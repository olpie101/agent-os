#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""Sandbox Extension Installer - Python implementation"""

import argparse
import os
import shutil
import sys
from pathlib import Path
from datetime import datetime


def copy_file_with_overwrite_check(source: Path, dest: Path, overwrite: bool, desc: str) -> bool:
    """Copy file with overwrite protection following Agent OS pattern."""
    if dest.exists() and not overwrite:
        print(f"    ⚠️  {desc} already exists - skipping")
        return False
    else:
        if source.exists():
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
            if dest.exists() and overwrite:
                print(f"    ✓ {desc} (overwritten)")
            else:
                print(f"    ✓ {desc}")
            return True
        else:
            print(f"    ❌ {desc} source not found: {source}")
            return False


def main():
    """Main installer function."""
    parser = argparse.ArgumentParser(description='Install sandbox extension')
    
    # Required arguments
    parser.add_argument('--mode', required=True, choices=['global', 'project'],
                        help='Installation mode')
    parser.add_argument('--source-dir', required=True,
                        help='Source directory containing extension files')
    parser.add_argument('--extension-name', required=True,
                        help='Name of the extension')
    
    # Optional arguments
    parser.add_argument('--install-dir',
                        help='Target installation directory')
    parser.add_argument('--project-dir',
                        help='Project directory (for project mode)')
    parser.add_argument('--config-enabled', default='true',
                        help='Whether extension is enabled')
    parser.add_argument('--config-required', default='true',
                        help='Whether extension is required')
    parser.add_argument('--config-install_dir',
                        help='Config override for install dir')
    parser.add_argument('--config-bin_dir', default='${HOME}/.local/bin',
                        help='Directory for command symlinks')
    parser.add_argument('--config-symlink', default='false',
                        help='Whether to create command symlink')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug output')
    parser.add_argument('--overwrite', action='store_true',
                        help='Overwrite existing files')
    
    # Parse arguments
    args, unknown = parser.parse_known_args()
    
    # Ignore unknown config arguments (like --config-*)
    for arg in unknown:
        if not arg.startswith('--config-'):
            print(f"Unknown argument: {arg}")
            parser.print_help()
            sys.exit(1)
    
    # Determine installation directory
    if args.config_install_dir:
        install_dir = args.config_install_dir
    elif args.install_dir:
        install_dir = args.install_dir
    else:
        install_dir = "${HOME}/.claude-code-sandbox"
    
    # Expand variables in paths
    home = os.path.expanduser("~")
    agent_os_home = os.environ.get('AGENT_OS_HOME', os.path.join(home, '.agent-os'))
    
    install_dir = install_dir.replace('${HOME}', home)
    install_dir = install_dir.replace('${AGENT_OS_HOME}', agent_os_home)
    install_dir = install_dir.replace('${EXTENSION_NAME}', args.extension_name)
    install_dir = Path(install_dir).expanduser().resolve()
    
    bin_dir = args.config_bin_dir.replace('${HOME}', home)
    bin_dir = Path(bin_dir).expanduser().resolve()
    
    # Parse symlink config (handle string "true"/"false" from command line)
    create_symlink = args.config_symlink.lower() == 'true'
    
    source_dir = Path(args.source_dir).expanduser().resolve()
    
    # Debug output
    if args.debug:
        print("🔍 Debug Information:")
        print(f"   Mode: {args.mode}")
        print(f"   Source: {source_dir}")
        print(f"   Install Dir: {install_dir}")
        print(f"   Bin Dir: {bin_dir}")
        print(f"   Enabled: {args.config_enabled}")
        print(f"   Required: {args.config_required}")
        print(f"   Symlink: {create_symlink}")
        print(f"   Overwrite: {args.overwrite}")
        print()
    
    print("🔒 Installing sandbox security profile...")
    
    # Create installation directory
    print(f"  Creating installation directory at {install_dir}...")
    install_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy sandbox profile
    profile_source = source_dir / "profiles" / "claude-code-sandbox.sb"
    profile_target = install_dir / "claude-code-sandbox.sb"
    
    if not copy_file_with_overwrite_check(
        profile_source, profile_target, args.overwrite, "Sandbox profile"
    ):
        if not profile_target.exists():
            print(f"❌ Error: Failed to install sandbox profile")
            sys.exit(1)
    
    if profile_target.exists():
        profile_target.chmod(0o644)
    
    # Copy launcher script
    launcher_source = source_dir / "launcher.sh"
    launcher_target = install_dir / "launcher.sh"
    
    if not copy_file_with_overwrite_check(
        launcher_source, launcher_target, args.overwrite, "Launcher script"
    ):
        if not launcher_target.exists():
            print(f"❌ Error: Failed to install launcher script")
            sys.exit(1)
    
    if launcher_target.exists():
        launcher_target.chmod(0o755)
    
    # Copy audit logger script
    audit_logger_source = source_dir / "sandbox-audit-logger.sh"
    audit_logger_target = install_dir / "sandbox-audit-logger.sh"
    
    if not copy_file_with_overwrite_check(
        audit_logger_source, audit_logger_target, args.overwrite, "Audit logger script"
    ):
        if not audit_logger_target.exists():
            print(f"❌ Error: Failed to install audit logger script")
            sys.exit(1)
    
    if audit_logger_target.exists():
        audit_logger_target.chmod(0o755)
    
    # Copy audit rotate script
    audit_rotate_source = source_dir / "sandbox-audit-rotate.sh"
    audit_rotate_target = install_dir / "sandbox-audit-rotate.sh"
    
    if not copy_file_with_overwrite_check(
        audit_rotate_source, audit_rotate_target, args.overwrite, "Audit rotate script"
    ):
        if not audit_rotate_target.exists():
            print(f"❌ Error: Failed to install audit rotate script")
            sys.exit(1)
    
    if audit_rotate_target.exists():
        audit_rotate_target.chmod(0o755)
    
    # Create symlink in bin directory if enabled
    if create_symlink:
        print("  Creating command symlink...")
        bin_dir.mkdir(parents=True, exist_ok=True)
        
        symlink_target = bin_dir / "claude-code-sandbox"
        
        # Handle symlink with overwrite protection
        if symlink_target.exists() or symlink_target.is_symlink():
            if args.overwrite:
                print("  Removing existing symlink...")
                symlink_target.unlink()
                symlink_target.symlink_to(launcher_target)
                print(f"  ✓ Symlink created (overwritten): {symlink_target} -> {launcher_target}")
            else:
                print(f"  ⚠️  Symlink already exists - skipping")
        else:
            symlink_target.symlink_to(launcher_target)
            print(f"  ✓ Symlink created: {symlink_target} -> {launcher_target}")
    else:
        print("  ⏭️  Symlink creation disabled in configuration")
        symlink_target = None
    
    # Create installation marker with overwrite check
    marker_file = install_dir / ".installed"
    if marker_file.exists() and not args.overwrite:
        print("  ⚠️  Installation marker already exists - skipping")
    else:
        with open(marker_file, 'w') as f:
            f.write(datetime.now().isoformat() + '\n')
        if args.overwrite:
            print("  ✓ Installation marker (overwritten)")
        else:
            print("  ✓ Installation marker")
    
    print()
    print("✅ Sandbox installation complete!")
    print()
    print("📝 Installation summary:")
    print(f"   Location: {install_dir}")
    if create_symlink:
        print("   Command: claude-code-sandbox")
    else:
        print("   Command: (symlink not created)")
    print("   Profile: Provides security isolation for code execution")
    print("   Audit: Logging and rotation scripts installed")
    
    # Verify installation
    required_components = [
        profile_target.exists(),
        launcher_target.exists(),
        audit_logger_target.exists(),
        audit_rotate_target.exists()
    ]
    
    if create_symlink:
        # With symlink enabled, check all components including symlink
        if all(required_components) and (symlink_target and (symlink_target.exists() or symlink_target.is_symlink())):
            print()
            print("✅ All components installed successfully")
            return 0
        else:
            print()
            print("⚠️  Some components may not have installed correctly")
            if not profile_target.exists():
                print("   Missing: sandbox profile")
            if not launcher_target.exists():
                print("   Missing: launcher script")
            if not audit_logger_target.exists():
                print("   Missing: audit logger script")
            if not audit_rotate_target.exists():
                print("   Missing: audit rotate script")
            if symlink_target and not (symlink_target.exists() or symlink_target.is_symlink()):
                print("   Missing: command symlink")
            return 1
    else:
        # Without symlink, check all required components
        if all(required_components):
            print()
            print("✅ All components installed successfully")
            return 0
        else:
            print()
            print("⚠️  Some components may not have installed correctly")
            if not profile_target.exists():
                print("   Missing: sandbox profile")
            if not launcher_target.exists():
                print("   Missing: launcher script")
            if not audit_logger_target.exists():
                print("   Missing: audit logger script")
            if not audit_rotate_target.exists():
                print("   Missing: audit rotate script")
            return 1


if __name__ == "__main__":
    sys.exit(main())