 #!/bin/bash

# Agent OS Claude Code Setup Script
# This script installs Agent OS commands for Claude Code

set -e  # Exit on error

# Initialize flags
USE_LOCAL=false
CUSTOM_BASE_URL=""
OVERWRITE_COMMANDS=false
OVERWRITE_AGENTS=false
OVERWRITE_HOOKS=false
UPDATE_SETTINGS=false

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
        --overwrite-hooks)
            OVERWRITE_HOOKS=true
            shift
            ;;
        --update-settings)
            UPDATE_SETTINGS=true
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
            echo "  --overwrite-hooks           Overwrite existing hook files"
            echo "  --update-settings           Update ~/.claude/settings.json with hooks configuration"
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
for cmd in all-tools plan-product create-spec execute-tasks analyze-product peer git-commit; do
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

# Install Claude Code hooks
echo ""
echo "📥 Installing Claude Code hooks to ~/.claude/hooks/"

# Create hooks directories
mkdir -p "$HOME/.claude/hooks/utils/llm"
mkdir -p "$HOME/.claude/hooks/utils/tts"
mkdir -p "$HOME/.claude/hooks/instructions"

# Copy hook files (excluding test files)
if [ "$USE_LOCAL" = true ]; then
    # For local installation, copy from repository
    HOOKS_SOURCE="$SCRIPT_DIR/claude-code/hooks"
    
    # Copy main hook files
    for hook_file in notification.py post_tool_use.py pre_compact.py pre_tool_use.py session_start.py stop.py subagent_stop.py user_prompt_submit.py; do
        if [ -f "$HOOKS_SOURCE/$hook_file" ]; then
            if [ -f "$HOME/.claude/hooks/$hook_file" ] && [ "$OVERWRITE_HOOKS" = false ]; then
                echo "  ⚠️  ~/.claude/hooks/$hook_file already exists - skipping"
            else
                cp "$HOOKS_SOURCE/$hook_file" "$HOME/.claude/hooks/"
                if [ -f "$HOME/.claude/hooks/$hook_file" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                    echo "  ✓ ~/.claude/hooks/$hook_file (overwritten)"
                else
                    echo "  ✓ ~/.claude/hooks/$hook_file"
                fi
            fi
        fi
    done
    
    # Copy instructions
    if [ -f "$HOOKS_SOURCE/instructions/reminder.md" ]; then
        if [ -f "$HOME/.claude/hooks/instructions/reminder.md" ] && [ "$OVERWRITE_HOOKS" = false ]; then
            echo "  ⚠️  ~/.claude/hooks/instructions/reminder.md already exists - skipping"
        else
            cp "$HOOKS_SOURCE/instructions/reminder.md" "$HOME/.claude/hooks/instructions/"
            if [ -f "$HOME/.claude/hooks/instructions/reminder.md" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                echo "  ✓ ~/.claude/hooks/instructions/reminder.md (overwritten)"
            else
                echo "  ✓ ~/.claude/hooks/instructions/reminder.md"
            fi
        fi
    fi
    
    # Copy LLM utilities (excluding test files)
    for llm_file in anth.py gemini.py oai.py; do
        if [ -f "$HOOKS_SOURCE/utils/llm/$llm_file" ]; then
            if [ -f "$HOME/.claude/hooks/utils/llm/$llm_file" ] && [ "$OVERWRITE_HOOKS" = false ]; then
                echo "  ⚠️  ~/.claude/hooks/utils/llm/$llm_file already exists - skipping"
            else
                cp "$HOOKS_SOURCE/utils/llm/$llm_file" "$HOME/.claude/hooks/utils/llm/"
                if [ -f "$HOME/.claude/hooks/utils/llm/$llm_file" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                    echo "  ✓ ~/.claude/hooks/utils/llm/$llm_file (overwritten)"
                else
                    echo "  ✓ ~/.claude/hooks/utils/llm/$llm_file"
                fi
            fi
        fi
    done
    
    # Copy TTS utilities (excluding test files)
    for tts_file in elevenlabs_tts.py gemini_tts.py openai_tts.py pyttsx3_tts.py; do
        if [ -f "$HOOKS_SOURCE/utils/tts/$tts_file" ]; then
            if [ -f "$HOME/.claude/hooks/utils/tts/$tts_file" ] && [ "$OVERWRITE_HOOKS" = false ]; then
                echo "  ⚠️  ~/.claude/hooks/utils/tts/$tts_file already exists - skipping"
            else
                cp "$HOOKS_SOURCE/utils/tts/$tts_file" "$HOME/.claude/hooks/utils/tts/"
                if [ -f "$HOME/.claude/hooks/utils/tts/$tts_file" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                    echo "  ✓ ~/.claude/hooks/utils/tts/$tts_file (overwritten)"
                else
                    echo "  ✓ ~/.claude/hooks/utils/tts/$tts_file"
                fi
            fi
        fi
    done
else
    # For remote installation, download from GitHub
    # Main hook files
    for hook_file in notification.py post_tool_use.py pre_compact.py pre_tool_use.py session_start.py stop.py subagent_stop.py user_prompt_submit.py; do
        if [ -f "$HOME/.claude/hooks/$hook_file" ] && [ "$OVERWRITE_HOOKS" = false ]; then
            echo "  ⚠️  ~/.claude/hooks/$hook_file already exists - skipping"
        else
            download_file "${BASE_URL}/claude-code/hooks/${hook_file}" "$HOME/.claude/hooks/${hook_file}"
            if [ -f "$HOME/.claude/hooks/$hook_file" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                echo "  ✓ ~/.claude/hooks/$hook_file (overwritten)"
            else
                echo "  ✓ ~/.claude/hooks/$hook_file"
            fi
        fi
    done
    
    # Instructions
    if [ -f "$HOME/.claude/hooks/instructions/reminder.md" ] && [ "$OVERWRITE_HOOKS" = false ]; then
        echo "  ⚠️  ~/.claude/hooks/instructions/reminder.md already exists - skipping"
    else
        download_file "${BASE_URL}/claude-code/hooks/instructions/reminder.md" "$HOME/.claude/hooks/instructions/reminder.md"
        if [ -f "$HOME/.claude/hooks/instructions/reminder.md" ] && [ "$OVERWRITE_HOOKS" = true ]; then
            echo "  ✓ ~/.claude/hooks/instructions/reminder.md (overwritten)"
        else
            echo "  ✓ ~/.claude/hooks/instructions/reminder.md"
        fi
    fi
    
    # LLM utilities
    for llm_file in anth.py gemini.py oai.py; do
        if [ -f "$HOME/.claude/hooks/utils/llm/$llm_file" ] && [ "$OVERWRITE_HOOKS" = false ]; then
            echo "  ⚠️  ~/.claude/hooks/utils/llm/$llm_file already exists - skipping"
        else
            download_file "${BASE_URL}/claude-code/hooks/utils/llm/${llm_file}" "$HOME/.claude/hooks/utils/llm/${llm_file}"
            if [ -f "$HOME/.claude/hooks/utils/llm/$llm_file" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                echo "  ✓ ~/.claude/hooks/utils/llm/$llm_file (overwritten)"
            else
                echo "  ✓ ~/.claude/hooks/utils/llm/$llm_file"
            fi
        fi
    done
    
    # TTS utilities
    for tts_file in elevenlabs_tts.py gemini_tts.py openai_tts.py pyttsx3_tts.py; do
        if [ -f "$HOME/.claude/hooks/utils/tts/$tts_file" ] && [ "$OVERWRITE_HOOKS" = false ]; then
            echo "  ⚠️  ~/.claude/hooks/utils/tts/$tts_file already exists - skipping"
        else
            download_file "${BASE_URL}/claude-code/hooks/utils/tts/${tts_file}" "$HOME/.claude/hooks/utils/tts/${tts_file}"
            if [ -f "$HOME/.claude/hooks/utils/tts/$tts_file" ] && [ "$OVERWRITE_HOOKS" = true ]; then
                echo "  ✓ ~/.claude/hooks/utils/tts/$tts_file (overwritten)"
            else
                echo "  ✓ ~/.claude/hooks/utils/tts/$tts_file"
            fi
        fi
    done
fi

# Settings configuration
if [ "$UPDATE_SETTINGS" = true ]; then
    echo ""
    echo "🔧 Configuring Claude Code hooks in settings.json"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "  ⚠️  jq is not installed. Please install jq to configure hooks automatically."
        echo "     On macOS: brew install jq"
        echo "     On Ubuntu/Debian: sudo apt-get install jq"
        echo "     On CentOS/RHEL: sudo yum install jq"
        echo ""
        echo "  Manual configuration required: Add the hooks configuration from settings_hooks.json to ~/.claude/settings.json"
    else
        # Get hooks configuration
        if [ "$USE_LOCAL" = true ]; then
            HOOKS_CONFIG_FILE="$SCRIPT_DIR/settings_hooks.json"
        else
            # Download settings_hooks.json to temp file
            HOOKS_CONFIG_FILE="/tmp/claude_hooks_config_$$.json"
            download_file "${BASE_URL}/settings_hooks.json" "$HOOKS_CONFIG_FILE"
        fi
        
        # Check if settings.json exists
        if [ ! -f "$HOME/.claude/settings.json" ]; then
            echo "  Creating new ~/.claude/settings.json with hooks configuration"
            # Create new settings.json with minimal structure and hooks
            echo '{
  "permissions": {
    "allow": []
  },
  "hooks": {}
}' > "$HOME/.claude/settings.json"
        else
            # Backup existing settings
            cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup"
            echo "  ✓ Backed up existing settings to ~/.claude/settings.json.backup"
        fi
        
        # Merge hooks configuration
        jq -s '.[0] * {"hooks": .[1].hooks}' "$HOME/.claude/settings.json" "$HOOKS_CONFIG_FILE" > "$HOME/.claude/settings.json.tmp"
        
        if [ $? -eq 0 ]; then
            mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
            echo "  ✓ Successfully merged hooks configuration into ~/.claude/settings.json"
        else
            echo "  ❌ Failed to merge hooks configuration. Please manually add hooks from settings_hooks.json"
            rm -f "$HOME/.claude/settings.json.tmp"
        fi
        
        # Clean up temp file if used
        if [ "$USE_LOCAL" != true ]; then
            rm -f "$HOOKS_CONFIG_FILE"
        fi
    fi
else
    echo ""
    echo "ℹ️  Settings update skipped (use --update-settings to enable)"
    echo "   To manually configure hooks, see settings_hooks.json for reference"
fi

echo ""
echo "✅ Agent OS Claude Code installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.claude/commands/        - Claude Code commands"
echo "   ~/.claude/agents/          - Claude Code specialized subagents"
echo "   ~/.claude/hooks/           - Claude Code hook scripts and utilities"
if [ "$UPDATE_SETTINGS" = true ]; then
    echo "   ~/.claude/settings.json    - Updated with hooks configuration"
fi
echo ""

# Display preservation notes
PRESERVED_SOMETHING=false
if [ "$OVERWRITE_COMMANDS" = false ] || [ "$OVERWRITE_AGENTS" = false ] || [ "$OVERWRITE_HOOKS" = false ]; then
    echo "💡 Note: Some existing files were preserved:"
    if [ "$OVERWRITE_COMMANDS" = false ]; then
        echo "   - Command files (use --overwrite-commands to update)"
        PRESERVED_SOMETHING=true
    fi
    if [ "$OVERWRITE_AGENTS" = false ]; then
        echo "   - Agent files (use --overwrite-agents to update)"
        PRESERVED_SOMETHING=true
    fi
    if [ "$OVERWRITE_HOOKS" = false ]; then
        echo "   - Hook files (use --overwrite-hooks to update)"
        PRESERVED_SOMETHING=true
    fi
fi

if [ "$UPDATE_SETTINGS" = false ]; then
    if [ "$PRESERVED_SOMETHING" = true ]; then
        echo "   - Settings file (use --update-settings to configure hooks)"
    else
        echo "💡 Note: Settings file was not updated (use --update-settings to configure hooks)"
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
