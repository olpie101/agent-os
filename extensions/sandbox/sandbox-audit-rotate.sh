#!/bin/bash
# Sandbox Audit Log Rotation Script
# Task 9.4: Create log rotation script for daily rotation
# This script manages daily rotation and cleanup of audit logs

set -e

# Configuration
AUDIT_BASE_PATH="${AUDIT_LOG_PATH:-${WORKING_DIR}/.audit/claude-code}"
RETENTION_DAYS="${AUDIT_RETENTION_DAYS:-30}"  # Keep logs for 30 days by default
COMPRESS_AFTER_DAYS="${AUDIT_COMPRESS_AFTER:-7}"  # Compress logs older than 7 days

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log rotation events
log_rotation() {
    local message="$1"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%S)Z
    echo "[$timestamp] ROTATION: $message"
}

# Function to rotate logs
rotate_logs() {
    local audit_dir="$1"
    
    if [ ! -d "$audit_dir" ]; then
        log_rotation "Audit directory does not exist: $audit_dir"
        return 1
    fi
    
    log_rotation "Starting log rotation in $audit_dir"
    
    # Get current date for comparison
    local current_date=$(date +%Y%m%d)
    local current_timestamp=$(date +%s)
    
    # Process all audit log files
    for log_file in "$audit_dir"/audit_*.log; do
        # Skip if no files match
        [ -e "$log_file" ] || continue
        
        # Extract date from filename (audit_YYYYMMDD.log)
        local filename=$(basename "$log_file")
        local file_date=$(echo "$filename" | sed 's/audit_\([0-9]\{8\}\)\.log/\1/')
        
        # Skip if not a valid audit log file
        if ! echo "$file_date" | grep -E '^[0-9]{8}$' >/dev/null; then
            continue
        fi
        
        # Convert file date to timestamp for age calculation
        local file_year="${file_date:0:4}"
        local file_month="${file_date:4:2}"
        local file_day="${file_date:6:2}"
        local file_timestamp=$(date -j -f "%Y-%m-%d" "${file_year}-${file_month}-${file_day}" +%s 2>/dev/null || echo 0)
        
        if [ "$file_timestamp" -eq 0 ]; then
            log_rotation "Warning: Could not parse date for $filename"
            continue
        fi
        
        # Calculate age in days
        local age_seconds=$((current_timestamp - file_timestamp))
        local age_days=$((age_seconds / 86400))
        
        # Delete logs older than retention period
        if [ "$age_days" -gt "$RETENTION_DAYS" ]; then
            log_rotation "Deleting old log: $filename (${age_days} days old)"
            rm -f "$log_file"
            # Also remove compressed version if it exists
            rm -f "${log_file}.gz"
            continue
        fi
        
        # Compress logs older than compression threshold
        if [ "$age_days" -gt "$COMPRESS_AFTER_DAYS" ] && [ ! -f "${log_file}.gz" ]; then
            log_rotation "Compressing log: $filename (${age_days} days old)"
            gzip -9 "$log_file"
        fi
    done
    
    # Clean up empty audit directories (but keep the main one)
    find "$audit_dir" -type d -empty -mindepth 1 -delete 2>/dev/null || true
    
    log_rotation "Log rotation completed"
}

# Function to generate rotation report
generate_report() {
    local audit_dir="$1"
    
    echo "=== Audit Log Rotation Report ==="
    echo "Directory: $audit_dir"
    echo "Retention: $RETENTION_DAYS days"
    echo "Compress after: $COMPRESS_AFTER_DAYS days"
    echo ""
    
    if [ ! -d "$audit_dir" ]; then
        echo "Audit directory does not exist"
        return
    fi
    
    # Count log files by status
    local current_logs=$(ls -1 "$audit_dir"/audit_*.log 2>/dev/null | wc -l | tr -d ' ')
    local compressed_logs=$(ls -1 "$audit_dir"/audit_*.log.gz 2>/dev/null | wc -l | tr -d ' ')
    local total_size=$(du -sh "$audit_dir" 2>/dev/null | cut -f1)
    
    echo "Current logs: $current_logs"
    echo "Compressed logs: $compressed_logs"
    echo "Total size: ${total_size:-0}"
    echo ""
    
    # List recent logs
    echo "Recent logs (last 7 days):"
    local seven_days_ago=$(date -v-7d +%Y%m%d 2>/dev/null || date -d '7 days ago' +%Y%m%d)
    
    for log_file in "$audit_dir"/audit_*.log "$audit_dir"/audit_*.log.gz; do
        [ -e "$log_file" ] || continue
        
        local filename=$(basename "$log_file")
        local file_date=$(echo "$filename" | sed 's/audit_\([0-9]\{8\}\).*/\1/')
        
        if [ "$file_date" -ge "$seven_days_ago" ] 2>/dev/null; then
            local size=$(ls -lh "$log_file" | awk '{print $5}')
            echo "  - $filename ($size)"
        fi
    done
}

# Function to setup automatic rotation (cron job)
setup_cron() {
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    local cron_entry="0 0 * * * $script_path --rotate $AUDIT_BASE_PATH"
    
    echo "Setting up daily rotation cron job..."
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        echo -e "${YELLOW}Cron job already exists${NC}"
    else
        # Add new cron job
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        echo -e "${GREEN}✓${NC} Cron job added for daily rotation at midnight"
    fi
    
    echo "Current crontab:"
    crontab -l | grep "$script_path" || echo "  (no rotation jobs found)"
}

# Parse command line arguments
case "${1:-}" in
    --rotate)
        # Perform rotation on specified directory or default
        AUDIT_DIR="${2:-$AUDIT_BASE_PATH}"
        rotate_logs "$AUDIT_DIR"
        ;;
    --report)
        # Generate report for specified directory or default
        AUDIT_DIR="${2:-$AUDIT_BASE_PATH}"
        generate_report "$AUDIT_DIR"
        ;;
    --setup-cron)
        # Setup automatic rotation via cron
        setup_cron
        ;;
    --help)
        cat << EOF
Usage: $0 [OPTION] [DIRECTORY]

Manage rotation and cleanup of sandbox audit logs.

OPTIONS:
    --rotate [DIR]      Rotate logs in specified directory
    --report [DIR]      Generate report for audit logs
    --setup-cron        Setup daily rotation cron job
    --help              Show this help message

ENVIRONMENT:
    AUDIT_LOG_PATH          Base audit log directory
    AUDIT_RETENTION_DAYS    Days to retain logs (default: 30)
    AUDIT_COMPRESS_AFTER    Days before compression (default: 7)

EXAMPLES:
    # Rotate logs in default location
    $0 --rotate

    # Generate report for specific project
    $0 --report /path/to/project/.audit/claude-code

    # Setup automatic daily rotation
    $0 --setup-cron

EOF
        ;;
    *)
        # Default action: rotate logs in all project audit directories
        if [ -n "${DEV_WORKSPACE:-}" ] && [ -d "$DEV_WORKSPACE" ]; then
            echo "Scanning for audit directories in $DEV_WORKSPACE..."
            
            # Find all .audit/claude-code directories
            find "$DEV_WORKSPACE" -type d -path "*/.audit/claude-code" 2>/dev/null | while read -r audit_dir; do
                echo ""
                echo "Processing: $audit_dir"
                rotate_logs "$audit_dir"
            done
        else
            echo "No DEV_WORKSPACE set or directory not found"
            echo "Use --help for usage information"
            exit 1
        fi
        ;;
esac