#!/bin/bash

# Agent OS Base Extensions Installation Script
# This script handles global extension installation during base setup
# Usage: base-extensions.sh --install-dir="/path" --base-dir="/path" --script-dir="/path" [--config-file="/path"]

set -e  # Exit on error

# Function to show usage
show_usage() {
    echo "Usage: $0 --install-dir=<path> --base-dir=<path> --script-dir=<path> [--config-file=<path>]"
    echo ""
    echo "Required arguments:"
    echo "  --install-dir=<path>    Path to installation directory (e.g., ~/.agent-os)"
    echo "  --base-dir=<path>       Path to repository base directory"
    echo "  --script-dir=<path>     Path to setup scripts directory"
    echo ""
    echo "Optional arguments:"
    echo "  --config-file=<path>    Path to configuration file (default: <install-dir>/config.yml)"
    echo "  --overwrite             Overwrite existing extension files"
    echo "  --help                  Show this help message"
    exit 1
}

# Initialize variables
BASE_INSTALL_DIR=""
BASE_DIR=""
SCRIPT_DIR=""
CONFIG_FILE=""
OVERWRITE=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --install-dir=*)
            BASE_INSTALL_DIR="${arg#*=}"
            ;;
        --base-dir=*)
            BASE_DIR="${arg#*=}"
            ;;
        --script-dir=*)
            SCRIPT_DIR="${arg#*=}"
            ;;
        --config-file=*)
            CONFIG_FILE="${arg#*=}"
            ;;
        --overwrite)
            OVERWRITE=true
            ;;
        --help)
            show_usage
            ;;
        *)
            echo "Unknown argument: $arg"
            show_usage
            ;;
    esac
done

# Validate required arguments
if [ -z "$BASE_INSTALL_DIR" ]; then
    echo "❌ Error: --install-dir is required"
    show_usage
fi

if [ -z "$BASE_DIR" ]; then
    echo "❌ Error: --base-dir is required"
    show_usage
fi

if [ -z "$SCRIPT_DIR" ]; then
    echo "❌ Error: --script-dir is required"
    show_usage
fi

# Set default config file if not provided
if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="$BASE_INSTALL_DIR/config.yml"
fi

echo ""
echo "📦 Installing global extensions..."
echo ""
echo "  📍 Install directory: $BASE_INSTALL_DIR"
echo "  📍 Base directory: $BASE_DIR"
echo "  📍 Script directory: $SCRIPT_DIR"
echo "  📍 Config file: $CONFIG_FILE"
echo ""

# Check if Python extension manager exists
PYTHON_MANAGER="$SCRIPT_DIR/scripts/manage_extensions.py"
if [ ! -f "$PYTHON_MANAGER" ]; then
    echo "❌ ERROR: Extension manager not found at $PYTHON_MANAGER"
    exit 1
fi

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo "❌ ERROR: uv is required but not installed"
    echo "  Please install uv: https://github.com/astral-sh/uv"
    exit 1
fi

# Export environment variables for Python script
export AGENT_OS_HOME="$BASE_INSTALL_DIR"
export AGENT_OS_CONFIG_FILE="$CONFIG_FILE"

# Delegate to Python extension manager
echo "🐍 Delegating to Python extension manager..."

# Build command arguments
MANAGER_ARGS=(
    --mode base
    --install-dir "$BASE_INSTALL_DIR"
    --base-dir "$BASE_DIR"
    --config-file "$CONFIG_FILE"
)

# Add overwrite flag if set
if [ "$OVERWRITE" = true ]; then
    MANAGER_ARGS+=(--overwrite)
fi

"$PYTHON_MANAGER" "${MANAGER_ARGS[@]}"

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "✅ Base extensions installation completed successfully"
else
    echo "❌ Base extensions installation failed with exit code $exit_code"
    exit $exit_code
fi

# The rest of the script is now handled by Python
exit 0
