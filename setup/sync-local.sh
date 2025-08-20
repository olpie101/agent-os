#!/bin/bash

# Agent OS Local Development Sync Script
# This script syncs local repository files to a base installation for testing
# Usage: ./setup/sync-local.sh [TARGET_DIR]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔄 Agent OS Local Development Sync"
echo "==================================="
echo ""

# Get the repository root (parent of setup directory)
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "📍 Repository directory: $REPO_DIR"

# Get target directory (default to ~/.agent-os-test for safety)
TARGET_DIR="${1:-$HOME/.agent-os-test}"
echo "📍 Target directory: $TARGET_DIR"
echo ""

# Confirm with user
echo -e "${YELLOW}This will sync files from your local repository to $TARGET_DIR${NC}"
echo -e "${YELLOW}This is for testing only. Use base.sh for production installations.${NC}"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "📁 Creating target directories..."
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/setup"
mkdir -p "$TARGET_DIR/instructions/core"
mkdir -p "$TARGET_DIR/instructions/meta"
mkdir -p "$TARGET_DIR/standards/code-style"
mkdir -p "$TARGET_DIR/commands"
mkdir -p "$TARGET_DIR/claude-code/agents"
mkdir -p "$TARGET_DIR/extensions"

# Function to sync a file
sync_file() {
    local source="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -f "$source" ]; then
        cp "$source" "$dest"
        echo -e "  ${GREEN}✓${NC} $desc"
    else
        echo -e "  ${YELLOW}⚠️${NC}  $desc not found at $source"
    fi
}

