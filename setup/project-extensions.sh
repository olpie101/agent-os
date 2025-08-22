#!/bin/bash

# Agent OS Project Extensions Installation Script
# This script handles project-level extension installation using the Python extension manager
# Usage: project-extensions.sh --install-dir="/path" --project-dir="/path" --script-dir="/path" [--config-file="/path"] [--overwrite]

set -e  # Exit on error

# Function to show usage
show_usage() {
    echo "Usage: $0 --install-dir=<path> --project-dir=<path> --script-dir=<path> [options]"
    echo ""
    echo "Required arguments:"
    echo "  --install-dir=<path>    Path to base installation directory (e.g., ~/.agent-os)"
    echo "  --project-dir=<path>    Path to project directory"
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
PROJECT_DIR=""
SCRIPT_DIR=""
CONFIG_FILE=""
OVERWRITE=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --install-dir=*)
            BASE_INSTALL_DIR="${arg#*=}"
            ;;
        --project-dir=*)
            PROJECT_DIR="${arg#*=}"
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

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ Error: --project-dir is required"
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

# Set derived paths
PROJECT_AGENT_OS_DIR="$PROJECT_DIR/.agent-os"
BASE_DIR="$(dirname "$SCRIPT_DIR")"  # Parent directory of setup scripts

echo ""
echo "📦 Installing project extensions..."
echo ""
echo "  📍 Base install directory: $BASE_INSTALL_DIR"
echo "  📍 Project directory: $PROJECT_DIR"
echo "  📍 Script directory: $SCRIPT_DIR"
echo "  📍 Base directory: $BASE_DIR"
echo "  📍 Config file: $CONFIG_FILE"
echo ""

# Create project .agent-os directory if it doesn't exist
if [ ! -d "$PROJECT_AGENT_OS_DIR" ]; then
    echo "  📁 Creating project .agent-os directory..."
    mkdir -p "$PROJECT_AGENT_OS_DIR"
fi

# Create .agent-os.yaml configuration file if it doesn't exist
AGENT_OS_YAML="$PROJECT_AGENT_OS_DIR/.agent-os.yaml"
if [ ! -f "$AGENT_OS_YAML" ]; then
    echo "  📄 Creating .agent-os.yaml configuration..."
    cat > "$AGENT_OS_YAML" << 'EOF'
# Agent OS Project Configuration
# This file configures project-specific settings and extensions

# Project metadata
project:
  name: "${PROJECT_NAME}"
  type: "standard"
  created: "${CREATION_DATE}"

# Extension configuration
extensions:
  # Project-specific extensions go here
  # Only extensions with type: project or both will be installed
  
# Configuration hierarchy (can override base config)
config:
  # Project-specific overrides go here
  # These override settings in ~/.agent-os/config.yml
EOF
    
    # Substitute variables
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    CREATION_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    sed -i.bak "s/\${PROJECT_NAME}/$PROJECT_NAME/g" "$AGENT_OS_YAML"
    sed -i.bak "s/\${CREATION_DATE}/$CREATION_DATE/g" "$AGENT_OS_YAML"
    rm -f "$AGENT_OS_YAML.bak"
    
    echo "  ✓ .agent-os.yaml created"
fi

# Create project config if it doesn't exist
PROJECT_CONFIG="$PROJECT_AGENT_OS_DIR/config.yml"
if [ ! -f "$PROJECT_CONFIG" ]; then
    echo "  📄 Creating project config.yml..."
    cat > "$PROJECT_CONFIG" << 'EOF'
# Agent OS Project Configuration
# This file overrides base configuration for this project

# Extension configuration (project-specific)
extensions:
  # Only project-type extensions should be configured here
  # Example:
  # my_project_extension:
  #   enabled: true
  #   config:
  #     some_setting: value
EOF
    echo "  ✓ Project config.yml created"
fi

# Check for Python extension manager
PYTHON_MANAGER="$SCRIPT_DIR/scripts/manage_extensions.py"
if [ ! -f "$PYTHON_MANAGER" ]; then
    echo "❌ Error: Python extension manager not found at $PYTHON_MANAGER"
    exit 1
fi

# Check for uv
if ! command -v uv &> /dev/null; then
    echo "❌ Error: uv is not installed. Please install uv first."
    echo "  Visit: https://github.com/astral-sh/uv"
    exit 1
fi

# Export environment variables for Python script
export AGENT_OS_HOME="$BASE_INSTALL_DIR"
export AGENT_OS_CONFIG_FILE="$CONFIG_FILE"
export PROJECT_DIR="$PROJECT_DIR"

# Delegate to Python extension manager
echo "🐍 Delegating to Python extension manager..."

# Build command arguments
MANAGER_ARGS=(
    --mode project
    --install-dir "$PROJECT_AGENT_OS_DIR"
    --base-dir "$BASE_DIR"
    --config-file "$CONFIG_FILE"
    --project-config "$PROJECT_CONFIG"
    --debug
)

# Add overwrite flag if set
if [ "$OVERWRITE" = true ]; then
    MANAGER_ARGS+=(--overwrite)
fi

"$PYTHON_MANAGER" "${MANAGER_ARGS[@]}"

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✅ Project extensions installation completed successfully"
    
    # Create project installation log
    LOG_FILE="$PROJECT_AGENT_OS_DIR/extensions/installation.log"
    if [ -f "$LOG_FILE" ]; then
        echo "  📄 Installation log: $LOG_FILE"
    fi
else
    echo ""
    echo "❌ Project extensions installation failed with exit code $exit_code"
    exit $exit_code
fi

echo ""