#!/bin/bash

# Agent OS Setup Script
# This script installs Agent OS files to your system

set -e  # Exit on error

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
OVERWRITE_STANDARDS=false
OVERWRITE_SCRIPTS=false
USE_LOCAL=false
CUSTOM_BASE_URL=""

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
        --overwrite-scripts)
            OVERWRITE_SCRIPTS=true
            shift
            ;;
        --local)
            USE_LOCAL=true
            shift
            ;;
        --base-url)
            CUSTOM_BASE_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --overwrite-instructions    Overwrite existing instruction files"
            echo "  --overwrite-standards       Overwrite existing standards files"
            echo "  --overwrite-scripts         Overwrite existing PEER scripts"
            echo "  --local                     Use local repository files instead of GitHub"
            echo "  --base-url URL              Use custom base URL for downloading files"
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

echo "🚀 Agent OS Setup Script"
echo "========================"
echo ""

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
mkdir -p "$HOME/.agent-os/standards"
mkdir -p "$HOME/.agent-os/standards/code-style"
mkdir -p "$HOME/.agent-os/instructions"
mkdir -p "$HOME/.agent-os/instructions/core"
mkdir -p "$HOME/.agent-os/instructions/meta"
mkdir -p "$HOME/.agent-os/scripts/peer"

# Download standards files
echo ""
echo "📥 Downloading standards files to ~/.agent-os/standards/"