# Function to sync a directory
sync_directory() {
    local source="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -d "$source" ]; then
        cp -r "$source"/* "$dest"/ 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} $desc"
    else
        echo -e "  ${YELLOW}⚠️${NC}  $desc not found at $source"
    fi
}

echo ""
echo "📥 Syncing setup scripts..."
sync_file "$REPO_DIR/setup/base.sh" "$TARGET_DIR/setup/base.sh" "setup/base.sh"
sync_file "$REPO_DIR/setup/project.sh" "$TARGET_DIR/setup/project.sh" "setup/project.sh"
sync_file "$REPO_DIR/setup/functions.sh" "$TARGET_DIR/setup/functions.sh" "setup/functions.sh"
sync_file "$REPO_DIR/setup/base-extensions.sh" "$TARGET_DIR/setup/base-extensions.sh" "setup/base-extensions.sh"
sync_file "$REPO_DIR/setup/project-extensions.sh" "$TARGET_DIR/setup/project-extensions.sh" "setup/project-extensions.sh"

# Make scripts executable
chmod +x "$TARGET_DIR/setup/"*.sh 2>/dev/null || true

echo ""
echo "📥 Syncing configuration..."
sync_file "$REPO_DIR/config.yml" "$TARGET_DIR/config.yml" "config.yml"

echo ""
echo "📥 Syncing instructions..."
echo "  📂 Core instructions:"
for file in plan-product create-spec create-tasks execute-tasks execute-task analyze-product peer; do
    if [ -f "$REPO_DIR/instructions/core/${file}.md" ]; then
        sync_file "$REPO_DIR/instructions/core/${file}.md" \
                  "$TARGET_DIR/instructions/core/${file}.md" \
                  "instructions/core/${file}.md"
    fi
done

echo ""
echo "  📂 Meta instructions:"
sync_file "$REPO_DIR/instructions/meta/pre-flight.md" \
          "$TARGET_DIR/instructions/meta/pre-flight.md" \
          "instructions/meta/pre-flight.md"

if [ -f "$REPO_DIR/instructions/meta/unified_state_schema.md" ]; then
    sync_file "$REPO_DIR/instructions/meta/unified_state_schema.md" \
              "$TARGET_DIR/instructions/meta/unified_state_schema.md" \
              "instructions/meta/unified_state_schema.md"
fi

echo ""
echo "📥 Syncing standards..."
sync_file "$REPO_DIR/standards/tech-stack.md" "$TARGET_DIR/standards/tech-stack.md" "standards/tech-stack.md"
sync_file "$REPO_DIR/standards/code-style.md" "$TARGET_DIR/standards/code-style.md" "standards/code-style.md"
sync_file "$REPO_DIR/standards/best-practices.md" "$TARGET_DIR/standards/best-practices.md" "standards/best-practices.md"

echo ""
echo "  📂 Code style subdirectory:"
for file in css-style html-style javascript-style; do
    if [ -f "$REPO_DIR/standards/code-style/${file}.md" ]; then
        sync_file "$REPO_DIR/standards/code-style/${file}.md" \
                  "$TARGET_DIR/standards/code-style/${file}.md" \
                  "standards/code-style/${file}.md"
    fi
done

echo ""
echo "📥 Syncing commands..."
for cmd in plan-product create-spec create-tasks execute-tasks analyze-product; do
    if [ -f "$REPO_DIR/commands/${cmd}.md" ]; then
        sync_file "$REPO_DIR/commands/${cmd}.md" \
                  "$TARGET_DIR/commands/${cmd}.md" \
                  "commands/${cmd}.md"
    fi
done

echo ""
echo "📥 Syncing Claude Code agents..."
for agent in context-fetcher date-checker file-creator git-workflow project-manager test-runner process-reflection; do
    if [ -f "$REPO_DIR/claude-code/agents/${agent}.md" ]; then
        sync_file "$REPO_DIR/claude-code/agents/${agent}.md" \
                  "$TARGET_DIR/claude-code/agents/${agent}.md" \
                  "claude-code/agents/${agent}.md"
    fi
done

echo ""
echo "📥 Syncing extensions..."
if [ -d "$REPO_DIR/extensions" ]; then
    # Copy entire extensions directory structure
    cp -r "$REPO_DIR/extensions" "$TARGET_DIR/"
    echo -e "  ${GREEN}✓${NC} Extensions directory structure"
    
    # List what was copied
    if [ -d "$TARGET_DIR/extensions/sandbox" ]; then
        echo -e "  ${GREEN}✓${NC} Sandbox extension"
    fi
    if [ -d "$TARGET_DIR/extensions/hooks" ]; then
        echo -e "  ${GREEN}✓${NC} Hooks extension (stub)"
    fi
    if [ -d "$TARGET_DIR/extensions/peer" ]; then
        echo -e "  ${GREEN}✓${NC} PEER extension (stub)"
    fi
else
    echo -e "  ${YELLOW}⚠️${NC}  Extensions directory not found"
fi

echo ""
echo "🔧 Setting up Agent OS installation structure..."
echo ""

# Set up the installation directory structure (mimicking base.sh)
INSTALL_DIR="$TARGET_DIR/.agent-os"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/setup"

echo "📁 Creating .agent-os directory structure..."
echo -e "  ${GREEN}✓${NC} $INSTALL_DIR"

# Copy setup scripts to the installation directory (mimicking base.sh download behavior)
echo ""
echo "📥 Setting up installation scripts..."
cp "$TARGET_DIR/setup/functions.sh" "$INSTALL_DIR/setup/functions.sh"
cp "$TARGET_DIR/setup/base-extensions.sh" "$INSTALL_DIR/setup/base-extensions.sh"
cp "$TARGET_DIR/setup/project-extensions.sh" "$INSTALL_DIR/setup/project-extensions.sh"
chmod +x "$INSTALL_DIR/setup/"*.sh

echo -e "  ${GREEN}✓${NC} Installation scripts ready"

# Source the functions (mimicking base.sh)
source "$INSTALL_DIR/setup/functions.sh"

echo ""
echo "📥 Installing Agent OS files..."

# Copy core files to installation directory (mimicking base.sh)
echo ""
echo "  📂 Instructions:"
mkdir -p "$INSTALL_DIR/instructions/core"
mkdir -p "$INSTALL_DIR/instructions/meta"
cp -r "$TARGET_DIR/instructions/core"/* "$INSTALL_DIR/instructions/core/" 2>/dev/null || true
cp -r "$TARGET_DIR/instructions/meta"/* "$INSTALL_DIR/instructions/meta/" 2>/dev/null || true
echo -e "    ${GREEN}✓${NC} Core and meta instructions"

echo ""
echo "  📂 Standards:"
mkdir -p "$INSTALL_DIR/standards/code-style"
cp -r "$TARGET_DIR/standards"/* "$INSTALL_DIR/standards/" 2>/dev/null || true
echo -e "    ${GREEN}✓${NC} Development standards"

echo ""
echo "  📂 Commands:"
mkdir -p "$INSTALL_DIR/commands"
cp -r "$TARGET_DIR/commands"/* "$INSTALL_DIR/commands/" 2>/dev/null || true
echo -e "    ${GREEN}✓${NC} Command templates"

echo ""
echo "  📂 Configuration:"
cp "$TARGET_DIR/config.yml" "$INSTALL_DIR/config.yml"
echo -e "    ${GREEN}✓${NC} Base configuration"

echo ""
echo "  📂 Claude Code Agents:"
mkdir -p "$INSTALL_DIR/claude-code/agents"
cp -r "$TARGET_DIR/claude-code/agents"/* "$INSTALL_DIR/claude-code/agents/" 2>/dev/null || true
echo -e "    ${GREEN}✓${NC} Agent templates"

# Set environment variables that base-extensions.sh expects
export INSTALL_DIR="$INSTALL_DIR"
export BASE_DIR="$REPO_DIR"
export SCRIPT_DIR="$INSTALL_DIR/setup"

echo ""
echo "🔧 Running extension installation (base-extensions.sh)..."
echo ""

# Call base-extensions.sh (mimicking base.sh)
INSTALL_DIR_ABS="$(cd "$INSTALL_DIR" && pwd)"
BASE_EXTENSIONS_SCRIPT="$INSTALL_DIR_ABS/setup/base-extensions.sh"
TARGET_DIR_ABS="$(cd "$TARGET_DIR" && pwd)"

if [ -f "$BASE_EXTENSIONS_SCRIPT" ]; then
    echo "  📍 Running: $BASE_EXTENSIONS_SCRIPT"
    echo "  📁 Context: $TARGET_DIR_ABS"
    
    # Change to the target directory context and source the script
    (
        cd "$TARGET_DIR_ABS"
        export INSTALL_DIR="$INSTALL_DIR_ABS"
        export BASE_DIR="$REPO_DIR"
        export SCRIPT_DIR="$INSTALL_DIR_ABS/setup"
        source "$BASE_EXTENSIONS_SCRIPT"
    )
    local_exit_code=$?
    if [ $local_exit_code -ne 0 ]; then
        echo -e "  ${RED}❌${NC} base-extensions.sh failed with exit code $local_exit_code"
        exit $local_exit_code
    fi
else
    echo -e "  ${RED}❌${NC} base-extensions.sh not found at $BASE_EXTENSIONS_SCRIPT!"
    exit 1
fi

echo ""
echo "✅ Local Agent OS installation completed!"
echo ""
echo "📍 Files installed to: $INSTALL_DIR"
echo "🔒 Extensions tested with: base-extensions.sh"
echo ""
echo "📋 Verification commands:"
echo "  ls -la $INSTALL_DIR/extensions/"
echo "  ls -la ~/.claude-code-sandbox/"
echo "  cat $INSTALL_DIR/extensions/installation.log"
echo ""
echo "To test project installation:"
echo "  cd $TARGET_DIR && ./setup/project.sh --claude-code"
echo ""
echo -e "${YELLOW}Note: This is for development only. Always test with actual${NC}"
echo -e "${YELLOW}GitHub downloads before creating PRs.${NC}"
echo ""