#!/bin/bash
# Claude Code Sandbox Launcher Script
# Provides secure sandboxed execution for Claude Code with configurable parameters
# Task 2: Create Launcher Script for Sandbox

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Launch Claude Code in a secure sandbox environment with restricted file system access.

OPTIONS:
    --help          Show this help message
    --dry-run       Show what would be executed without running it
    --verbose       Enable verbose output
    
ENVIRONMENT VARIABLES:
    DEV_WORKSPACE       Development workspace directory (default: \$HOME/dev)
    WORKING_DIR         Current working directory (default: pwd)
    AGENT_OS_DIR        Agent OS directory (default: \$HOME/.agent-os)
    NATS_URL           NATS server URL (default: nats://localhost:4222)
    NATS_CREDS         Path to NATS credentials file (default: none)
    SANDBOX_VERBOSE    Enable verbose logging (true/false, default: false)
    EXTRA_EXEC_PATH    Additional executable path (default: none)
    CCAOS_ENV_FILE     Path to .env file for hooks (default: \$HOME/.config/ccaos/.env)
    SANDBOX_PROFILE    Path to sandbox profile (default: same directory as launcher)
    
EXAMPLES:
    # Run Claude Code with defaults
    $0 claude-code
    
    # Run with custom workspace
    DEV_WORKSPACE=/my/projects $0 claude-code
    
    # Dry run to see what would be executed
    $0 --dry-run claude-code

EOF
}

# Parse command line arguments
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            SANDBOX_VERBOSE=true
            shift
            ;;
        *)
            # Stop processing options and keep remaining args as command
            break
            ;;
    esac
done

# Determine the script's directory early (needed for finding files)
# Resolve symlinks to find the real script location
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    # Get the target of the symlink
    LINK_TARGET="$(readlink "$SCRIPT_PATH")"
    # If the target is relative, resolve it relative to the symlink's directory
    if [[ "$LINK_TARGET" != /* ]]; then
        SCRIPT_PATH="$(dirname "$SCRIPT_PATH")/$LINK_TARGET"
    else
        SCRIPT_PATH="$LINK_TARGET"
    fi
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Task 2.2: Implement environment variable detection and defaults
# Set default values for environment variables if not already set
DEV_WORKSPACE="${DEV_WORKSPACE:-$HOME/dev}"
WORKING_DIR="${WORKING_DIR:-$(pwd)}"
AGENT_OS_DIR="${AGENT_OS_DIR:-$HOME/.agent-os}"
NATS_URL="${NATS_URL:-nats://localhost:4222}"
HOME_DIR="${HOME}"

# Set CCAOS_ENV_FILE with default location
CCAOS_ENV_FILE="${CCAOS_ENV_FILE:-$HOME/.config/ccaos/.env}"

# Ensure the default .env file exists (create if not)
if [ ! -f "$CCAOS_ENV_FILE" ]; then
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$CCAOS_ENV_FILE")"
    # Create empty .env file
    touch "$CCAOS_ENV_FILE"
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${YELLOW}Created default .env file:${NC} $CCAOS_ENV_FILE"
    fi
fi

# Export CCAOS_ENV_FILE so it's available to child processes
export CCAOS_ENV_FILE

# Optional parameters (only used if defined)
NATS_CREDS="${NATS_CREDS:-}"
EXTRA_EXEC_PATH="${EXTRA_EXEC_PATH:-}"

# Verbose mode from environment
if [ "$SANDBOX_VERBOSE" = "true" ]; then
    VERBOSE=true
    VERBOSE_MODE="true"
else
    VERBOSE_MODE="false"
fi

# Task 9.2: Implement project-specific audit directories
# Create audit logs in centralized .sandbox-audit with project-specific subdirectories
# Escape the working directory path by replacing / with - to create unique identifier
ESCAPED_WORKING_DIR=$(echo "$WORKING_DIR" | sed 's/\//-/g' | sed 's/^-//')
AUDIT_LOG_PATH="${DEV_WORKSPACE}/.sandbox-audit/${ESCAPED_WORKING_DIR}"
echo "-----"

# Task 2.5: Add audit directory creation if not exists
# Create audit directory if it doesn't exist
if [ "$DRY_RUN" = "false" ]; then
    mkdir -p "$AUDIT_LOG_PATH"
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${GREEN}✓${NC} Created audit directory: $AUDIT_LOG_PATH"
    fi
    
    # Task 9.5: Implement verbose mode logging when enabled
    # Initialize audit logging (SCRIPT_DIR already determined above)
    AUDIT_LOGGER="${SCRIPT_DIR}/sandbox-audit-logger.sh"
    
    if [ -f "$AUDIT_LOGGER" ]; then
        # Source the audit logger to get logging functions
        export AUDIT_LOG_PATH VERBOSE_MODE WORKING_DIR DEV_WORKSPACE
        source "$AUDIT_LOGGER"
        
        # Log sandbox initialization
        log_info "Sandbox launcher initialized"
        log_verbose "Configuration: DEV_WORKSPACE=$DEV_WORKSPACE"
        log_verbose "Configuration: WORKING_DIR=$WORKING_DIR"
        log_verbose "Configuration: AGENT_OS_DIR=$AGENT_OS_DIR"
        log_verbose "Configuration: AUDIT_LOG_PATH=$AUDIT_LOG_PATH"
        
        if [ -n "$NATS_CREDS" ]; then
            log_verbose "Configuration: NATS_CREDS configured"
        fi
        
        if [ -n "$EXTRA_EXEC_PATH" ]; then
            log_verbose "Configuration: EXTRA_EXEC_PATH=$EXTRA_EXEC_PATH"
        fi
    fi
else
    echo "Would execute: mkdir -p $AUDIT_LOG_PATH"
fi

# Find the sandbox profile - use environment variable or default to script directory
SANDBOX_PROFILE="${SANDBOX_PROFILE:-${SCRIPT_DIR}/claude-code-sandbox.sb}"

# Check if sandbox profile exists
if [ ! -f "$SANDBOX_PROFILE" ]; then
    # In dry-run mode, just warn but continue
    if [ "$DRY_RUN" = "true" ]; then
        echo -e "${YELLOW}Warning:${NC} Cannot find sandbox profile at $SANDBOX_PROFILE" >&2
        SANDBOX_PROFILE="claude-code-sandbox.sb"  # Use placeholder for dry-run
    else
        echo -e "${RED}Error:${NC} Cannot find sandbox profile at $SANDBOX_PROFILE"
        echo "The sandbox profile should be in the same directory as this launcher script"
        echo "Expected location: $SANDBOX_PROFILE"
        exit 1
    fi
fi

# Task 2.4: Implement parameter passing to sandbox-exec
# Build sandbox-exec command arguments as an array for direct execution
SANDBOX_ARGS=()
SANDBOX_ARGS+=("-D" "DEV_WORKSPACE=$DEV_WORKSPACE")
SANDBOX_ARGS+=("-D" "WORKING_DIR=$WORKING_DIR")
SANDBOX_ARGS+=("-D" "AGENT_OS_DIR=$AGENT_OS_DIR")
SANDBOX_ARGS+=("-D" "AUDIT_LOG_PATH=$AUDIT_LOG_PATH")
SANDBOX_ARGS+=("-D" "HOME=$HOME_DIR")
SANDBOX_ARGS+=("-D" "NATS_URL=$NATS_URL")
SANDBOX_ARGS+=("-D" "VERBOSE_MODE=$VERBOSE_MODE")
SANDBOX_ARGS+=("-D" "CCAOS_ENV_FILE=$CCAOS_ENV_FILE")

# Add optional parameters only if defined
if [ -n "$NATS_CREDS" ]; then
    SANDBOX_ARGS+=("-D" "NATS_CREDS=$NATS_CREDS")
fi

if [ -n "$EXTRA_EXEC_PATH" ]; then
    SANDBOX_ARGS+=("-D" "EXTRA_EXEC_PATH=$EXTRA_EXEC_PATH")
fi

SANDBOX_ARGS+=("-f" "$SANDBOX_PROFILE")

# Add the command to execute
if [ $# -gt 0 ]; then
    # Pass remaining arguments directly as they were provided
    # This preserves the command structure (e.g., bash -c "complex command")
    SANDBOX_ARGS+=("$@")
else
    # Default to claude-code if no command specified
    SANDBOX_ARGS+=("claude-code")
fi

# Display configuration if verbose
if [ "$VERBOSE" = "true" ]; then
    echo -e "${YELLOW}Sandbox Configuration:${NC}"
    echo "  DEV_WORKSPACE: $DEV_WORKSPACE"
    echo "  WORKING_DIR: $WORKING_DIR"
    echo "  AGENT_OS_DIR: $AGENT_OS_DIR"
    echo "  AUDIT_LOG_PATH: $AUDIT_LOG_PATH"
    echo "  NATS_URL: $NATS_URL"
    if [ -n "$NATS_CREDS" ]; then
        echo "  NATS_CREDS: $NATS_CREDS"
    fi
    if [ -n "$EXTRA_EXEC_PATH" ]; then
        echo "  EXTRA_EXEC_PATH: $EXTRA_EXEC_PATH"
    fi
    echo "  VERBOSE_MODE: $VERBOSE_MODE"
    echo "  SANDBOX_PROFILE: $SANDBOX_PROFILE"
    echo ""
fi

# Execute or show dry run
if [ "$DRY_RUN" = "true" ]; then
    echo "<<<<<< "
    echo "Would execute:"
    echo "sandbox-exec ${SANDBOX_ARGS[@]}"
    
    # Output test-friendly format for assertions
    echo ""
    echo "Parameters:"
    echo "DEV_WORKSPACE=$DEV_WORKSPACE"
    echo "WORKING_DIR=$WORKING_DIR"
    echo "AGENT_OS_DIR=$AGENT_OS_DIR"
    echo "AUDIT_LOG_PATH=$AUDIT_LOG_PATH"
    echo "HOME=$HOME_DIR"
    echo "NATS_URL=$NATS_URL"
    echo "VERBOSE_MODE=$VERBOSE_MODE"
    
    # Show command construction for tests
    echo ""
    echo "Command parts:"
    echo "-D DEV_WORKSPACE=$DEV_WORKSPACE"
    echo "-D WORKING_DIR=$WORKING_DIR"
    echo "-D AGENT_OS_DIR=$AGENT_OS_DIR"
    echo "-D AUDIT_LOG_PATH=$AUDIT_LOG_PATH"
    echo "-D HOME=$HOME_DIR"
    echo "claude-code-sandbox.sb"
    
    if [ "$VERBOSE_MODE" = "true" ]; then
        echo "VERBOSE_MODE=true"
    fi
else
    echo ">>>>> "
    if [ "$VERBOSE" = "true" ]; then
        echo -e "${GREEN}Executing:${NC}"
        echo "sandbox-exec ${SANDBOX_ARGS[@]}"
        echo ""
    fi
    
    # Task 9.5: Log sandbox execution
    if [ -f "$AUDIT_LOGGER" ] && command -v log_info >/dev/null 2>&1; then
        log_info "Executing sandbox command"
        log_verbose "Full command: sandbox-exec ${SANDBOX_ARGS[*]}"
    fi
    
    # Execute sandbox-exec directly with the arguments array
    sandbox-exec "${SANDBOX_ARGS[@]}"
    EXIT_CODE=$?
    
    # Log exit status
    if [ -f "$AUDIT_LOGGER" ] && command -v log_info >/dev/null 2>&1; then
        log_info "Sandbox execution completed with exit code: $EXIT_CODE"
    fi
    
    exit $EXIT_CODE
fi