# tech-stack.md
if [ -f "$HOME/.agent-os/standards/tech-stack.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/tech-stack.md already exists - skipping"
else
    download_file "$HOME/.agent-os/standards/tech-stack.md" "${BASE_URL}/standards/tech-stack.md"
    if [ -f "$HOME/.agent-os/standards/tech-stack.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/tech-stack.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/tech-stack.md"
    fi
fi

# code-style.md
if [ -f "$HOME/.agent-os/standards/code-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/code-style.md already exists - skipping"
else
    download_file "${BASE_URL}/standards/code-style.md" "$HOME/.agent-os/standards/code-style.md"
    if [ -f "$HOME/.agent-os/standards/code-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/code-style.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/code-style.md"
    fi
fi

# best-practices.md
if [ -f "$HOME/.agent-os/standards/best-practices.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/best-practices.md already exists - skipping"
else
    download_file "${BASE_URL}/standards/best-practices.md" "$HOME/.agent-os/standards/best-practices.md"
    if [ -f "$HOME/.agent-os/standards/best-practices.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/best-practices.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/best-practices.md"
    fi
fi

# Download code-style subdirectory files
echo ""
echo "📥 Downloading code style files to ~/.agent-os/standards/code-style/"

# css-style.md
if [ -f "$HOME/.agent-os/standards/code-style/css-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/code-style/css-style.md already exists - skipping"
else
    download_file "${BASE_URL}/standards/code-style/css-style.md" "$HOME/.agent-os/standards/code-style/css-style.md"
    if [ -f "$HOME/.agent-os/standards/code-style/css-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/code-style/css-style.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/code-style/css-style.md"
    fi
fi

# html-style.md
if [ -f "$HOME/.agent-os/standards/code-style/html-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/code-style/html-style.md already exists - skipping"
else
    download_file "${BASE_URL}/standards/code-style/html-style.md" "$HOME/.agent-os/standards/code-style/html-style.md"
    if [ -f "$HOME/.agent-os/standards/code-style/html-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/code-style/html-style.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/code-style/html-style.md"
    fi
fi

# javascript-style.md
if [ -f "$HOME/.agent-os/standards/code-style/javascript-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/code-style/javascript-style.md already exists - skipping"
else
    download_file "${BASE_URL}/standards/code-style/javascript-style.md" "$HOME/.agent-os/standards/code-style/javascript-style.md"
    if [ -f "$HOME/.agent-os/standards/code-style/javascript-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/code-style/javascript-style.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/code-style/javascript-style.md"
    fi
fi

# Download instruction files
echo ""
echo "📥 Downloading instruction files to ~/.agent-os/instructions/"

# Core instruction files
echo "  📂 Core instructions:"

# plan-product.md
if [ -f "$HOME/.agent-os/instructions/core/plan-product.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/plan-product.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/plan-product.md" "$HOME/.agent-os/instructions/core/plan-product.md"
    if [ -f "$HOME/.agent-os/instructions/core/plan-product.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/plan-product.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/plan-product.md"
    fi
fi

# create-spec.md
if [ -f "$HOME/.agent-os/instructions/core/create-spec.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
  echo "    ⚠️  ~/.agent-os/instructions/core/create-spec.md already exists - skipping"
else
  download_file "${BASE_URL}/instructions/core/create-spec.md" "$HOME/.agent-os/instructions/core/create-spec.md"
  if [ -f "$HOME/.agent-os/instructions/core/create-spec.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
    echo "    ✓ ~/.agent-os/instructions/core/create-spec.md (overwritten)"
  else
    echo "    ✓ ~/.agent-os/instructions/core/create-spec.md"
  fi
fi

# execute-tasks.md
if [ -f "$HOME/.agent-os/instructions/core/execute-tasks.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/execute-tasks.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/execute-tasks.md" "$HOME/.agent-os/instructions/core/execute-tasks.md"
    if [ -f "$HOME/.agent-os/instructions/core/execute-tasks.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/execute-tasks.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/execute-tasks.md"
    fi
fi

# execute-task.md
if [ -f "$HOME/.agent-os/instructions/core/execute-task.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/execute-task.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/execute-task.md" "$HOME/.agent-os/instructions/core/execute-task.md"
    if [ -f "$HOME/.agent-os/instructions/core/execute-task.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/execute-task.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/execute-task.md"
    fi
fi

# analyze-product.md
if [ -f "$HOME/.agent-os/instructions/core/analyze-product.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/analyze-product.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/analyze-product.md" "$HOME/.agent-os/instructions/core/analyze-product.md"
    if [ -f "$HOME/.agent-os/instructions/core/analyze-product.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/analyze-product.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/analyze-product.md"
    fi
fi

# peer.md
if [ -f "$HOME/.agent-os/instructions/core/peer.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/peer.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/peer.md" "$HOME/.agent-os/instructions/core/peer.md"
    if [ -f "$HOME/.agent-os/instructions/core/peer.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/peer.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/peer.md"
    fi
fi

# git-commit.md
if [ -f "$HOME/.agent-os/instructions/core/git-commit.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/git-commit.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/git-commit.md" "$HOME/.agent-os/instructions/core/git-commit.md"
    if [ -f "$HOME/.agent-os/instructions/core/git-commit.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/git-commit.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/git-commit.md"
    fi
fi

# refine-spec.md
if [ -f "$HOME/.agent-os/instructions/core/refine-spec.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/refine-spec.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/core/refine-spec.md" "$HOME/.agent-os/instructions/core/refine-spec.md"
    if [ -f "$HOME/.agent-os/instructions/core/refine-spec.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/refine-spec.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/refine-spec.md"
    fi
fi

# Meta instruction files
echo ""
echo "  📂 Meta instructions:"

# pre-flight.md
if [ -f "$HOME/.agent-os/instructions/meta/pre-flight.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/meta/pre-flight.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/meta/pre-flight.md" "$HOME/.agent-os/instructions/meta/pre-flight.md"
    if [ -f "$HOME/.agent-os/instructions/meta/pre-flight.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/meta/pre-flight.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/meta/pre-flight.md"
    fi
fi

# unified_state_schema.md
if [ -f "$HOME/.agent-os/instructions/meta/unified_state_schema.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/meta/unified_state_schema.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/meta/unified_state_schema.md" "$HOME/.agent-os/instructions/meta/unified_state_schema.md"
    if [ -f "$HOME/.agent-os/instructions/meta/unified_state_schema.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/meta/unified_state_schema.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/meta/unified_state_schema.md"
    fi
fi

# nats-kv-operations.md
if [ -f "$HOME/.agent-os/instructions/meta/nats-kv-operations.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/meta/nats-kv-operations.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/meta/nats-kv-operations.md" "$HOME/.agent-os/instructions/meta/nats-kv-operations.md"
    if [ -f "$HOME/.agent-os/instructions/meta/nats-kv-operations.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/meta/nats-kv-operations.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/meta/nats-kv-operations.md"
    fi
fi

# json-creation-standards.md
if [ -f "$HOME/.agent-os/instructions/meta/json-creation-standards.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/meta/json-creation-standards.md already exists - skipping"
else
    download_file "${BASE_URL}/instructions/meta/json-creation-standards.md" "$HOME/.agent-os/instructions/meta/json-creation-standards.md"
    if [ -f "$HOME/.agent-os/instructions/meta/json-creation-standards.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/meta/json-creation-standards.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/meta/json-creation-standards.md"
    fi
fi

# PEER Pattern Scripts
echo ""
echo "📥 Downloading PEER pattern scripts to ~/.agent-os/scripts/peer/"

# read-state.sh
if [ -f "$HOME/.agent-os/scripts/peer/read-state.sh" ] && [ "$OVERWRITE_SCRIPTS" = false ]; then
    echo "  ⚠️  ~/.agent-os/scripts/peer/read-state.sh already exists - skipping"
else
    download_file "${BASE_URL}/scripts/peer/read-state.sh" "$HOME/.agent-os/scripts/peer/read-state.sh"
    if [ -f "$HOME/.agent-os/scripts/peer/read-state.sh" ] && [ "$OVERWRITE_SCRIPTS" = true ]; then
        echo "  ✓ ~/.agent-os/scripts/peer/read-state.sh (overwritten)"
    else
        echo "  ✓ ~/.agent-os/scripts/peer/read-state.sh"
    fi
fi

# update-state.sh
if [ -f "$HOME/.agent-os/scripts/peer/update-state.sh" ] && [ "$OVERWRITE_SCRIPTS" = false ]; then
    echo "  ⚠️  ~/.agent-os/scripts/peer/update-state.sh already exists - skipping"
else
    download_file "${BASE_URL}/scripts/peer/update-state.sh" "$HOME/.agent-os/scripts/peer/update-state.sh"
    if [ -f "$HOME/.agent-os/scripts/peer/update-state.sh" ] && [ "$OVERWRITE_SCRIPTS" = true ]; then
        echo "  ✓ ~/.agent-os/scripts/peer/update-state.sh (overwritten)"
    else
        echo "  ✓ ~/.agent-os/scripts/peer/update-state.sh"
    fi
fi

# create-state.sh
if [ -f "$HOME/.agent-os/scripts/peer/create-state.sh" ] && [ "$OVERWRITE_SCRIPTS" = false ]; then
    echo "  ⚠️  ~/.agent-os/scripts/peer/create-state.sh already exists - skipping"
else
    download_file "${BASE_URL}/scripts/peer/create-state.sh" "$HOME/.agent-os/scripts/peer/create-state.sh"
    if [ -f "$HOME/.agent-os/scripts/peer/create-state.sh" ] && [ "$OVERWRITE_SCRIPTS" = true ]; then
        echo "  ✓ ~/.agent-os/scripts/peer/create-state.sh (overwritten)"
    else
        echo "  ✓ ~/.agent-os/scripts/peer/create-state.sh"
    fi
fi

# Make scripts executable
echo ""
echo "🔧 Making PEER scripts executable..."
chmod +x "$HOME/.agent-os/scripts/peer/read-state.sh" 2>/dev/null && echo "  ✓ read-state.sh" || true
chmod +x "$HOME/.agent-os/scripts/peer/update-state.sh" 2>/dev/null && echo "  ✓ update-state.sh" || true
chmod +x "$HOME/.agent-os/scripts/peer/create-state.sh" 2>/dev/null && echo "  ✓ create-state.sh" || true

echo ""
echo "✅ Agent OS base installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.agent-os/standards/     - Your development standards"
echo "   ~/.agent-os/instructions/  - Agent OS instructions"
echo "   ~/.agent-os/scripts/       - PEER pattern wrapper scripts"
echo ""
if [ "$OVERWRITE_INSTRUCTIONS" = false ] && [ "$OVERWRITE_STANDARDS" = false ] && [ "$OVERWRITE_SCRIPTS" = false ]; then
    echo "💡 Note: Existing files were skipped to preserve your customizations"
    echo "   Use --overwrite-instructions, --overwrite-standards, or --overwrite-scripts to update specific files"
else
    echo "💡 Note: Some files were overwritten based on your flags"
    if [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
        echo "   Existing instruction files were preserved"
    fi
    if [ "$OVERWRITE_STANDARDS" = false ]; then
        echo "   Existing standards files were preserved"
    fi
    if [ "$OVERWRITE_SCRIPTS" = false ]; then
        echo "   Existing PEER scripts were preserved"
    fi
fi
echo ""
echo "Next steps:"
echo ""
echo "1. Customize your coding standards in ~/.agent-os/standards/"
echo ""
echo "2. Install commands for your AI coding assistant(s):"
echo ""
echo "   - Using Claude Code? Install the Claude Code commands with:"
echo "     curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/setup-claude-code.sh | bash"
echo ""
echo "   - Using Cursor? Install the Cursor commands with:"
echo "     curl -sSL https://raw.githubusercontent.com/buildermethods/agent-os/main/setup-cursor.sh | bash"
echo ""
echo "   - Using something else? See instructions at https://buildermethods.com/agent-os"
echo ""
echo "Learn more at https://buildermethods.com/agent-os"
echo ""
