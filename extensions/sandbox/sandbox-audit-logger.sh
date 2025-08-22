#!/bin/bash
# Sandbox Audit Logger
# Task 9.3: Configure audit log format (ISO 8601 timestamps)
# This script handles audit logging with proper timestamp formatting

# Get the audit log path from environment or use default
AUDIT_LOG_PATH="${AUDIT_LOG_PATH:-${WORKING_DIR}/.audit/claude-code}"
VERBOSE_MODE="${VERBOSE_MODE:-false}"

# Ensure audit directory exists
mkdir -p "$AUDIT_LOG_PATH"

# Generate log filename with date for daily rotation
LOG_DATE=$(date +%Y%m%d)
LOG_FILE="${AUDIT_LOG_PATH}/audit_${LOG_DATE}.log"

# Function to log with ISO 8601 timestamp
log_entry() {
    local level="$1"
    shift
    local message="$*"
    
    # ISO 8601 timestamp with timezone
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S)Z
    
    # Write to log file
    echo "[$timestamp] $level: $message" >> "$LOG_FILE"
    
    # If verbose mode is enabled, also output to stderr
    if [ "$VERBOSE_MODE" = "true" ]; then
        echo "[$timestamp] $level: $message" >&2
    fi
}

# Function to log verbose messages (only logged if verbose mode is on)
log_verbose() {
    if [ "$VERBOSE_MODE" = "true" ]; then
        log_entry "VERBOSE" "$@"
    fi
}

# Function to log informational messages
log_info() {
    log_entry "INFO" "$@"
}

# Function to log warning messages
log_warning() {
    log_entry "WARNING" "$@"
}

# Function to log error messages
log_error() {
    log_entry "ERROR" "$@"
}

# Function to log file access attempts
log_file_access() {
    local access_type="$1"  # READ, WRITE, EXECUTE
    local file_path="$2"
    local result="$3"       # ALLOWED, DENIED
    
    log_entry "FILE_ACCESS" "$access_type $file_path - $result"
}

# Function to log network access attempts
log_network_access() {
    local protocol="$1"     # TCP, UDP
    local destination="$2"  # host:port
    local result="$3"       # ALLOWED, DENIED
    
    log_entry "NETWORK" "$protocol $destination - $result"
}

# Function to log process execution
log_process_exec() {
    local command="$1"
    local result="$2"       # ALLOWED, DENIED
    
    log_entry "PROCESS_EXEC" "$command - $result"
}

# Start logging session
log_info "Sandbox audit logging session started"
log_info "Working directory: $WORKING_DIR"
log_info "Development workspace: $DEV_WORKSPACE"
log_info "Audit log path: $AUDIT_LOG_PATH"
log_verbose "Verbose mode enabled: $VERBOSE_MODE"
log_verbose "Environment variables configured"
log_verbose "Sandbox parameters initialized"

# Export functions for use in other scripts
export -f log_entry
export -f log_verbose
export -f log_info
export -f log_warning
export -f log_error
export -f log_file_access
export -f log_network_access
export -f log_process_exec

# If called directly (not sourced) with arguments, log and execute them
# Check if script is being sourced or executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly, not sourced
    if [ $# -gt 0 ]; then
        log_info "Command execution: $*"
        exec "$@"
    fi
fi