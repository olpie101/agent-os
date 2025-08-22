#!/bin/bash

# Agent OS Base Installation Script
# This script installs Agent OS to the current directory

set -e  # Exit on error

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
OVERWRITE_STANDARDS=false
OVERWRITE_CONFIG=false
CLAUDE_CODE=false
CURSOR=false

# Base URL for raw GitHub content (supports override via AGENT_OS_BASE_URL)
BASE_URL="${AGENT_OS_BASE_URL:-https://raw.githubusercontent.com/olpie101/agent-os/main}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --overwrite-instructions)
            OVERWRITE_INSTRUCTIONS=true
            shift
            ;;
        --overwrite-standards)
            OVERWRITE_STANDARDS=true
            shift
            ;;
        --overwrite-config)
            OVERWRITE_CONFIG=true
            shift
            ;;
        --claude-code|--claude|--claude_code)
            CLAUDE_CODE=true
            shift
            ;;
        --cursor|--cursor-cli)
            CURSOR=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --overwrite-instructions    Overwrite existing instruction files"
            echo "  --overwrite-standards       Overwrite existing standards files"
            echo "  --overwrite-config          Overwrite existing config.yml"
            echo "  --claude-code               Add Claude Code support"
            echo "  --cursor                    Add Cursor support"
            echo "  -h, --help                  Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo ""
echo "🚀 Agent OS Base Installation"
echo "============================="
echo ""

# Set installation directory to current directory
CURRENT_DIR=$(pwd)
INSTALL_DIR="$CURRENT_DIR/.agent-os"

echo "📍 The Agent OS base installation will be installed in the current directory ($CURRENT_DIR)"
echo ""

echo "📁 Creating base directories..."
echo ""
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/setup"

# Download functions.sh to its permanent location and source it
echo "📥 Downloading setup functions..."
curl -sSL "${BASE_URL}/setup/functions.sh" -o "$INSTALL_DIR/setup/functions.sh"
source "$INSTALL_DIR/setup/functions.sh"

# Load configuration hierarchy (if config-loader.sh exists)
if [ -f "$INSTALL_DIR/setup/config-loader.sh" ]; then
    echo "🔧 Loading configuration hierarchy..."
    source "$INSTALL_DIR/setup/config-loader.sh"
    export AGENT_OS_HOME="$INSTALL_DIR"
    apply_config_hierarchy
fi

echo ""
echo "📦 Installing the latest version of Agent OS from the Agent OS GitHub repository..."

# Install /instructions, /standards, and /commands folders and files from GitHub
install_from_github "$INSTALL_DIR" "$OVERWRITE_INSTRUCTIONS" "$OVERWRITE_STANDARDS"

# Download config.yml
echo ""
echo "📥 Downloading configuration..."
download_file "${BASE_URL}/config.yml" \
    "$INSTALL_DIR/config.yml" \
    "$OVERWRITE_CONFIG" \
    "config.yml"

# Download setup/project.sh
echo ""
echo "📥 Downloading project setup script..."
download_file "${BASE_URL}/setup/project.sh" \
    "$INSTALL_DIR/setup/project.sh" \
    "true" \
    "setup/project.sh"
chmod +x "$INSTALL_DIR/setup/project.sh"

# Download extension scripts
echo ""
echo "📥 Downloading extension scripts..."
download_file "${BASE_URL}/setup/base-extensions.sh" \
    "$INSTALL_DIR/setup/base-extensions.sh" \
    "true" \
    "setup/base-extensions.sh"
chmod +x "$INSTALL_DIR/setup/base-extensions.sh"

download_file "${BASE_URL}/setup/project-extensions.sh" \
    "$INSTALL_DIR/setup/project-extensions.sh" \
    "true" \
    "setup/project-extensions.sh"
chmod +x "$INSTALL_DIR/setup/project-extensions.sh"

download_file "${BASE_URL}/setup/sync-project-local.sh" \
    "$INSTALL_DIR/setup/sync-project-local.sh" \
    "true" \
    "setup/sync-project-local.sh"
chmod +x "$INSTALL_DIR/setup/sync-project-local.sh"

# Download Python extension manager and its modules
echo "📥 Downloading Python extension manager..."
mkdir -p "$INSTALL_DIR/setup/scripts"
download_file "${BASE_URL}/setup/scripts/manage_extensions.py" \
    "$INSTALL_DIR/setup/scripts/manage_extensions.py" \
    "true" \
    "setup/scripts/manage_extensions.py"
