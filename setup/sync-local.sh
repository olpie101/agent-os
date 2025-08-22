#!/bin/bash

# Agent OS Local Development Sync Script
# This script replicates the output of base.sh for local testing
# Usage: ./setup/sync-local.sh [TARGET_DIR] --config CONFIG_FILE

set -e  # Exit on error

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
OVERWRITE_STANDARDS=false
OVERWRITE_CONFIG=false
OVERWRITE_EXTENSIONS=false
CONFIG_FILE=""
TARGET_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔄 Agent OS Local Development Sync"
echo "==================================="
echo ""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TARGET_DIR]"
    echo ""
    echo "Options:"
    echo "  --config FILE               Configuration file to use (e.g., config.yml)"
    echo "  --overwrite-instructions    Overwrite existing instruction files"
    echo "  --overwrite-standards       Overwrite existing standards files"
    echo "  --overwrite-config          Overwrite existing config.yml"
    echo "  --overwrite-extensions      Overwrite existing extension files"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Arguments:"
    echo "  TARGET_DIR    Target installation directory (default: ~/.agent-os)"
    echo ""
    echo "Examples:"
    echo "  $0                                   # Install to default location"
    echo "  $0 ~/my-agent-os                     # Install to custom location"
    echo "  $0 --config config.yml                # Use specific config, default location"
    echo "  $0 ~/test --config test-config.yml   # Custom location and config"
    echo ""
    exit 0
}

# Parse command line arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
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
        --overwrite-extensions)
            OVERWRITE_EXTENSIONS=true
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        -*|--*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

# Get the repository root (parent of setup directory)
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "📍 Repository directory: $REPO_DIR"

# Get target directory - now only first positional argument
# Default to ~/.agent-os (standard location) instead of test location
TARGET_DIR="${1:-$HOME/.agent-os}"

# Support backward compatibility: if second positional arg looks like a config file, use it
if [ -n "${2:-}" ] && [[ "${2}" == *.yml || "${2}" == *.yaml ]]; then
    if [ -z "$CONFIG_FILE" ]; then
        CONFIG_FILE="$2"
        echo -e "${YELLOW}Note: Using legacy syntax. Consider using --config flag instead.${NC}"
    fi
fi

echo "📍 Target directory: $TARGET_DIR"

# Validate config file if provided
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    echo "📍 Using config file: $CONFIG_FILE"
    export CONFIG_FILE
elif [ -n "$CONFIG_FILE" ]; then
    echo -e "${RED}❌${NC} Config file not found: $CONFIG_FILE"
    exit 1
fi
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
echo "🔧 Setting up Agent OS installation structure..."
echo ""

# Set up the installation directory structure (mimicking base.sh output)
INSTALL_DIR="$TARGET_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/setup"
mkdir -p "$INSTALL_DIR/instructions/core"
mkdir -p "$INSTALL_DIR/instructions/meta"
mkdir -p "$INSTALL_DIR/standards/code-style"
mkdir -p "$INSTALL_DIR/commands"
mkdir -p "$INSTALL_DIR/claude-code/agents"
mkdir -p "$INSTALL_DIR/extensions"

echo "📁 Creating directory structure..."
echo -e "  ${GREEN}✓${NC} $INSTALL_DIR"

# Function to sync a file with overwrite protection
sync_file() {
    local source="$1"
    local dest="$2"
    local desc="$3"
    local overwrite="${4:-false}"
    
    if [ -f "$dest" ] && [ "$overwrite" = false ]; then
        echo -e "  ${YELLOW}⚠️${NC}  $desc already exists - skipping"
        return 0
    fi
    
    if [ -f "$source" ]; then
        cp "$source" "$dest"
        if [ -f "$dest" ] && [ "$overwrite" = true ]; then
            echo -e "  ${GREEN}✓${NC} $desc (overwritten)"
        else
            echo -e "  ${GREEN}✓${NC} $desc"
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC}  $desc not found at $source"
    fi
}

