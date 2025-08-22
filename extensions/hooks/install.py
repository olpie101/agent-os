#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""Hooks Extension Installer - Python version."""

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

def parse_config_args(unknown_args):
    """Parse --config-* arguments from unknown args."""
    config = {}
    for arg in unknown_args:
        if arg.startswith('--config-'):
            key_value = arg[9:]  # Remove '--config-'
            if '=' in key_value:
                key, value = key_value.split('=', 1)
                # Convert boolean strings
                if value.lower() in ['true', 'false']:
                    value = value.lower() == 'true'
                config[key] = value
    return config

def expand_variables(path_str: str, variables: dict) -> str:
    """Expand variables in path strings."""
    if not path_str:
        return path_str
    
    # Replace variables
    for var, value in variables.items():
        path_str = path_str.replace(f'${{{var}}}', str(value))
        path_str = path_str.replace(f'${var}', str(value))
    
    return path_str

def copy_file_with_overwrite_check(source: Path, dest: Path, overwrite: bool, desc: str) -> bool:
    """Copy file with overwrite protection following Agent OS pattern."""
    if dest.exists() and not overwrite:
        print(f"    ⚠️  {desc} already exists - skipping")
        return False
    else:
        if source.exists():
            # Create parent directory if needed
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
            dest.chmod(0o755)
            if dest.exists() and overwrite:
                print(f"    ✓ {desc} (overwritten)")
            else:
                print(f"    ✓ {desc}")
            return True
        else:
            return False

