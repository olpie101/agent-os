#!/bin/bash

# Agent OS Base Extensions Installation Script
# This script handles global extension installation during base setup

set -e  # Exit on error

echo ""
echo "📦 Installing global extensions..."
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
BASE_INSTALL_DIR="${INSTALL_DIR:-$HOME/.agent-os}"

# Function to copy extension to base installation
copy_extension() {
    local ext_name="$1"
    local source_dir="$BASE_DIR/extensions/$ext_name"
    local dest_dir="$BASE_INSTALL_DIR/extensions/$ext_name"
    
    if [ ! -d "$source_dir" ]; then
        echo "  ⚠️  Extension '$ext_name' not found at $source_dir"
        return 1
    fi
    
    echo "  📂 Copying $ext_name extension..."
    mkdir -p "$dest_dir"
    cp -r "$source_dir"/* "$dest_dir/"
    echo "  ✓ $ext_name extension copied"
    return 0
}

# Function to run extension installer
run_extension_installer() {
    local ext_name="$1"
    local installer="$BASE_INSTALL_DIR/extensions/$ext_name/install.sh"
    
    if [ ! -f "$installer" ]; then
        echo "  ⚠️  No installer found for $ext_name at $installer"
        return 1
    fi
    
    echo "  🔧 Running $ext_name installer..."
    chmod +x "$installer"
    
    # Run installer in a subshell to prevent variable pollution
    (
        cd "$BASE_INSTALL_DIR/extensions/$ext_name"
        ./install.sh
    )
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "  ✓ $ext_name installation completed"
    else
        echo "  ⚠️  $ext_name installation failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# Check if config.yml exists
CONFIG_FILE="$BASE_INSTALL_DIR/config.yml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "  ⚠️  Configuration file not found at $CONFIG_FILE"
    echo "  Proceeding with default extension installation..."
fi

# Install sandbox extension (global, required)
echo ""
echo "🔒 Installing sandbox extension (required)..."

# Copy sandbox extension
if copy_extension "sandbox"; then
    # Run sandbox installer
    if ! run_extension_installer "sandbox"; then
        echo ""
        echo "❌ ERROR: Sandbox extension installation failed!"
        echo "   This is a required extension and installation cannot continue."
        exit 1
    fi
else
    echo ""
    echo "❌ ERROR: Failed to copy sandbox extension!"
    echo "   This is a required extension and installation cannot continue."
    exit 1
fi

echo ""
echo "✅ Global extensions installation completed"
echo ""

# Create installation log
LOG_FILE="$BASE_INSTALL_DIR/extensions/installation.log"
mkdir -p "$(dirname "$LOG_FILE")"
{
    echo "=== Agent OS Extensions Installation Log ==="
    echo "Date: $(date)"
    echo "Base Installation: $BASE_INSTALL_DIR"
    echo ""
    echo "Installed Extensions:"
    echo "  - sandbox (required, global)"
    echo ""
    echo "=== End of Log ==="
} > "$LOG_FILE"

echo "  📄 Installation log saved to: $LOG_FILE"
echo ""