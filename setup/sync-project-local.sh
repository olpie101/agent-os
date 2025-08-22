#!/bin/bash

# Agent OS Local Project Installation Script
# This script installs Agent OS into a project using a local Agent OS installation as source
# Enables offline/disconnected project installations
# Usage: ~/.agent-os/setup/sync-project-local.sh [OPTIONS]

set -e  # Exit on error

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
OVERWRITE_STANDARDS=false
OVERWRITE_EXTENSIONS=false
CLAUDE_CODE=false
PROJECT_TYPE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔄 Agent OS Local Project Installation"
echo "======================================"
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --overwrite-instructions    Overwrite existing instruction files"
    echo "  --overwrite-standards       Overwrite existing standards files"
    echo "  --overwrite-extensions      Overwrite existing extension files"
    echo "  --claude-code               Add Claude Code support"
    echo "  --project-type=TYPE         Use specific project type for installation"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "This script installs Agent OS into the current project directory"
    echo "using your local Agent OS installation as the source."
    echo ""
    exit 0
}

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
        --overwrite-extensions)
            OVERWRITE_EXTENSIONS=true
            shift
            ;;
        --claude-code|--claude|--claude_code)
            CLAUDE_CODE=true
            shift
            ;;
        --project-type=*)
            PROJECT_TYPE="${1#*=}"
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get the Agent OS installation directory (parent of setup directory where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_OS_HOME="$(dirname "$SCRIPT_DIR")"

echo "📍 Using Agent OS installation at: $AGENT_OS_HOME"

# Verify this is a valid Agent OS installation
if [ ! -d "$AGENT_OS_HOME/instructions" ] || [ ! -d "$AGENT_OS_HOME/standards" ]; then
    echo -e "${RED}❌${NC} Invalid Agent OS installation at $AGENT_OS_HOME"
    echo "    Missing required directories (instructions and/or standards)"
    exit 1
fi

# Get project directory info
PROJECT_DIR=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_DIR")
PROJECT_INSTALL_DIR="./.agent-os"

echo "📍 Installing to project: $PROJECT_NAME"
echo "📍 Project directory: $PROJECT_DIR"
echo ""

# Source functions from the Agent OS installation
if [ -f "$AGENT_OS_HOME/setup/functions.sh" ]; then
    source "$AGENT_OS_HOME/setup/functions.sh"
else
    echo -e "${RED}❌${NC} functions.sh not found in Agent OS installation"
    exit 1
fi

# Load configuration hierarchy
if [ -f "$AGENT_OS_HOME/setup/config-loader.sh" ]; then
    echo "🔧 Loading configuration system..."
    source "$AGENT_OS_HOME/setup/config-loader.sh"
    export AGENT_OS_HOME
    export PROJECT_AGENT_OS_DIR="$PROJECT_DIR/.agent-os"
    apply_config_hierarchy
fi

# Auto-enable tools based on config if no flags provided
if [ "$CLAUDE_CODE" = false ] && [ -f "$AGENT_OS_HOME/config.yml" ]; then
    # Check if claude_code is enabled in config
    if grep -q "claude_code:" "$AGENT_OS_HOME/config.yml" && \
       grep -A1 "claude_code:" "$AGENT_OS_HOME/config.yml" | grep -q "enabled: true"; then
        CLAUDE_CODE=true
        echo "  ✓ Auto-enabling Claude Code support (from Agent OS config)"
    fi
fi

# Determine project type
if [ -z "$PROJECT_TYPE" ] && [ -f "$AGENT_OS_HOME/config.yml" ]; then
    # Try to read default_project_type from config
    PROJECT_TYPE=$(grep "^default_project_type:" "$AGENT_OS_HOME/config.yml" | cut -d' ' -f2 | tr -d ' ')
    if [ -z "$PROJECT_TYPE" ]; then
        PROJECT_TYPE="default"
    fi
elif [ -z "$PROJECT_TYPE" ]; then
    PROJECT_TYPE="default"
fi

echo "📦 Using project type: $PROJECT_TYPE"
echo ""

# Determine source paths based on project type
INSTRUCTIONS_SOURCE=""
STANDARDS_SOURCE=""

if [ "$PROJECT_TYPE" = "default" ]; then
    INSTRUCTIONS_SOURCE="$AGENT_OS_HOME/instructions"
    STANDARDS_SOURCE="$AGENT_OS_HOME/standards"
else
    # Look up project type in config
    if [ -f "$AGENT_OS_HOME/config.yml" ] && grep -q "^  $PROJECT_TYPE:" "$AGENT_OS_HOME/config.yml"; then
        # Extract paths for this project type
        INSTRUCTIONS_PATH=$(awk "/^  $PROJECT_TYPE:/{f=1} f&&/instructions:/{print \$2; exit}" "$AGENT_OS_HOME/config.yml")
        STANDARDS_PATH=$(awk "/^  $PROJECT_TYPE:/{f=1} f&&/standards:/{print \$2; exit}" "$AGENT_OS_HOME/config.yml")

        # Expand tilde in paths
        INSTRUCTIONS_SOURCE=$(eval echo "$INSTRUCTIONS_PATH")
        STANDARDS_SOURCE=$(eval echo "$STANDARDS_PATH")

        # Check if paths exist
        if [ ! -d "$INSTRUCTIONS_SOURCE" ] || [ ! -d "$STANDARDS_SOURCE" ]; then
            echo -e "  ${YELLOW}⚠️${NC}  Project type '$PROJECT_TYPE' paths not found, falling back to default"
            INSTRUCTIONS_SOURCE="$AGENT_OS_HOME/instructions"
            STANDARDS_SOURCE="$AGENT_OS_HOME/standards"
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC}  Project type '$PROJECT_TYPE' not found in config, using default"
        INSTRUCTIONS_SOURCE="$AGENT_OS_HOME/instructions"
        STANDARDS_SOURCE="$AGENT_OS_HOME/standards"
    fi
fi

# Create project directories
echo "📁 Creating project directories..."
mkdir -p "$PROJECT_INSTALL_DIR"
mkdir -p "$PROJECT_INSTALL_DIR/instructions/core"
mkdir -p "$PROJECT_INSTALL_DIR/instructions/meta"
mkdir -p "$PROJECT_INSTALL_DIR/standards/code-style"
echo -e "  ${GREEN}✓${NC} Project structure created"
echo ""

# Copy instructions
echo "📥 Installing instruction files..."
copy_directory "$INSTRUCTIONS_SOURCE" "$PROJECT_INSTALL_DIR/instructions" "$OVERWRITE_INSTRUCTIONS"
echo ""

# Copy standards
echo "📥 Installing standards files..."
copy_directory "$STANDARDS_SOURCE" "$PROJECT_INSTALL_DIR/standards" "$OVERWRITE_STANDARDS"
echo ""

# Handle Claude Code installation
if [ "$CLAUDE_CODE" = true ]; then
    echo "📥 Installing Claude Code support..."
    mkdir -p "./.claude/commands"
    mkdir -p "./.claude/agents"

    echo "  📂 Commands:"
    # Copy ALL .md files from commands/
    for file in "$AGENT_OS_HOME"/commands/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            copy_file "$file" "./.claude/commands/$filename" "false" "$filename"
        fi
    done

    echo ""
    echo "  📂 Agents:"
    # Copy ALL .md files from claude-code/agents/
    for file in "$AGENT_OS_HOME"/claude-code/agents/*.md; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            copy_file "$file" "./.claude/agents/$filename" "false" "$filename"
        fi
    done
    echo ""
fi

# Run project-extensions.sh if it exists
if [ -f "$AGENT_OS_HOME/setup/project-extensions.sh" ]; then
    echo "🔧 Running project extensions installer..."
    
    # Build arguments for project-extensions.sh
    PROJ_EXT_ARGS=(
        --install-dir="$AGENT_OS_HOME"
        --project-dir="$PROJECT_DIR"
        --script-dir="$AGENT_OS_HOME/setup"
        --config-file="$AGENT_OS_HOME/config.yml"
    )
    
    # Add overwrite flag if set
    if [ "$OVERWRITE_EXTENSIONS" = true ]; then
        PROJ_EXT_ARGS+=(--overwrite)
    fi
    
    bash "$AGENT_OS_HOME/setup/project-extensions.sh" "${PROJ_EXT_ARGS[@]}"
    echo ""
fi

# Success message
echo ""
echo "✅ Agent OS has been installed in your project ($PROJECT_NAME)!"
echo ""
echo "📍 Project-level files installed to:"
echo "   .agent-os/instructions/    - Agent OS instructions"
echo "   .agent-os/standards/       - Development standards"

if [ "$CLAUDE_CODE" = true ]; then
    echo "   .claude/commands/          - Claude Code commands"
    echo "   .claude/agents/            - Claude Code specialized agents"
fi

echo ""
echo "--------------------------------"
echo ""
echo "Next steps:"
echo ""

if [ "$CLAUDE_CODE" = true ]; then
    echo "Claude Code usage:"
    echo "  /plan-product    - Set the mission & roadmap for a new product"
    echo "  /analyze-product - Set up the mission and roadmap for an existing product"
    echo "  /create-spec     - Create a spec for a new feature"
    echo "  /execute-tasks   - Build and ship code for a new feature"
    echo ""
fi

echo "--------------------------------"
echo ""
echo "This installation was performed offline using your local Agent OS at:"
echo "$AGENT_OS_HOME"
echo ""
echo "Refer to the official Agent OS docs at:"
echo "https://buildermethods.com/agent-os"
echo ""
echo "Keep building! 🚀"
echo ""