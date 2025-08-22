# Extension Installer Options

Agent OS supports two types of extension installers, providing flexibility for extension developers based on their needs and complexity requirements.

## Installer Types

### 1. Shell Script (`install.sh`)
- **Best for:** Simple installations, file copying, system commands
- **Language:** Bash shell script
- **Dependencies:** None (uses system shell)
- **Platform:** Unix-like systems (Linux, macOS)

### 2. Python Script (`install.py`)
- **Best for:** Complex logic, cross-platform compatibility, API interactions
- **Language:** Python 3.11+
- **Dependencies:** Managed via uv script dependencies
- **Platform:** Any platform with Python and uv

## Installer Interface

Both installer types receive identical command-line arguments:

### Required Arguments
- `--mode={global|project}` - Installation mode
- `--source-dir=PATH` - Extension source directory
- `--extension-name=NAME` - Extension name

### Optional Arguments
- `--install-dir=PATH` - Override installation directory
- `--project-dir=PATH` - Project directory (for project mode)
- `--debug` - Enable debug output

### Configuration Arguments
- `--config-KEY=VALUE` - Extension-specific configuration
  - Example: `--config-auto_update=true`
  - Example: `--config-nats_url=nats://localhost:4222`

## Installer Selection

The extension system automatically detects which installer to use:

1. **Priority:** If both `install.py` and `install.sh` exist, `install.py` takes precedence
2. **Fallback:** If only one installer exists, it will be used
3. **Error:** If neither exists, the extension cannot be installed

## Examples

### Basic Shell Installer (`install.sh`)

```bash
#!/bin/bash
set -e

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode=*) MODE="${1#*=}" ;;
        --source-dir=*) SOURCE_DIR="${1#*=}" ;;
        --extension-name=*) EXTENSION_NAME="${1#*=}" ;;
        --install-dir=*) INSTALL_DIR="${1#*=}" ;;
        --debug) DEBUG=true ;;
        --config-*) 
            # Parse config arguments
            CONFIG_KEY="${1#--config-}"
            CONFIG_KEY="${CONFIG_KEY%%=*}"
            CONFIG_VALUE="${1#*=}"
            ;;
    esac
    shift
done

echo "Installing $EXTENSION_NAME extension..."

# Installation logic here
mkdir -p "$INSTALL_DIR"
cp -r "$SOURCE_DIR"/* "$INSTALL_DIR/"

echo "✅ Installation complete"
```

### Basic Python Installer (`install.py`)

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

import argparse
import shutil
from pathlib import Path

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', required=True)
    parser.add_argument('--source-dir', required=True)
    parser.add_argument('--extension-name', required=True)
    parser.add_argument('--install-dir')
    parser.add_argument('--debug', action='store_true')
    
    args, unknown = parser.parse_known_args()
    
    print(f"Installing {args.extension_name} extension...")
    
    # Installation logic here
    if args.install_dir:
        install_path = Path(args.install_dir)
        install_path.mkdir(parents=True, exist_ok=True)
        # Copy files...
    
    print("✅ Installation complete")
    return 0

if __name__ == '__main__':
    sys.exit(main())
```

## Migration Guide

To migrate from `install.sh` to `install.py`:

1. Create `install.py` alongside existing `install.sh`
2. Port installation logic to Python
3. Test both installers work correctly
4. Remove `install.sh` when ready (optional)

The system will automatically use `install.py` when both exist, allowing gradual migration without breaking existing installations.

## Advantages

### Shell Script Advantages
- No Python dependencies needed
- Direct system command execution
- Familiar to system administrators
- Lightweight and fast

### Python Script Advantages
- Cross-platform compatibility
- Better error handling and logging
- Rich standard library
- JSON/YAML parsing built-in
- Complex logic easier to maintain
- Type hints and better IDE support

## Template

A complete template is provided at `/extensions/install.py.template` that includes:
- Argument parsing
- Configuration handling
- Debug output
- Mode-specific logic
- Error handling

Copy this template to start developing your Python-based installer.