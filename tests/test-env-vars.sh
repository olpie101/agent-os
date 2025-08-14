#!/bin/bash
# Test suite for Task 3: Environment Variable and Parameter Implementation
# Task 3.1: Write tests for DEV_WORKSPACE parameter handling

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -n "Testing $test_name... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_function 2>/dev/null; then
        echo -e "${GREEN}✅ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  Error: $($test_function 2>&1)" >&2
    fi
}

# Test functions for environment variable handling

test_dev_workspace_read_permission() {
    # Test that DEV_WORKSPACE is used for read permissions instead of HOME
    # This will test that we can read from DEV_WORKSPACE
    local test_file="/tmp/test_dev_workspace_$$"
    
    # Create a test script that tries to read from DEV_WORKSPACE
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Try to list files in DEV_WORKSPACE using /bin/ls explicitly
/bin/ls "$DEV_WORKSPACE" > /dev/null 2>&1
EOF
    chmod +x "$test_file"
    
    # Run with sandbox
    DEV_WORKSPACE="$HOME/dev" sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

test_working_dir_parameter() {
    # Test that WORKING_DIR parameter is properly passed
    local test_file="/tmp/test_working_dir_$$"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Try to write to WORKING_DIR using explicit /bin paths
echo "test" > test_file_$$.txt
/bin/rm -f test_file_$$.txt
EOF
    chmod +x "$test_file"
    
    # Run with sandbox
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

test_agent_os_dir_parameter() {
    # Test that AGENT_OS_DIR parameter works
    # This should allow reading from ~/.agent-os
    local test_file="/tmp/test_agent_os_$$"
    
    # Only test if .agent-os directory exists
    if [ ! -d "$HOME/.agent-os" ]; then
        mkdir -p "$HOME/.agent-os"
        local created_dir=true
    fi
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Try to check if AGENT_OS_DIR exists
[ -d "$HOME/.agent-os" ]
EOF
    chmod +x "$test_file"
    
    # Run with sandbox
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    
    # Clean up if we created the directory
    if [ "$created_dir" = "true" ]; then
        rmdir "$HOME/.agent-os" 2>/dev/null || true
    fi
    
    return $result
}

test_nats_url_parameter() {
    # Test that NATS_URL parameter can be set
    # This is mainly a parameter passing test
    local test_file="/tmp/test_nats_url_$$"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Just verify the script runs (network access will be tested separately)
echo "NATS parameter test"
EOF
    chmod +x "$test_file"
    
    # Run with custom NATS_URL
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -D NATS_URL="nats://localhost:4222" \
        -f claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

# test_extra_exec_path_optional removed - cannot be implemented
# sandbox-exec doesn't support truly optional parameters

test_audit_log_path_writable() {
    # Test that AUDIT_LOG_PATH is writable
    local test_file="/tmp/test_audit_log_$$"
    local audit_dir="/tmp/test_audit_$$"
    
    mkdir -p "$audit_dir"
    
    cat > "$test_file" << EOF
#!/bin/bash
# Try to write to audit log path
echo "audit test" > "$audit_dir/test.log"
[ -f "$audit_dir/test.log" ]
EOF
    chmod +x "$test_file"
    
    # Run with custom audit path
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="$audit_dir" \
        -D HOME="$HOME" \
        -f claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -rf "$audit_dir"
    rm -f "$test_file"
    return $result
}

# Main test execution
echo "========================================="
echo "Environment Variable and Parameter Tests"
echo "========================================="
echo ""

# First verify the sandbox profile exists
if [ ! -f "claude-code-sandbox.sb" ]; then
    echo -e "${RED}Error: claude-code-sandbox.sb not found${NC}"
    exit 1
fi

# Run pre-task validation as required by spec
echo "Running pre-task validation..."
if ! sandbox-exec \
    -D DEV_WORKSPACE="$HOME/dev" \
    -D WORKING_DIR="$(pwd)" \
    -D AGENT_OS_DIR="$HOME/.agent-os" \
    -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
    -D HOME="$HOME" \
    -f claude-code-sandbox.sb \
    /bin/bash -c "echo 'Pre-task validation OK'"; then
    echo -e "${RED}Pre-task validation failed! Cannot proceed with tests.${NC}"
    exit 1
fi
echo -e "${GREEN}Pre-task validation passed${NC}"
echo ""

# Run tests
run_test "DEV_WORKSPACE read permission" test_dev_workspace_read_permission
run_test "WORKING_DIR parameter" test_working_dir_parameter
run_test "AGENT_OS_DIR parameter" test_agent_os_dir_parameter
run_test "NATS_URL parameter" test_nats_url_parameter
# EXTRA_EXEC_PATH test removed - cannot be optional in sandbox-exec
run_test "AUDIT_LOG_PATH is writable" test_audit_log_path_writable

# Summary
echo ""
echo "========================================="
echo "Test Summary:"
echo "  Tests Run: $TESTS_RUN"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi