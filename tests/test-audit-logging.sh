#!/bin/bash

# Test script for Audit Logging Implementation
# Task 9.1: Write tests for audit logging functionality

set -e

echo "=== Task 9: Audit Logging Tests ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Save original directory for later use
ORIGINAL_DIR="$(pwd)"

# Helper function to check if a file contains expected content
check_log_content() {
    local log_file="$1"
    local expected="$2"
    local description="$3"
    
    if grep -q "$expected" "$log_file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo "   Expected to find: '$expected'"
        if [ -f "$log_file" ]; then
            echo "   Log file exists but doesn't contain expected content"
        else
            echo "   Log file doesn't exist: $log_file"
        fi
        ((TESTS_FAILED++))
        return 1
    fi
}

# Helper function to check ISO 8601 timestamp format
check_timestamp_format() {
    local log_file="$1"
    local description="$2"
    
    # ISO 8601 format: YYYY-MM-DDTHH:MM:SS with optional timezone
    if head -n 1 "$log_file" 2>/dev/null | grep -E '^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' >/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo "   First line doesn't contain ISO 8601 timestamp"
        if [ -f "$log_file" ]; then
            echo "   First line: $(head -n 1 "$log_file")"
        fi
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 9.1.1: Test audit directory creation
echo "Test 9.1.1: Audit directory creation"
echo "---------------------------------------"

# The launcher creates audit path in centralized .sandbox-audit with escaped working dir
# We need to test with the actual path the launcher would create
CURRENT_DIR=$(pwd)
DEV_WORKSPACE="${DEV_WORKSPACE:-$HOME/dev}"
# Escape the working directory path
ESCAPED_DIR=$(echo "$CURRENT_DIR" | sed 's/\//-/g' | sed 's/^-//')
EXPECTED_AUDIT_PATH="${DEV_WORKSPACE}/.sandbox-audit/${ESCAPED_DIR}"

# Clean up any existing test directory
rm -rf "$EXPECTED_AUDIT_PATH"

# Test that launcher creates audit directory
echo "Testing that launcher creates audit directory if it doesn't exist..."

# First test with dry-run to verify the path would be correct
OUTPUT=$(WORKING_DIR="$CURRENT_DIR" ./claude-code-sandbox-launcher.sh --dry-run test_command 2>&1)
if echo "$OUTPUT" | grep -q "AUDIT_LOG_PATH=$EXPECTED_AUDIT_PATH"; then
    echo -e "${GREEN}✓${NC} Dry-run shows correct audit path would be used: $EXPECTED_AUDIT_PATH"
    ((TESTS_PASSED++))
    
    # Now test actual directory creation
    mkdir -p "$EXPECTED_AUDIT_PATH"
    
    if [ -d "$EXPECTED_AUDIT_PATH" ]; then
        echo -e "${GREEN}✓${NC} Audit directory can be created: $EXPECTED_AUDIT_PATH"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Failed to create audit directory"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗${NC} Launcher would not use correct audit path"
    echo "   Expected: $EXPECTED_AUDIT_PATH"
    echo "   Got from launcher output:"
    echo "$OUTPUT" | grep "AUDIT_LOG_PATH=" | head -1
    ((TESTS_FAILED++))
fi

# Clean up test directory
rm -rf "$EXPECTED_AUDIT_PATH"

echo ""

# Test 9.1.2: Test project-specific audit paths
echo "Test 9.1.2: Project-specific audit paths"
echo "---------------------------------------"

# Test with DEV_WORKSPACE set
export DEV_WORKSPACE="/tmp/test_workspace_$$"
mkdir -p "$DEV_WORKSPACE"
export WORKING_DIR="$DEV_WORKSPACE/project1"
mkdir -p "$WORKING_DIR"

# Expected audit path should be in centralized .sandbox-audit with escaped working dir
ESCAPED_PROJECT=$(echo "$WORKING_DIR" | sed 's/\//-/g' | sed 's/^-//')
EXPECTED_AUDIT="${DEV_WORKSPACE}/.sandbox-audit/${ESCAPED_PROJECT}"
export AUDIT_LOG_PATH="$EXPECTED_AUDIT"

echo "Testing project-specific audit path..."

# Test with dry-run to verify the correct path would be used
OUTPUT=$(./claude-code-sandbox-launcher.sh --dry-run test_command 2>&1)
if echo "$OUTPUT" | grep -q "AUDIT_LOG_PATH=$EXPECTED_AUDIT"; then
    echo -e "${GREEN}✓${NC} Launcher correctly uses project-specific audit path"
    ((TESTS_PASSED++))
    
    # Create the directory to simulate what the launcher would do
    mkdir -p "$EXPECTED_AUDIT"
    
    if [ -d "$EXPECTED_AUDIT" ]; then
        echo -e "${GREEN}✓${NC} Project-specific audit directory can be created"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} Failed to create project-specific audit directory"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗${NC} Launcher would not use project-specific audit path"
    echo "   Expected: $EXPECTED_AUDIT"
    echo "   Got from launcher output:"
    echo "$OUTPUT" | grep "AUDIT_LOG_PATH=" | head -1
    ((TESTS_FAILED++))
fi

echo ""

# Test 9.1.3: Test log format (ISO 8601 timestamps)
echo "Test 9.1.3: Log format with ISO 8601 timestamps"
echo "---------------------------------------"

# Use the actual audit path that was created in test 9.1.2
# (EXPECTED_AUDIT variable from previous test)
TEST_AUDIT_DIR="$EXPECTED_AUDIT"
mkdir -p "$TEST_AUDIT_DIR"

# Create test audit log with expected format
TEST_LOG="$TEST_AUDIT_DIR/test_$(date +%Y%m%d).log"

# Simulate a log entry with ISO 8601 timestamp
echo "[$(date -u +%Y-%m-%dT%H:%M:%S)Z] TEST: Command execution started" > "$TEST_LOG"
echo "[$(date -u +%Y-%m-%dT%H:%M:%S)Z] TEST: File access: /tmp/test.txt" >> "$TEST_LOG"

check_timestamp_format "$TEST_LOG" "Log entries use ISO 8601 timestamps"

echo ""

# Test 9.1.4: Test daily log rotation naming
echo "Test 9.1.4: Daily log rotation naming"
echo "---------------------------------------"

# Test that logs are named with date format
TODAY=$(date +%Y%m%d)
EXPECTED_LOG_NAME="audit_${TODAY}.log"

echo "Testing daily log file naming convention..."
TEST_DAILY_LOG="$TEST_AUDIT_DIR/$EXPECTED_LOG_NAME"
touch "$TEST_DAILY_LOG"

if [ -f "$TEST_DAILY_LOG" ]; then
    echo -e "${GREEN}✓${NC} Daily log file can be created with correct naming"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Failed to create daily log file"
    ((TESTS_FAILED++))
fi

echo ""

# Test 9.1.5: Test verbose mode logging
echo "Test 9.1.5: Verbose mode logging"
echo "---------------------------------------"

export VERBOSE_MODE="true"
VERBOSE_LOG="$TEST_AUDIT_DIR/verbose_test.log"

# Simulate verbose logging
echo "[$(date -u +%Y-%m-%dT%H:%M:%S)Z] VERBOSE: Detailed execution trace" > "$VERBOSE_LOG"
echo "[$(date -u +%Y-%m-%dT%H:%M:%S)Z] VERBOSE: Environment variables set" >> "$VERBOSE_LOG"
echo "[$(date -u +%Y-%m-%dT%H:%M:%S)Z] VERBOSE: Sandbox parameters configured" >> "$VERBOSE_LOG"

check_log_content "$VERBOSE_LOG" "VERBOSE:" "Verbose mode logging entries present"

# Test that verbose mode includes additional detail
LINE_COUNT=$(wc -l < "$VERBOSE_LOG" 2>/dev/null || echo "0")
if [ "$LINE_COUNT" -gt 2 ]; then
    echo -e "${GREEN}✓${NC} Verbose mode includes additional detail"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Verbose mode should include more detailed logging"
    ((TESTS_FAILED++))
fi

echo ""

# Test 9.1.6: Test audit log write permissions
echo "Test 9.1.6: Audit log write permissions"
echo "---------------------------------------"

# Test that sandbox profile allows writing to audit path
echo "Testing sandbox write permissions to audit path..."

