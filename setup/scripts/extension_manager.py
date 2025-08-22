#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///

"""Extension management for Agent OS."""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List


class ExtensionManager:
    """Manages extension discovery and installation."""

    def __init__(self, config, mode: str, overwrite: bool = False):
        self.config = config
        self.mode = mode  # 'base' or 'project'
        self.overwrite = overwrite  # Whether to overwrite existing files
        self.installed_extensions = []
        self.failed_extensions = []
        self.skipped_extensions = []

    def discover_extensions(self, base_dir: Path) -> List[str]:
        """Dynamically discover available extensions."""
        extensions_dir = base_dir / 'extensions'
        if not extensions_dir.exists():
            return []

        extensions = []
        for item in extensions_dir.iterdir():
            if item.is_dir():
                # Check for either install.sh or install.py
                has_installer = (
                    item / 'install.sh').exists() or (item / 'install.py').exists()
                if has_installer:
                    extensions.append(item.name)

        return sorted(extensions)

    def is_enabled(self, extension: str) -> bool:
        """Check if an extension is enabled in configuration."""
        key = f'EXTENSIONS_{extension.upper()}_ENABLED'
        value = str(self.config.get_value(key, 'false')).lower()
        return value == 'true'

    def is_required(self, extension: str) -> bool:
        """Check if an extension is required."""
        key = f'EXTENSIONS_{extension.upper()}_REQUIRED'
        # Check base config for required status
        value = str(self.config.base_config.get(key, 'false')).lower()
        return value == 'true'

    def is_installed_globally(self, extension: str) -> bool:
        """Check if an extension is already installed globally."""
        # Check if the extension exists in the global Agent OS directory
        global_install_dir = Path.home() / '.agent-os' / 'extensions' / extension
        return global_install_dir.exists()

    def should_install_extension(self, extension: str, extension_dir: Path) -> bool:
        """Determine if an extension should be installed based on mode and type."""
        # Read extension.yaml to get the type
        extension_yaml = extension_dir / 'extension.yaml'
        if not extension_yaml.exists():
            # No metadata, assume it can be installed
            return True
        
        try:
            import yaml
            with open(extension_yaml, 'r') as f:
                metadata = yaml.safe_load(f)
            
            ext_type = metadata.get('type', 'global')
            
            # Mode-based filtering
            if self.mode == 'base':  # base mode is essentially global
                # Install if type is 'global' or 'both'
                if ext_type in ['global', 'both']:
                    return True
                return False
            elif self.mode == 'project':
                # Install if type is 'project' or 'both'
                if ext_type == 'project':
                    return True
                elif ext_type == 'both':
                    # Only install if not already globally installed
                    if self.is_installed_globally(extension):
                        print(f"  ⏭️  {extension} already installed globally - skipping project installation")
                        return False
                    return True
                return False
            
            # Default to allowing installation
            return True
            
        except Exception as e:
            print(f"  ⚠️  Warning: Could not read extension type from {extension_yaml}: {e}")
            # If we can't read the metadata, default to allowing installation
            return True

    def copy_extension(self, source: Path, dest: Path) -> bool:
        """Copy extension files to destination."""
        try:
            print(f"  📂 Copying {source.name} extension...")
            dest.parent.mkdir(parents=True, exist_ok=True)

            if dest.exists():
                shutil.rmtree(dest)

            shutil.copytree(source, dest)
            print(f"  ✓ {source.name} extension copied")
            return True
        except Exception as e:
            print(f"  ⚠️  Failed to copy {source.name}: {e}")
            return False

    def run_installer(self, extension_dir: Path, source_dir: Path = None) -> bool:
        """Run the extension installer via extension_installer.py."""
        # Debug environment variables (only show if debug is enabled)
        if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
            print(f"  [DEBUG] Environment in extension_manager.py:")
            print(f"         AGENT_OS_HOME: {
                  os.getenv('AGENT_OS_HOME', 'NOT SET')}")
            print(f"         INSTALL_DIR: {
                  os.getenv('INSTALL_DIR', 'NOT SET')}")
            print(f"         AGENT_OS_CONFIG_FILE: {
                  os.getenv('AGENT_OS_CONFIG_FILE', 'NOT SET')}")
            print(f"         AGENT_OS_DEBUG: {
                  os.getenv('AGENT_OS_DEBUG', 'NOT SET')}")

        # Try multiple paths to find the installer
        possible_paths = [
            # Primary: AGENT_OS_HOME path
            Path(os.getenv('AGENT_OS_HOME',
                           os.path.expanduser('~/.agent-os'))) / 'setup' / 'scripts' / 'extension_installer.py',
            # Secondary: Relative to this script
            Path(__file__).parent / 'extension_installer.py',
            # Tertiary: In INSTALL_DIR if set
            Path(os.getenv('INSTALL_DIR', '')) / 'setup' / 'scripts' /
            'extension_installer.py' if os.getenv('INSTALL_DIR') else None,
        ]

        installer_path = None
        if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
            print(f"  [DEBUG] Searching for extension_installer.py:")
        for path in possible_paths:
            if path:
                exists = path.exists()
                if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
                    print(f"         {path}: {
                          'EXISTS' if exists else 'NOT FOUND'}")
                if exists and not installer_path:
                    installer_path = path
                    if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
                        print(f"         -> Selected this path")

        if not installer_path:
            print(f"  ⚠️  Extension installer not found in any location")
            return False

        try:
            print(f"  🔧 Running {extension_dir.name} installer...")
            if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
                print(f"     Using installer at: {installer_path}")

            # Get merged configuration as JSON
            merged_config = self.config.get_merged_config()
            config_json = json.dumps(merged_config)

            # Build command for extension_installer.py using uv
            cmd = ['uv', 'run', str(installer_path)]

            # Add required arguments
            # Map 'base' mode to 'global' for the installer
            installer_mode = 'global' if self.mode == 'base' else self.mode
            cmd.extend([
                f'--mode={installer_mode}',
                f'--source-dir={source_dir or extension_dir}',
                f'--extension-name={extension_dir.name}',
                f'--merged-config={config_json}'
            ])

            # Add optional arguments
            if self.mode == 'project':
                project_dir = os.getenv('PROJECT_DIR', os.getcwd())
                cmd.append(f'--project-dir={project_dir}')

            # Add debug flag if verbose
            if os.getenv('AGENT_OS_DEBUG', '').lower() == 'true':
                cmd.append('--debug')

            # Add overwrite flag
            if self.overwrite:
                cmd.append('--overwrite')

            result = subprocess.run(
                cmd,
                # cwd=extension_dir,
                capture_output=False,  # Let installer output directly
                text=True
            )

            if result.returncode == 0:
                print(f"  ✓ {extension_dir.name} installation completed")
                return True
            else:
                print(f"  ⚠️  {extension_dir.name} installation failed with exit code {
                      result.returncode}")
                return False
        except Exception as e:
            print(f"  ⚠️  Failed to run installer for {
                  extension_dir.name}: {e}")
            return False

    def install_extension(self, name: str, source: Path, dest: Path) -> bool:
        """Install a single extension."""
        print(f"\n🔧 Installing {name} extension...")

        # Copy extension files
        if not self.copy_extension(source, dest):
            self.failed_extensions.append(name)
            return False

        # Run installer with source directory
        if not self.run_installer(dest, source):
            self.failed_extensions.append(name)
            return False

        self.installed_extensions.append(name)
        return True

    def process_extensions(self, base_dir: Path, install_dir: Path):
        """Process all discovered extensions."""
        # Discover available extensions
        extensions = self.discover_extensions(base_dir)

        if not extensions:
            print("  ℹ️  No extensions found to process")
            return

        print(f"\n📦 Processing {len(extensions)} extension(s)...")

        for ext_name in extensions:
            source = base_dir / 'extensions' / ext_name
            
            # Check if this extension should be installed based on mode and type
            if not self.should_install_extension(ext_name, source):
                print(f"\n⏭️  Skipping {
                      ext_name} extension (not applicable for {self.mode} mode)")
                self.skipped_extensions.append(ext_name)
                continue
            
            enabled = self.is_enabled(ext_name)
            required = self.is_required(ext_name)

            if enabled:
                dest = install_dir / 'extensions' / ext_name

                success = self.install_extension(ext_name, source, dest)

                if not success and required:
                    print(f"\n❌ ERROR: Required extension '{
                          ext_name}' failed to install!")
                    sys.exit(1)
            else:
                print(f"\n⏭️  Skipping {
                      ext_name} extension (disabled in configuration)")
                self.skipped_extensions.append(ext_name)
                if required:
                    print(f"❌ ERROR: Extension '{
                          ext_name}' is required but disabled!")
                    sys.exit(1)

        # Display installation summary
        self.display_summary()

    def display_summary(self):
        """Display installation summary with counts and extension names."""
        print(f"\n📊 Extension Installation Summary ({self.mode} mode)")
        print("=" * 50)

        total_processed = len(self.installed_extensions) + \
            len(self.failed_extensions) + len(self.skipped_extensions)

        # Success summary
        if self.installed_extensions:
            print(f"✅ Successfully installed ({
                  len(self.installed_extensions)}):")
            for ext in self.installed_extensions:
                print(f"   • {ext}")
        else:
            print(f"✅ Successfully installed: 0")

        # Failure summary
        if self.failed_extensions:
            print(f"\n❌ Failed to install ({len(self.failed_extensions)}):")
            for ext in self.failed_extensions:
                print(f"   • {ext}")
        else:
            print(f"\n❌ Failed to install: 0")

        # Skipped summary
        if self.skipped_extensions:
            print(f"\n⏭️  Skipped ({len(self.skipped_extensions)}):")
            for ext in self.skipped_extensions:
                print(f"   • {ext}")
        else:
            print(f"\n⏭️  Skipped: 0")

        print(f"\n📈 Total processed: {total_processed} extension(s)")

    def create_log(self, install_dir: Path):
        """Create installation log."""
        log_dir = install_dir / 'extensions'
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / 'installation.log'

        with open(log_file, 'w') as f:
            f.write("=== Agent OS Extensions Installation Log ===\n")
            f.write(f"Date: {os.popen('date').read().strip()}\n")
            f.write(f"Mode: {self.mode}\n")
            f.write(f"Installation Directory: {install_dir}\n")
            f.write("\nInstalled Extensions:\n")

            if self.installed_extensions:
                for ext in self.installed_extensions:
                    f.write(f"  - {ext}\n")
            else:
                f.write("  (none)\n")

            f.write("\n=== End of Log ===\n")

        print(f"\n📄 Installation log saved to: {log_file}")
