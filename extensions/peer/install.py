#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""PEER extension installer - Python version."""

import argparse
import os
import shutil
import sys
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

def main():
    """Main entry point for PEER extension installer."""
    parser = argparse.ArgumentParser(description='Install PEER extension')
    
    # Standard arguments
    parser.add_argument('--mode', choices=['global', 'project'], required=True)
    parser.add_argument('--source-dir', required=True)
    parser.add_argument('--extension-name', required=True)
    parser.add_argument('--install-dir')
    parser.add_argument('--project-dir')
    parser.add_argument('--debug', action='store_true')
    
    args, unknown = parser.parse_known_args()
    config = parse_config_args(unknown)
    
    # Debug output
    debug = args.debug or os.getenv('AGENT_OS_DEBUG', '').lower() == 'true'
    if debug:
        print(f"[DEBUG] PEER Python installer")
        print(f"        Mode: {args.mode}")
        print(f"        Source: {args.source_dir}")
        print(f"        Config: {config}")
    
    print(f"🔧 Installing PEER extension ({args.mode} mode)...")
    
    # Determine installation directory
    if args.install_dir:
        install_dir = Path(args.install_dir).expanduser()
    else:
        install_dir = Path.home() / '.agent-os' / 'extensions' / 'peer'
    
    # Create installation directory
    install_dir.mkdir(parents=True, exist_ok=True)
    print(f"  📁 Installation directory: {install_dir}")
    
    # Copy scripts directory
    source_path = Path(args.source_dir)
    scripts_src = source_path / 'scripts'
    if scripts_src.exists():
        scripts_dst = install_dir / 'scripts'
        if scripts_dst.exists():
            shutil.rmtree(scripts_dst)
        shutil.copytree(scripts_src, scripts_dst)
        
        # Make scripts executable
        for script in scripts_dst.glob('*.sh'):
            script.chmod(0o755)
        print(f"  ✓ Installed PEER scripts")
    
    # Handle NATS configuration
    nats_url = config.get('nats_url', 'nats://localhost:4222')
    project_buckets = config.get('project_buckets', True)
    
    print(f"  ✓ NATS URL: {nats_url}")
    if project_buckets:
        print(f"  ✓ Per-project KV buckets enabled")
    else:
        print(f"  ✓ Global KV bucket mode")
    
    # Mode-specific setup
    if args.mode == 'project' and args.project_dir:
        project_path = Path(args.project_dir)
        peer_dir = project_path / '.agent-os' / 'peer'
        peer_dir.mkdir(parents=True, exist_ok=True)
        
        # Create project-specific configuration
        config_file = peer_dir / 'config.json'
        import json
        with open(config_file, 'w') as f:
            json.dump({
                'nats_url': nats_url,
                'project_buckets': project_buckets,
                'project_name': project_path.name
            }, f, indent=2)
        print(f"  ✓ Created project configuration: {config_file}")
    
    print(f"✅ PEER extension installed successfully")
    return 0

if __name__ == '__main__':
    sys.exit(main())