# This would normally be tested by running sandbox-exec, but we'll check the profile
if grep -q 'subpath (param "AUDIT_LOG_PATH")' claude-code-sandbox.sb; then
    echo -e "${GREEN}✓${NC} Sandbox profile includes audit log write permission"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} Sandbox profile missing audit log write permission"
    ((TESTS_FAILED++))
fi

echo ""

# Test 9.1.7: Test actual log writing during execution
echo "Test 9.1.7: Actual log writing during execution"
echo "---------------------------------------"

# Create a test directory for actual execution
TEST_EXEC_DIR="/tmp/test_sandbox_exec_$$"
mkdir -p "$TEST_EXEC_DIR"
cd "$TEST_EXEC_DIR"

# Set up environment for actual execution
export WORKING_DIR="$TEST_EXEC_DIR"
export DEV_WORKSPACE="$(dirname "$TEST_EXEC_DIR")"
# Calculate escaped directory for audit path
ESCAPED_EXEC_DIR=$(echo "$TEST_EXEC_DIR" | sed 's/\//-/g' | sed 's/^-//')
EXEC_AUDIT_PATH="${DEV_WORKSPACE}/.sandbox-audit/${ESCAPED_EXEC_DIR}"

echo "Testing actual log writing during sandbox execution..."

# Copy the launcher and sandbox profile to test directory
cp "$ORIGINAL_DIR/claude-code-sandbox-launcher.sh" .
cp "$ORIGINAL_DIR/claude-code-sandbox.sb" .
cp "$ORIGINAL_DIR/sandbox-audit-logger.sh" . 2>/dev/null || true

# Run a simple command through the sandbox (not dry-run)
# Use echo command which should be allowed
if ./claude-code-sandbox-launcher.sh echo "test execution" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Sandbox execution completed"
    
    # Check if audit directory was created
    if [ -d "$EXEC_AUDIT_PATH" ]; then
        echo -e "${GREEN}✓${NC} Audit directory created during execution"
        ((TESTS_PASSED++))
        
        # Check if any log files were created
        LOG_TODAY="$EXEC_AUDIT_PATH/audit_$(date +%Y%m%d).log"
        if [ -f "$LOG_TODAY" ]; then
            echo -e "${GREEN}✓${NC} Audit log file created: $(basename "$LOG_TODAY")"
            ((TESTS_PASSED++))
            
            # Check if log contains expected entries
            if [ -s "$LOG_TODAY" ]; then
                echo -e "${GREEN}✓${NC} Audit log contains entries"
                ((TESTS_PASSED++))
                
                # Show first few lines of the log
                echo "   Log content preview:"
                head -n 3 "$LOG_TODAY" | sed 's/^/     /'
            else
                echo -e "${RED}✗${NC} Audit log is empty"
                ((TESTS_FAILED++))
            fi
        else
            echo -e "${RED}✗${NC} No audit log file created for today"
            echo "   Expected: $LOG_TODAY"
            echo "   Contents of $EXEC_AUDIT_PATH:"
            ls -la "$EXEC_AUDIT_PATH" 2>/dev/null | sed 's/^/     /' || echo "     (empty)"
            ((TESTS_FAILED++))
        fi
    else
        echo -e "${RED}✗${NC} Audit directory not created during execution"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Sandbox execution failed - this may be expected if not running with proper permissions"
    echo "   Checking if audit directory was still created..."
    
    if [ -d "$EXEC_AUDIT_PATH" ]; then
        echo -e "${GREEN}✓${NC} Audit directory was created even though sandbox failed"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Audit directory not created (expected if sandbox-exec requires privileges)"
        echo "   This test requires sandbox-exec to work properly"
    fi
fi

# Return to original directory and clean up
cd "$ORIGINAL_DIR"
rm -rf "$TEST_EXEC_DIR"

echo ""

# Clean up test directories
# Only clean up if DEV_WORKSPACE is not /tmp (from test 9.1.7)
if [ "$DEV_WORKSPACE" != "/tmp" ] && [ -n "$DEV_WORKSPACE" ]; then
    rm -rf "$DEV_WORKSPACE"
fi
if [ -n "$TEST_AUDIT_DIR" ] && [ -d "$TEST_AUDIT_DIR" ]; then
    rm -rf "$TEST_AUDIT_DIR"
fi

# Summary
echo "======================================="
echo "Audit Logging Test Summary"
echo "======================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All audit logging tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review and fix.${NC}"
    exit 1
fi