download_file "${BASE_URL}/setup/scripts/config_manager.py" \
    "$INSTALL_DIR/setup/scripts/config_manager.py" \
    "true" \
    "setup/scripts/config_manager.py"
download_file "${BASE_URL}/setup/scripts/extension_manager.py" \
    "$INSTALL_DIR/setup/scripts/extension_manager.py" \
    "true" \
    "setup/scripts/extension_manager.py"
download_file "${BASE_URL}/setup/scripts/extension_installer.py" \
    "$INSTALL_DIR/setup/scripts/extension_installer.py" \
    "true" \
    "setup/scripts/extension_installer.py"
chmod +x "$INSTALL_DIR/setup/scripts/"*.py

# Handle Claude Code installation
if [ "$CLAUDE_CODE" = true ]; then
    echo ""
    echo "📥 Downloading Claude Code agent templates..."
    mkdir -p "$INSTALL_DIR/claude-code/agents"

    # Download agents to base installation for project use
    echo "  📂 Agent templates:"
    for agent in context-fetcher date-checker file-creator git-workflow project-manager test-runner; do
        download_file "${BASE_URL}/claude-code/agents/${agent}.md" \
            "$INSTALL_DIR/claude-code/agents/${agent}.md" \
            "false" \
            "claude-code/agents/${agent}.md"
    done

    # Update config to enable claude_code
    if [ -f "$INSTALL_DIR/config.yml" ]; then
        sed -i.bak '/claude_code:/,/enabled:/ s/enabled: false/enabled: true/' "$INSTALL_DIR/config.yml" && rm "$INSTALL_DIR/config.yml.bak"
    fi
fi

# Handle Cursor installation
if [ "$CURSOR" = true ]; then
    echo ""
    echo "📥 Enabling Cursor support..."

    # Only update config to enable cursor
    if [ -f "$INSTALL_DIR/config.yml" ]; then
        sed -i.bak '/cursor:/,/enabled:/ s/enabled: false/enabled: true/' "$INSTALL_DIR/config.yml" && rm "$INSTALL_DIR/config.yml.bak"
        echo "  ✓ Cursor enabled in configuration"
    fi
fi

# Call base-extensions.sh if it exists (for extension installation)
if [ -f "$INSTALL_DIR/setup/base-extensions.sh" ]; then
    # For base.sh, the base-dir is the installation directory itself
    # since we downloaded files from GitHub
    echo "[DEBUG] base.sh: AGENT_OS_HOME before calling base-extensions.sh: '${AGENT_OS_HOME}'"
    bash "$INSTALL_DIR/setup/base-extensions.sh" \
        --install-dir="$INSTALL_DIR" \
        --base-dir="$INSTALL_DIR" \
        --script-dir="$INSTALL_DIR/setup" \
        --config-file="$INSTALL_DIR/config.yml"
fi

# Success message
echo ""
echo "✅ Agent OS base installation has been completed."
echo ""

# Dynamic project installation command
PROJECT_SCRIPT="$INSTALL_DIR/setup/project.sh"
echo "--------------------------------"
echo ""
echo "To install Agent OS in a project, run:"
echo ""
echo "   cd <project-directory>"
echo "   $PROJECT_SCRIPT"
echo ""
echo "--------------------------------"
echo ""
echo "📍 Base installation files installed to:"
echo "   $INSTALL_DIR/instructions/      - Agent OS instructions"
echo "   $INSTALL_DIR/standards/         - Development standards"
echo "   $INSTALL_DIR/commands/          - Command templates"
echo "   $INSTALL_DIR/config.yml         - Configuration"
echo "   $INSTALL_DIR/setup/project.sh   - Project installation script (online)"
echo "   $INSTALL_DIR/setup/sync-project-local.sh - Project installation script (offline)"

if [ "$CLAUDE_CODE" = true ]; then
    echo "   $INSTALL_DIR/claude-code/agents/ - Claude Code agent templates"
fi

echo ""
echo "--------------------------------"
echo ""
echo "Next steps:"
echo ""
echo "1. Customize your standards in $INSTALL_DIR/standards/"
echo ""
echo "2. Configure project types in $INSTALL_DIR/config.yml"
echo ""
echo "3. Navigate to a project directory and run:"
echo "   - Online:  $PROJECT_SCRIPT"
echo "   - Offline: $INSTALL_DIR/setup/sync-project-local.sh"
echo ""
echo "--------------------------------"
echo ""
echo "Refer to the official Agent OS docs at:"
echo "https://buildermethods.com/agent-os"
echo ""
echo "Keep building! 🚀"
echo ""
echo
