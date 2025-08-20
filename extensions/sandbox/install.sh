#!/bin/bash

# Sandbox Extension Installer
# Installs Claude Code sandbox security profile

set -e  # Exit on error

echo "  🔒 Installing sandbox security profile..."

# Get extension directory (where this script is located)
EXT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set installation directory with override support
SANDBOX_INSTALL_DIR="${SANDBOX_INSTALL_DIR:-$HOME/.claude-code-sandbox}"

# Set bin directory with override support for symlink
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

# Load configuration to check if extension is enabled
BASE_CONFIG="$HOME/.agent-os/config.yml"
PROJECT_CONFIG=".agent-os.yaml"

# Function to check if extension is enabled
is_extension_enabled() {
    # Default to enabled if no config exists
    local enabled=true
    
    # Check base config
    if [ -f "$BASE_CONFIG" ]; then
        # Check if sandbox is explicitly disabled (it shouldn't be, as it's required)
        if grep -q "sandbox:" "$BASE_CONFIG" && \
           grep -A2 "sandbox:" "$BASE_CONFIG" | grep -q "enabled: false"; then
            echo "    ⚠️  WARNING: Sandbox is marked as disabled but is a required extension"
            echo "    Proceeding with installation anyway..."
        fi
        
        # Check if it's marked as required
        if grep -q "sandbox:" "$BASE_CONFIG" && \
           grep -A2 "sandbox:" "$BASE_CONFIG" | grep -q "required: true"; then
            echo "    ℹ️  Sandbox is a required extension"
        fi
    fi
    
    return 0  # Always install sandbox as it's required
}

# Check if extension is enabled
if ! is_extension_enabled; then
    echo "    ⚠️  Sandbox extension is disabled in configuration"
    exit 0
fi

# Create installation directory
echo "    Creating sandbox directory at $SANDBOX_INSTALL_DIR..."
mkdir -p "$SANDBOX_INSTALL_DIR"

# Copy sandbox profile
PROFILE_SOURCE="$EXT_DIR/profiles/claude-code-sandbox.sb"
PROFILE_DEST="$SANDBOX_INSTALL_DIR/claude-code-sandbox.sb"

if [ ! -f "$PROFILE_SOURCE" ]; then
    echo "    ❌ ERROR: Sandbox profile not found at $PROFILE_SOURCE"
    exit 1
fi

echo "    Copying sandbox profile..."
cp "$PROFILE_SOURCE" "$PROFILE_DEST"

# Set appropriate permissions
chmod 644 "$PROFILE_DEST"

# Copy launcher script
LAUNCHER_SOURCE="$EXT_DIR/launcher.sh"
LAUNCHER_DEST="$SANDBOX_INSTALL_DIR/launcher.sh"

if [ -f "$LAUNCHER_SOURCE" ]; then
    echo "    Copying launcher script..."
    cp "$LAUNCHER_SOURCE" "$LAUNCHER_DEST"
    chmod +x "$LAUNCHER_DEST"
    echo "    ✅ Launcher script installed at $LAUNCHER_DEST"
    
    # Create symlink in bin directory
    echo "    Creating symlink in $BIN_DIR..."
    mkdir -p "$BIN_DIR"
    
    SYMLINK_PATH="$BIN_DIR/claude-code-sandbox"
    
    # Remove existing symlink if it exists
    if [ -L "$SYMLINK_PATH" ]; then
        rm "$SYMLINK_PATH"
    fi
    
    # Create new symlink
    ln -sf "$LAUNCHER_DEST" "$SYMLINK_PATH"
    
    if [ -L "$SYMLINK_PATH" ]; then
        echo "    ✅ Symlink created at $SYMLINK_PATH"
        
        # Check if BIN_DIR is in PATH
        if ! echo "$PATH" | grep -q "$BIN_DIR"; then
            echo ""
            echo "    ⚠️  Note: $BIN_DIR is not in your PATH"
            echo "       Add the following to your shell configuration:"
            echo "       export PATH=\"$BIN_DIR:\$PATH\""
        fi
    else
        echo "    ⚠️  WARNING: Failed to create symlink at $SYMLINK_PATH"
    fi
else
    echo "    ⚠️  WARNING: Launcher script not found at $LAUNCHER_SOURCE"
    echo "       The sandbox extension will still work, but the 'claude-code-sandbox' command won't be available"
fi

# Create a marker file to indicate successful installation
echo "$(date)" > "$SANDBOX_INSTALL_DIR/.installed"

# Verify installation
if [ -f "$PROFILE_DEST" ]; then
    echo "    ✅ Sandbox profile installed successfully at $PROFILE_DEST"
    
    # Provide instructions for Claude Code configuration
    echo ""
    echo "    📝 To use this sandbox profile with Claude Code:"
    echo "       1. Ensure Claude Code is configured to use sandbox"
    echo "       2. The profile path is: $PROFILE_DEST"
    echo "       3. Sandbox provides security isolation for code execution"
    
    if [ -L "$SYMLINK_PATH" ]; then
        echo ""
        echo "    🚀 You can now use the 'claude-code-sandbox' command"
        echo "       Run: claude-code-sandbox --help for usage information"
    fi
else
    echo "    ❌ ERROR: Failed to install sandbox profile"
    exit 1
fi

# Log installation
LOG_FILE="$SANDBOX_INSTALL_DIR/installation.log"
{
    echo "=== Sandbox Extension Installation ==="
    echo "Date: $(date)"
    echo "Profile: $PROFILE_DEST"
    if [ -f "$LAUNCHER_DEST" ]; then
        echo "Launcher: $LAUNCHER_DEST"
    fi
    if [ -L "$SYMLINK_PATH" ]; then
        echo "Symlink: $SYMLINK_PATH"
    fi
    echo "Status: SUCCESS"
    echo "=== End ==="
} >> "$LOG_FILE"

exit 0