def check_jq_available() -> bool:
    """Check if jq command is available."""
    try:
        result = subprocess.run(['jq', '--version'], capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def backup_settings(settings_file: Path) -> bool:
    """Backup existing settings.json file."""
    try:
        backup_file = settings_file.with_suffix('.json.backup')
        shutil.copy2(settings_file, backup_file)
        print(f"  ✓ Backed up existing settings to {backup_file}")
        return True
    except Exception as e:
        print(f"  ⚠️  Failed to backup settings: {e}")
        return False

def update_settings_json(install_path: Path, source_dir: Path, overwrite: bool = False, debug: bool = False) -> bool:
    """Update ~/.claude/settings.json with hooks configuration."""
    settings_file = install_path / 'settings.json'
    hooks_config_file = source_dir / 'settings_hooks.json'
    
    if not hooks_config_file.exists():
        print(f"  ⚠️  Settings configuration file not found: {hooks_config_file}")
        return False
    
    # Check if jq is available
    if not check_jq_available():
        print("  ⚠️  jq is not installed. Please install jq to configure hooks automatically.")
        print("     On macOS: brew install jq")
        print("     On Ubuntu/Debian: sudo apt-get install jq")
        print("     On CentOS/RHEL: sudo yum install jq")
        print(f"  Manual configuration required: Add the hooks configuration from {hooks_config_file} to {settings_file}")
        return False
    
    # Create settings.json if it doesn't exist
    if not settings_file.exists():
        print(f"  Creating new {settings_file} with hooks configuration")
        initial_settings = {
            "permissions": {"allow": []},
            "hooks": {}
        }
        with open(settings_file, 'w') as f:
            json.dump(initial_settings, f, indent=2)
    else:
        # Check if we should update existing settings
        if not overwrite:
            # Check if hooks are already configured
            try:
                with open(settings_file, 'r') as f:
                    existing_settings = json.load(f)
                if 'hooks' in existing_settings and existing_settings['hooks']:
                    print(f"  ⚠️  Hooks already configured in {settings_file} - skipping")
                    print("     Use --overwrite to update hooks configuration")
                    return False
            except Exception:
                pass  # If we can't read the file, proceed with update
        
        # Backup existing settings
        if not backup_settings(settings_file):
            print("  ⚠️  Could not backup settings, skipping update")
            return False
    
    # Merge hooks configuration using jq
    try:
        cmd = [
            'jq', '-s', 
            '.[0] * {"hooks": .[1].hooks}',
            str(settings_file),
            str(hooks_config_file)
        ]
        
        if debug:
            print(f"  🔧 Running: {' '.join(cmd)}")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            # Write the merged configuration
            temp_file = settings_file.with_suffix('.json.tmp')
            with open(temp_file, 'w') as f:
                f.write(result.stdout)
            
            # Replace original file
            shutil.move(temp_file, settings_file)
            print(f"  ✓ Successfully merged hooks configuration into {settings_file}")
            return True
        else:
            print(f"  ❌ Failed to merge hooks configuration: {result.stderr}")
            return False
    
    except Exception as e:
        print(f"  ❌ Failed to update settings: {e}")
        return False

def main():
    """Main entry point for hooks extension installer."""
    parser = argparse.ArgumentParser(description='Install Hooks extension')
    
    # Standard arguments
    parser.add_argument('--mode', choices=['global', 'project'], required=True,
                        help='Installation mode')
    parser.add_argument('--source-dir', required=True,
                        help='Source directory containing extension files')
    parser.add_argument('--extension-name', required=True,
                        help='Name of the extension')
    parser.add_argument('--install-dir',
                        help='Target installation directory')
    parser.add_argument('--project-dir',
                        help='Project directory (for project mode)')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug output')
    parser.add_argument('--overwrite', action='store_true',
                        help='Overwrite existing files during installation')
    
    args, unknown = parser.parse_known_args()
    
    # Parse config arguments
    config = parse_config_args(unknown)
    
    # Get config values with defaults
    config_enabled = config.get('enabled', True)
    config_required = config.get('required', False)
    config_install_dir = config.get('install_dir', '')
    config_source_dir = config.get('source_dir', '')
    config_auto_update = config.get('auto_update', False)
    config_update_settings = config.get('update_settings', True)
    
    # Debug mode from argument or environment
    debug = args.debug or os.getenv('AGENT_OS_DEBUG', '').lower() == 'true'
    
    # Validate project mode requirements
    if args.mode == 'project' and not args.project_dir:
        print("❌ Error: --project-dir is required for project mode hooks installation")
        return 1
    
    # Determine installation directory
    if config_install_dir:
        install_dir = config_install_dir
    elif args.install_dir:
        install_dir = args.install_dir
    else:
        install_dir = "~/.claude"
    
    # Determine hooks source directory
    if config_source_dir:
        hooks_source_dir = config_source_dir
    elif args.mode == 'project':
        hooks_source_dir = f"{args.project_dir}/claude-code/hooks"
    else:
        # For global mode, hooks are in the extension directory
        hooks_source_dir = f"{args.source_dir}"
    
    # Set up variables for expansion
    variables = {
        'HOME': os.path.expanduser('~'),
        'AGENT_OS_HOME': os.getenv('AGENT_OS_HOME', os.path.expanduser('~/.agent-os')),
        'EXTENSION_NAME': args.extension_name,
        'PROJECT_DIR': args.project_dir or '',
        'SOURCE_DIR': args.source_dir
    }
    
    # Expand variables in paths
    install_dir = expand_variables(install_dir, variables)
    hooks_source_dir = expand_variables(hooks_source_dir, variables)
    
    # Convert to Path objects
    install_path = Path(install_dir).expanduser().resolve()
    source_path = Path(args.source_dir).expanduser().resolve()
    hooks_source_path = Path(hooks_source_dir).expanduser().resolve()
    
    if debug:
        print("🔍 Debug Information:")
        print(f"   Mode: {args.mode}")
        print(f"   Extension Source: {source_path}")
        print(f"   Hooks Source: {hooks_source_path}")
        print(f"   Install Dir: {install_path}")
        print(f"   Project Dir: {args.project_dir}")
        print(f"   Enabled: {config_enabled}")
        print(f"   Required: {config_required}")
        print(f"   Auto Update: {config_auto_update}")
        print(f"   Update Settings: {config_update_settings}")
    
    print("🪝 Installing hooks extension...")
    
    # Create installation directories
    hooks_install_path = install_path / 'hooks'
    print(f"  Creating hooks directory at {hooks_install_path}...")
    hooks_install_path.mkdir(parents=True, exist_ok=True)
    
    # Create subdirectories
    (hooks_install_path / 'utils' / 'llm').mkdir(parents=True, exist_ok=True)
    (hooks_install_path / 'utils' / 'tts').mkdir(parents=True, exist_ok=True)
    (hooks_install_path / 'instructions').mkdir(parents=True, exist_ok=True)
    
    # Check if hooks source directory exists
    if not hooks_source_path.exists() or not hooks_source_path.is_dir():
        print(f"  ⚠️  WARNING: Hooks source directory not found at {hooks_source_path}")
        if args.mode == 'project':
            print("  This extension requires claude-code/hooks/ to be present in your project")
            print("  Create claude-code/hooks/ with your hook files and run installation again")
        
        # Create empty hooks directory anyway
        print(f"  No hooks installed (source directory not found)")
        return 0
    
    # Copy hook files based on the setup-claude-code.sh pattern
    hook_files = [
        'notification.py', 'post_tool_use.py', 'pre_compact.py', 
        'pre_tool_use.py', 'session_start.py', 'stop.py', 
        'subagent_stop.py', 'user_prompt_submit.py'
    ]
    
    hooks_copied = 0
    
    # Copy main hook files
    for hook_file in hook_files:
        source_file = hooks_source_path / hook_file
        dest_file = hooks_install_path / hook_file
        if copy_file_with_overwrite_check(source_file, dest_file, args.overwrite, hook_file):
            hooks_copied += 1
        elif debug and not source_file.exists():
            print(f"    ⚠️  {hook_file} not found in source")
    
    # Copy instructions directory
    instructions_src = hooks_source_path / "instructions"
    if instructions_src.exists() and instructions_src.is_dir():
        instructions_dst = hooks_install_path / "instructions"
        if instructions_dst.exists() and not args.overwrite:
            print(f"    ⚠️  instructions/ directory already exists - skipping")
        else:
            if instructions_dst.exists():
                shutil.rmtree(instructions_dst)
            shutil.copytree(instructions_src, instructions_dst)
            if args.overwrite and instructions_dst.exists():
                print(f"    ✓ instructions/ directory (overwritten)")
            else:
                print(f"    ✓ instructions/ directory")
    
    # Copy LLM utilities
    llm_files = ['anth.py', 'gemini.py', 'oai.py']
    llm_src = hooks_source_path / 'utils' / 'llm'
    if llm_src.exists():
        for llm_file in llm_files:
            source_file = llm_src / llm_file
            dest_file = hooks_install_path / 'utils' / 'llm' / llm_file
            copy_file_with_overwrite_check(source_file, dest_file, args.overwrite, f"utils/llm/{llm_file}")
    
    # Copy TTS utilities
    tts_files = ['elevenlabs_tts.py', 'gemini_tts.py', 'openai_tts.py', 'pyttsx3_tts.py']
    tts_src = hooks_source_path / 'utils' / 'tts'
    if tts_src.exists():
        for tts_file in tts_files:
            source_file = tts_src / tts_file
            dest_file = hooks_install_path / 'utils' / 'tts' / tts_file
            copy_file_with_overwrite_check(source_file, dest_file, args.overwrite, f"utils/tts/{tts_file}")
    
    # Create configuration file
    config_file = hooks_install_path / ".hooks-config"
    with open(config_file, 'w') as f:
        f.write("# Hooks Extension Configuration\n")
        f.write(f"installation_date={datetime.now().isoformat()}\n")
        f.write(f"installation_mode={args.mode}\n")
        f.write(f"source_directory={hooks_source_path}\n")
        f.write(f"hook_count={hooks_copied}\n")
        f.write(f"auto_update={str(config_auto_update).lower()}\n")
        f.write(f"update_settings={str(config_update_settings).lower()}\n")
        if args.mode == 'project':
            f.write(f"source_project={args.project_dir}\n")
    
    # Update settings.json if requested
    if config_update_settings:
        print(f"  🔧 Configuring Claude Code hooks in settings.json")
        if not update_settings_json(install_path, source_path, args.overwrite, debug):
            print(f"  ⚠️  Settings update failed - hooks are installed but not configured")
            print(f"     Manual configuration required: see {source_path}/settings_hooks.json")
    else:
        print(f"  ℹ️  Settings update skipped")
        print(f"     To manually configure hooks, see {source_path}/settings_hooks.json")
    
    # Verify installation
    installed_files = list(hooks_install_path.glob("*.py"))
    installed_count = len(installed_files)
    
    print()
    if installed_count > 0:
        print("✅ Hooks installed successfully!")
        print()
        print("📝 Installation summary:")
        print(f"   Location: {hooks_install_path}")
        print(f"   Hooks installed: {installed_count}")
        if args.mode == 'project':
            print(f"   Source project: {args.project_dir}")
        if config_auto_update:
            print("   Auto-update: enabled")
        if config_update_settings:
            print(f"   Settings: configured in {install_path}/settings.json")
    elif hooks_copied == 0:
        print("✅ Hooks directory created (no hooks to install)")
        print()
        print("📝 To add hooks:")
        if args.mode == 'project':
            print(f"   1. Create Python hook files in: {args.project_dir}/claude-code/hooks/")
        else:
            print(f"   1. Create Python hook files in: {hooks_source_path}")
        print("   2. Re-run the installation")
    else:
        print("❌ ERROR: Failed to install hooks")
        return 1
    
    return 0

if __name__ == '__main__':
    sys.exit(main())