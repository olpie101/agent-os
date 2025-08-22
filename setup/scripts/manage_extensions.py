#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pyyaml",
# ]
# ///

"""Main entry point for Agent OS extension management."""

import argparse
import os
import sys
from pathlib import Path

# Import the separated modules
from config_manager import ConfigManager
from extension_manager import ExtensionManager


def main():
    """Main entry point for extension management."""
    parser = argparse.ArgumentParser(description='Manage Agent OS extensions')
    parser.add_argument('--mode', choices=['base', 'project'], required=True,
                        help='Installation mode')
    parser.add_argument('--install-dir', required=True,
                        help='Installation directory')
    parser.add_argument('--base-dir', required=True,
                        help='Base directory containing extensions')
    parser.add_argument('--config-file', required=True,
                        help='Configuration file path')
    parser.add_argument('--project-config',
                        help='Project configuration file path (optional)')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug output')
    parser.add_argument('--overwrite', action='store_true',
                        help='Overwrite existing extension files')

    args = parser.parse_args()

    # Convert paths
    install_dir = Path(args.install_dir).expanduser().resolve()
    base_dir = Path(args.base_dir).expanduser().resolve()
    config_file = Path(args.config_file).expanduser().resolve()
    project_config = Path(args.project_config).expanduser(
    ).resolve() if args.project_config else None

    print(f"\n📦 Agent OS Extension Manager - {args.mode.capitalize()} Mode")
    print("=" * 50)

    if args.debug:
        print(f"Install Directory: {install_dir}")
        print(f"Base Directory: {base_dir}")
        print(f"Config File: {config_file}")
        if project_config:
            print(f"Project Config: {project_config}")
        print()

    # Initialize configuration manager
    config = ConfigManager()

    # Load configurations
    config.load_configs(config_file, project_config)

    # Merge with proper hierarchy
    config.merge_configs()

    # Validate requirements
    errors = config.validate_requirements()
    if errors:
        print("\n❌ Configuration validation failed:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)

    print("✅ Configuration validated successfully")

    # Initialize extension manager
    ext_manager = ExtensionManager(config, args.mode, args.overwrite)
    
    # Set environment variables for extensions to use
    os.environ['AGENT_OS_CONFIG_FILE'] = str(config_file)
    os.environ['INSTALL_DIR'] = str(install_dir)  # Add INSTALL_DIR for extension_installer.py
    if args.debug:
        os.environ['AGENT_OS_DEBUG'] = 'true'  # Propagate debug flag
    if args.mode == 'project' and project_config:
        os.environ['PROJECT_DIR'] = str(project_config.parent)

    # Process extensions
    ext_manager.process_extensions(base_dir, install_dir)

    # Create installation log
    ext_manager.create_log(install_dir)

    print(f"\n✅ {args.mode.capitalize()} extensions installation completed\n")


if __name__ == '__main__':
    main()
