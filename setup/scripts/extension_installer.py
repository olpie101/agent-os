#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pyyaml",
# ]
# ///

"""Extension installer that validates config and delegates to install.sh."""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any, Optional

import yaml


class ExtensionInstaller:
    """Validates extension configuration and delegates to install.sh."""

    def __init__(self, args: argparse.Namespace):
        """Initialize the installer with command-line arguments."""
        self.mode = args.mode
        self.source_dir = Path(args.source_dir).resolve()
        self.install_dir = Path(
            args.install_dir).resolve() if args.install_dir else None
        self.extension_name = args.extension_name
        self.project_dir = Path(
            args.project_dir).resolve() if args.project_dir else None
        self.merged_config = json.loads(
            args.merged_config) if args.merged_config else {}
        self.debug = args.debug
        self.overwrite = args.overwrite

        # Load extension metadata
        self.metadata = self.load_metadata()

    def load_metadata(self) -> Dict[str, Any]:
        """Load extension metadata from extension.yaml."""
        metadata_path = self.source_dir / 'extension.yaml'

        if not metadata_path.exists():
            # Return minimal metadata if extension.yaml doesn't exist
            return {
                'name': self.extension_name,
                'type': 'both',
                'config_schema': {
                    'enabled': {
                        'type': 'boolean',
                        'default': True,
                        'required': False
                    },
                    'install_dir': {
                        'type': 'string',
                        'default': f"${{AGENT_OS_HOME}}/extensions/{self.extension_name}",
                        'required': False
                    }
                }
            }

        with open(metadata_path, 'r') as f:
            return yaml.safe_load(f)

    def validate_installation_type(self) -> bool:
        """Validate that the extension supports the installation mode."""
        ext_type = self.metadata.get('type', 'both')

        if ext_type == 'both':
            return True
        elif ext_type == self.mode:
            return True
        else:
            print(f"❌ Extension '{self.extension_name}' does not support {
                  self.mode} installation")
            print(f"   Extension type: {ext_type}")
            return False

    def validate_config(self) -> Dict[str, Any]:
        """Validate merged config against schema and extract extension config."""
        config_schema = self.metadata.get('config_schema', {})
        validated_config = {}

        # Extract extension-specific config from merged config
        # Config keys are in format: EXTENSIONS_<NAME>_<KEY>
        prefix = f"EXTENSIONS_{self.extension_name.upper()}_"

        for schema_key, schema_def in config_schema.items():
            # Convert schema key to config key format
            config_key = prefix + schema_key.upper()

            # Get value from merged config
            value = self.merged_config.get(config_key)

            # Use default if not provided
            if value is None:
                if 'default' in schema_def:
                    value = schema_def['default']
                elif schema_def.get('required', False):
                    print(f"❌ Required config '{
                          schema_key}' not provided for {self.extension_name}")
                    return None

            # Validate type
            if value is not None:
                expected_type = schema_def.get('type', 'string')
                if not self.validate_type(value, expected_type):
                    print(f"❌ Config '{schema_key}' has invalid type. Expected {
                          expected_type}, got {type(value).__name__}")
                    return None

                # Validate enum
                if 'enum' in schema_def and value not in schema_def['enum']:
                    print(f"❌ Config '{schema_key}' value '{
                          value}' not in allowed values: {schema_def['enum']}")
                    return None

            # Add to validated config (using original key name)
            validated_config[schema_key] = value

        return validated_config

    def validate_type(self, value: Any, expected_type: str) -> bool:
        """Validate that a value matches the expected type."""
        type_map = {
            'string': str,
            'boolean': bool,
            'integer': int,
            'array': list,
            'object': dict
        }

        expected_python_type = type_map.get(expected_type, str)

        # Special handling for boolean strings
        if expected_type == 'boolean' and isinstance(value, str):
            return value.lower() in ['true', 'false']

        return isinstance(value, expected_python_type)

    def expand_variables(self, value: str) -> str:
        """Expand variables in configuration values."""
        if not isinstance(value, str):
            return value

        # Define available variables
        variables = {
            'AGENT_OS_HOME': os.getenv('AGENT_OS_HOME', os.path.expanduser('~/.agent-os')),
            'HOME': os.path.expanduser('~'),
            'PROJECT_DIR': str(self.project_dir) if self.project_dir else os.getcwd(),
            'EXTENSION_NAME': self.extension_name,
            'INSTALL_DIR': str(self.install_dir) if self.install_dir else ''
        }

        # Expand variables
        for var, var_value in variables.items():
            value = value.replace(f'${{{var}}}', var_value)
            value = value.replace(f'${var}', var_value)

        return value

    def check_dependencies(self) -> bool:
        """Check if required extension dependencies are met."""
        dependencies = self.metadata.get('dependencies', {})
        extensions = dependencies.get('extensions', [])

        for ext_dep in extensions:
            if isinstance(ext_dep, dict):
                dep_name = ext_dep.get('name')
                optional = ext_dep.get('optional', False)
            else:
                dep_name = ext_dep
                optional = False

            # Check if dependency extension is enabled
            dep_key = f"EXTENSIONS_{dep_name.upper()}_ENABLED"
            dep_enabled = str(self.merged_config.get(
                dep_key, 'false')).lower() == 'true'

            if not dep_enabled and not optional:
                print(f"❌ Required dependency '{dep_name}' is not enabled")
                return False
            elif not dep_enabled and optional:
                if self.debug:
                    print(f"  ⚠️  Optional dependency '{
                          dep_name}' is not enabled")

        return True

    def get_installer_type(self, source_dir: Path) -> Optional[str]:
        """Determine which installer type is available."""
        install_py = source_dir / 'install.py'
        install_sh = source_dir / 'install.sh'
        
        # Prefer install.py if both exist (more portable)
        if install_py.exists():
            return 'python'
        elif install_sh.exists():
            return 'shell'
        else:
            return None

    def build_install_command(self, validated_config: Dict[str, Any]) -> list:
        """Build the install command for either install.sh or install.py."""
        installer_type = self.get_installer_type(self.source_dir)
        
        if not installer_type:
            print(f"❌ No install.sh or install.py found for {self.extension_name}")
            return None
        
        if installer_type == 'shell':
            install_script = self.source_dir / 'install.sh'
            # Make sure install script is executable
            install_script.chmod(0o755)
            cmd = ['bash', str(install_script)]
            if self.debug:
                print(f"  📝 Using shell installer: install.sh")
        else:  # python
            install_script = self.source_dir / 'install.py'
            # Use uv run for Python installer
            cmd = ['uv', 'run', str(install_script)]
            if self.debug:
                print(f"  🐍 Using Python installer: install.py")

        # Add standard arguments
        cmd.extend([
            f'--mode={self.mode}',
            f'--source-dir={self.source_dir}',
            f'--extension-name={self.extension_name}'
        ])

        # Add install directory if determined
        if 'install_dir' in validated_config:
            install_dir = self.expand_variables(
                validated_config['install_dir'])
            cmd.append(f'--install-dir={install_dir}')
        elif self.install_dir:
            cmd.append(f'--install-dir={self.install_dir}')

        # Add project directory for project mode
        if self.mode == 'project' and self.project_dir:
            cmd.append(f'--project-dir={self.project_dir}')

        # Add all validated config values as arguments
        for key, value in validated_config.items():
            if key == 'install_dir':
                continue  # Already handled above

            # Convert boolean to string
            if isinstance(value, bool):
                value = 'true' if value else 'false'
            elif isinstance(value, list):
                value = ','.join(str(v) for v in value)

            # Add as config argument
            cmd.append(f'--config-{key}={value}')

        # Add debug flag if enabled
        if self.debug:
            cmd.append('--debug')
        
        # Add overwrite flag if enabled
        if self.overwrite:
            cmd.append('--overwrite')

        return cmd

    def install(self) -> bool:
        """Perform the installation."""
        print(f"\n🔧 Installing {self.extension_name} extension...")
        print(f"  📍 Mode: {self.mode}")
        print(f"  📍 Source: {self.source_dir}")

        # Validate installation type
        if not self.validate_installation_type():
            return False

        # Check dependencies
        if not self.check_dependencies():
            return False

        # Validate configuration
        validated_config = self.validate_config()
        if validated_config is None:
            return False

        if self.debug:
            print(f"  📋 Validated config: {validated_config}")

        # Build install command
        cmd = self.build_install_command(validated_config)
        if not cmd:
            return False

        if self.debug:
            print(f"  🔧 Running: {' '.join(cmd)}")

        # Run install.sh
        try:
            result = subprocess.run(
                cmd,
                # cwd=self.source_dir,
                capture_output=False,  # Let install.sh output directly
                text=True
            )

            if result.returncode == 0:
                print(f"✅ {self.extension_name} extension installed successfully")
                return True
            else:
                print(f"❌ {self.extension_name} installation failed with exit code {
                      result.returncode}")
                return False
        except Exception as e:
            print(f"❌ Failed to run installer: {e}")
            return False