# Function to sync a directory with overwrite protection
sync_directory() {
    local source="$1"
    local dest="$2"
    local desc="$3"
    local overwrite="${4:-false}"
    
    if [ -d "$dest" ] && [ "$(ls -A $dest 2>/dev/null)" ] && [ "$overwrite" = false ]; then
        echo -e "  ${YELLOW}⚠️${NC}  $desc already exists with content - skipping"
        return 0
    fi
    
    if [ -d "$source" ]; then
        if [ -d "$dest" ] && [ "$overwrite" = true ]; then
            rm -rf "$dest"/*
        fi
        cp -r "$source"/* "$dest"/ 2>/dev/null || true
        if [ "$overwrite" = true ] && [ -d "$dest" ]; then
            echo -e "  ${GREEN}✓${NC} $desc (overwritten)"
        else
            echo -e "  ${GREEN}✓${NC} $desc"
        fi
    else
        echo -e "  ${YELLOW}⚠️${NC}  $desc not found at $source"
    fi
}

# Copy configuration loader and base-extensions.sh for extension installation
echo ""
echo "📥 Setting up configuration and extension system..."
# These system files are always overwritten to ensure consistency
sync_file "$REPO_DIR/setup/config-loader.sh" "$INSTALL_DIR/setup/config-loader.sh" "config-loader.sh" true
sync_file "$REPO_DIR/setup/functions.sh" "$INSTALL_DIR/setup/functions.sh" "functions.sh" true
sync_file "$REPO_DIR/setup/base-extensions.sh" "$INSTALL_DIR/setup/base-extensions.sh" "base-extensions.sh" true
sync_file "$REPO_DIR/setup/project.sh" "$INSTALL_DIR/setup/project.sh" "project.sh" true
sync_file "$REPO_DIR/setup/project-extensions.sh" "$INSTALL_DIR/setup/project-extensions.sh" "project-extensions.sh" true

# Copy Python extension manager and its modules
mkdir -p "$INSTALL_DIR/setup/scripts"
# System scripts are always overwritten to ensure consistency
sync_file "$REPO_DIR/setup/scripts/manage_extensions.py" "$INSTALL_DIR/setup/scripts/manage_extensions.py" "scripts/manage_extensions.py" true
sync_file "$REPO_DIR/setup/scripts/config_manager.py" "$INSTALL_DIR/setup/scripts/config_manager.py" "scripts/config_manager.py" true
sync_file "$REPO_DIR/setup/scripts/extension_manager.py" "$INSTALL_DIR/setup/scripts/extension_manager.py" "scripts/extension_manager.py" true
sync_file "$REPO_DIR/setup/scripts/extension_installer.py" "$INSTALL_DIR/setup/scripts/extension_installer.py" "scripts/extension_installer.py" true

chmod +x "$INSTALL_DIR/setup/"*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR/setup/scripts/"*.py 2>/dev/null || true

# Copy configuration file (use provided CONFIG_FILE or default)
echo ""
echo "📥 Installing configuration..."
if [ -n "$CONFIG_FILE" ]; then
    sync_file "$CONFIG_FILE" "$INSTALL_DIR/config.yml" "config.yml (from $CONFIG_FILE)" "$OVERWRITE_CONFIG"
else
    sync_file "$REPO_DIR/config.yml" "$INSTALL_DIR/config.yml" "config.yml" "$OVERWRITE_CONFIG"
fi

echo ""
echo "📥 Syncing instructions..."
echo "  📂 Core instructions:"
for file in plan-product create-spec create-tasks execute-tasks execute-task analyze-product peer; do
    if [ -f "$REPO_DIR/instructions/core/${file}.md" ]; then
        sync_file "$REPO_DIR/instructions/core/${file}.md" \
                  "$TARGET_DIR/instructions/core/${file}.md" \
                  "instructions/core/${file}.md" \
                  "$OVERWRITE_INSTRUCTIONS"
    fi
done

echo ""
echo "  📂 Meta instructions:"
sync_file "$REPO_DIR/instructions/meta/pre-flight.md" \
          "$TARGET_DIR/instructions/meta/pre-flight.md" \
          "instructions/meta/pre-flight.md" \
          "$OVERWRITE_INSTRUCTIONS"

if [ -f "$REPO_DIR/instructions/meta/unified_state_schema.md" ]; then
    sync_file "$REPO_DIR/instructions/meta/unified_state_schema.md" \
              "$TARGET_DIR/instructions/meta/unified_state_schema.md" \
              "instructions/meta/unified_state_schema.md" \
              "$OVERWRITE_INSTRUCTIONS"
fi

echo ""
echo "📥 Syncing standards..."
sync_file "$REPO_DIR/standards/tech-stack.md" "$TARGET_DIR/standards/tech-stack.md" "standards/tech-stack.md" "$OVERWRITE_STANDARDS"
sync_file "$REPO_DIR/standards/code-style.md" "$TARGET_DIR/standards/code-style.md" "standards/code-style.md" "$OVERWRITE_STANDARDS"
sync_file "$REPO_DIR/standards/best-practices.md" "$TARGET_DIR/standards/best-practices.md" "standards/best-practices.md" "$OVERWRITE_STANDARDS"

echo ""
echo "  📂 Code style subdirectory:"
for file in css-style html-style javascript-style; do
    if [ -f "$REPO_DIR/standards/code-style/${file}.md" ]; then
        sync_file "$REPO_DIR/standards/code-style/${file}.md" \
                  "$TARGET_DIR/standards/code-style/${file}.md" \
                  "standards/code-style/${file}.md" \
                  "$OVERWRITE_STANDARDS"
    fi
done

echo ""
echo "📥 Syncing commands..."
for cmd in plan-product create-spec create-tasks execute-tasks analyze-product; do
    if [ -f "$REPO_DIR/commands/${cmd}.md" ]; then
        sync_file "$REPO_DIR/commands/${cmd}.md" \
                  "$TARGET_DIR/commands/${cmd}.md" \
                  "commands/${cmd}.md" \
                  true  # Commands are always overwritten
    fi
done

echo ""
echo "📥 Syncing Claude Code agents..."
for agent in context-fetcher date-checker file-creator git-workflow project-manager test-runner process-reflection; do
    if [ -f "$REPO_DIR/claude-code/agents/${agent}.md" ]; then
        sync_file "$REPO_DIR/claude-code/agents/${agent}.md" \
                  "$TARGET_DIR/claude-code/agents/${agent}.md" \
                  "claude-code/agents/${agent}.md" \
                  true  # Agents are always overwritten
    fi
done

echo ""
echo "📥 Syncing extensions..."
if [ -d "$REPO_DIR/extensions" ]; then
    if [ -d "$INSTALL_DIR/extensions" ] && [ "$OVERWRITE_EXTENSIONS" = false ]; then
        echo -e "  ${YELLOW}⚠️${NC}  Extensions directory already exists - skipping"
    else
        # Copy entire extensions directory structure
        if [ -d "$INSTALL_DIR/extensions" ] && [ "$OVERWRITE_EXTENSIONS" = true ]; then
            rm -rf "$INSTALL_DIR/extensions"
        fi
        cp -r "$REPO_DIR/extensions" "$INSTALL_DIR/"
        if [ "$OVERWRITE_EXTENSIONS" = true ] && [ -d "$INSTALL_DIR/extensions" ]; then
            echo -e "  ${GREEN}✓${NC} Extensions directory structure (overwritten)"
        else
            echo -e "  ${GREEN}✓${NC} Extensions directory structure"
        fi
        
        # List what was copied
        if [ -d "$INSTALL_DIR/extensions/sandbox" ]; then
            echo -e "  ${GREEN}✓${NC} Sandbox extension available"
        fi
        if [ -d "$INSTALL_DIR/extensions/hooks" ]; then
            echo -e "  ${GREEN}✓${NC} Hooks extension available"
        fi
        if [ -d "$INSTALL_DIR/extensions/peer" ]; then
            echo -e "  ${GREEN}✓${NC} PEER extension available"
        fi
    fi
else
    echo -e "  ${YELLOW}⚠️${NC}  Extensions directory not found"
fi

# Source the functions
source "$INSTALL_DIR/setup/functions.sh"

# Source configuration loader to use config system
if [ -f "$INSTALL_DIR/setup/config-loader.sh" ]; then
    echo ""
    echo "🔧 Loading configuration system..."
    source "$INSTALL_DIR/setup/config-loader.sh"
    export AGENT_OS_HOME="$INSTALL_DIR"
    apply_config_hierarchy
else
    echo ""
    echo "  ⚠️  Configuration loader not found, using defaults..."
fi

# Set environment variables that base-extensions.sh expects
export INSTALL_DIR="$INSTALL_DIR"
export BASE_DIR="$REPO_DIR"
export SCRIPT_DIR="$INSTALL_DIR/setup"

echo ""
echo "🔧 Running extension installation..."
echo ""

# Run base-extensions.sh to install extensions based on configuration
BASE_EXTENSIONS_SCRIPT="$INSTALL_DIR/setup/base-extensions.sh"

if [ -f "$BASE_EXTENSIONS_SCRIPT" ]; then
    echo "<<<<< BASE EXTENSIONS SCRIPT >>>>>"
    echo "  📍 Running: $BASE_EXTENSIONS_SCRIPT"
    
    # Determine config file to use
    CONFIG_TO_USE="${CONFIG_FILE:-$INSTALL_DIR/config.yml}"
    
    # Run the extensions installer with command-line arguments
    # Add overwrite flag if set
    EXTENSION_ARGS=(
        --install-dir="$INSTALL_DIR"
        --base-dir="$REPO_DIR"
        --script-dir="$INSTALL_DIR/setup"
        --config-file="$CONFIG_TO_USE"
    )
    
    if [ "$OVERWRITE_EXTENSIONS" = true ]; then
        EXTENSION_ARGS+=(--overwrite)
    fi
    
    bash "$BASE_EXTENSIONS_SCRIPT" "${EXTENSION_ARGS[@]}"
    
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
echo "📍 Installation directory: $INSTALL_DIR"
echo "📄 Configuration used: ${CONFIG_FILE:-$INSTALL_DIR/config.yml}"
echo "🔒 Extensions installed based on configuration"
echo ""
echo "📋 Verification commands:"
echo "  cat $INSTALL_DIR/extensions/installation.log"
echo "  ls -la $INSTALL_DIR/extensions/"
echo "  ls -la ~/.claude-code-sandbox/"
echo ""
echo "To test project installation:"
echo "  mkdir -p ./tmp/test-project"
echo "  cd ./tmp/test-project"
echo "  $INSTALL_DIR/setup/project.sh --claude-code"
echo ""
echo "To test with disabled extensions:"
echo "  # Create custom config with extensions disabled"
echo "  cp $INSTALL_DIR/config.yml ./tmp/test-config.yml"
echo "  # Edit test-config.yml to disable extensions"
echo "  ./setup/sync-local.sh ./tmp/agent-os-test2 ./tmp/test-config.yml"
echo ""
echo -e "${YELLOW}Note: This is for development only. Always test with actual${NC}"
echo -e "${YELLOW}GitHub downloads before creating PRs.${NC}"
echo ""
