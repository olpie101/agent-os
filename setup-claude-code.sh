 #!/bin/bash

# Agent OS Claude Code Setup Script
# This script installs Agent OS commands for Claude Code

set -e  # Exit on error

# Initialize flags
USE_LOCAL=false
CUSTOM_BASE_URL=""
OVERWRITE_COMMANDS=false
OVERWRITE_AGENTS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            USE_LOCAL=true
            shift
            ;;
        --base-url)
            CUSTOM_BASE_URL="$2"
            shift 2
            ;;
        --overwrite-commands)
            OVERWRITE_COMMANDS=true
            shift
            ;;
        --overwrite-agents)
            OVERWRITE_AGENTS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --local                     Use local repository files instead of GitHub"
            echo "  --base-url URL              Use custom base URL for downloading files"
            echo "  --overwrite-commands        Overwrite existing command files"
            echo "  --overwrite-agents          Overwrite existing agent files"
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

echo "🚀 Agent OS Claude Code Setup"
echo "============================="
echo ""

# Check if Agent OS base installation is present
if [ ! -d "$HOME/.agent-os/instructions" ] || [ ! -d "$HOME/.agent-os/standards" ]; then
    echo "⚠️  Agent OS base installation not found!"
    echo ""
    echo "Please install the Agent OS base installation first:"
    echo ""
    echo "Option 1 - Automatic installation:"
    echo "  curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/setup.sh | bash"
    echo ""
    echo "Option 2 - Manual installation:"
    echo "  Follow instructions at https://buildermethods.com/agent-os"
    echo ""
    exit 1
fi

# Determine base URL
if [ "$USE_LOCAL" = true ]; then
    # Find the script directory (repository root)
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    BASE_URL="file://$SCRIPT_DIR"
    echo "📁 Using local repository at: $SCRIPT_DIR"
elif [ -n "$CUSTOM_BASE_URL" ]; then
    BASE_URL="$CUSTOM_BASE_URL"
    echo "🌐 Using custom base URL: $BASE_URL"
else
    # Default to GitHub
    BASE_URL="https://raw.githubusercontent.com/buildermethods/agent-os/main"
    echo "🌐 Using GitHub repository"
fi
echo ""

# Function to download or copy files
download_file() {
    local source="$1"
    local destination="$2"
    
    if [ "$USE_LOCAL" = true ]; then
        # For local files, strip the file:// prefix and copy
        local local_source="${source#file://}"
        cp "$local_source" "$destination"
    else
        # For remote files, use curl
        curl -s -o "$destination" "$source"
    fi
}

# Create directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.claude/commands"
mkdir -p "$HOME/.claude/agents"

# Download command files for Claude Code
echo ""
echo "📥 Downloading Claude Code command files to ~/.claude/commands/"

# Commands
for cmd in plan-product create-spec execute-tasks analyze-product peer git-commit; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ] && [ "$OVERWRITE_COMMANDS" = false ]; then
        echo "  ⚠️  ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        download_file "${BASE_URL}/commands/${cmd}.md" "$HOME/.claude/commands/${cmd}.md"
        if [ -f "$HOME/.claude/commands/${cmd}.md" ] && [ "$OVERWRITE_COMMANDS" = true ]; then
            echo "  ✓ ~/.claude/commands/${cmd}.md (overwritten)"
        else
            echo "  ✓ ~/.claude/commands/${cmd}.md"
        fi
    fi
done

# Download Claude Code agents
echo ""
echo "📥 Downloading Claude Code subagents to ~/.claude/agents/"

# List of agent files to download
agents=("test-runner" "context-fetcher" "git-workflow" "file-creator" "date-checker" "peer-planner" "peer-executor" "peer-express" "peer-review" "meta-agent")

for agent in "${agents[@]}"; do
    if [ -f "$HOME/.claude/agents/${agent}.md" ] && [ "$OVERWRITE_AGENTS" = false ]; then
        echo "  ⚠️  ~/.claude/agents/${agent}.md already exists - skipping"
    else
        download_file "${BASE_URL}/claude-code/agents/${agent}.md" "$HOME/.claude/agents/${agent}.md"
        if [ -f "$HOME/.claude/agents/${agent}.md" ] && [ "$OVERWRITE_AGENTS" = true ]; then
            echo "  ✓ ~/.claude/agents/${agent}.md (overwritten)"
        else
            echo "  ✓ ~/.claude/agents/${agent}.md"
        fi
    fi
done

echo ""
echo "✅ Agent OS Claude Code installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.claude/commands/        - Claude Code commands"
echo "   ~/.claude/agents/          - Claude Code specialized subagents"
echo ""
if [ "$OVERWRITE_COMMANDS" = false ] && [ "$OVERWRITE_AGENTS" = false ]; then
    echo "💡 Note: Existing files were skipped to preserve your customizations"
    echo "   Use --overwrite-commands, --overwrite-agents to update specific files"
else
    echo "💡 Note: Some files were overwritten based on your flags"
    if [ "$OVERWRITE_COMMANDS" = false ]; then
        echo "   Existing command files were preserved"
    fi
    if [ "$OVERWRITE_AGENTS" = false ]; then
        echo "   Existing agent files were preserved"
    fi
fi
echo ""
echo "Next steps:"
echo ""
echo "Initiate Agent OS in a new product's codebase with:"
echo "  /plan-product"
echo ""
echo "Initiate Agent OS in an existing product's codebase with:"
echo "  /analyze-product"
echo ""
echo "Initiate a new feature with:"
echo "  /create-spec (or simply ask 'what's next?')"
echo ""
echo "Build and ship code with:"
echo "  /execute-task"
echo ""
echo "Execute any instruction through PEER pattern with:"
echo "  /peer --instruction=<name>"
echo ""
echo "Continue a PEER execution with:"
echo "  /peer --continue"
echo ""
echo "Execute git commits with MCP validation (when available):"
echo "  /peer --instruction=git-commit"
echo ""
echo "Learn more at https://buildermethods.com/agent-os"
echo ""