def main():
    """Main entry point for extension installer."""
    # Debug environment variables (only show if debug is enabled)
    if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
        print(f"  [DEBUG] Environment in extension_installer.py:")
        print(f"         AGENT_OS_HOME: {os.getenv('AGENT_OS_HOME', 'NOT SET')}")
        print(f"         INSTALL_DIR: {os.getenv('INSTALL_DIR', 'NOT SET')}")
        print(f"         AGENT_OS_CONFIG_FILE: {os.getenv('AGENT_OS_CONFIG_FILE', 'NOT SET')}")
        print(f"         PROJECT_DIR: {os.getenv('PROJECT_DIR', 'NOT SET')}")
        print(f"         AGENT_OS_DEBUG: {os.getenv('AGENT_OS_DEBUG', 'NOT SET')}")

    parser = argparse.ArgumentParser(description='Install Agent OS extension')

    # Required arguments
    parser.add_argument('--mode', choices=['global', 'project'], required=True,
                        help='Installation mode')
    parser.add_argument('--source-dir', required=True,
                        help='Source directory containing extension files')
    parser.add_argument('--extension-name', required=True,
                        help='Name of the extension')
    parser.add_argument('--merged-config', required=True,
                        help='JSON string of merged configuration')

    # Optional arguments
    parser.add_argument('--install-dir',
                        help='Override installation directory')
    parser.add_argument('--project-dir',
                        help='Project directory (for project mode)')
    parser.add_argument('--debug', action='store_true',
                        help='Enable debug output')
    parser.add_argument('--overwrite', action='store_true',
                        help='Overwrite existing files during installation')

    args = parser.parse_args()

    # Create installer and run
    installer = ExtensionInstaller(args)
    success = installer.install()

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
