#!/bin/bash
# Test suite for Task 5: File System Write Access Restrictions
# Task 5.1: Write tests for write permission boundaries

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

# Test functions for write restrictions

test_working_dir_writable() {
    # Test that WORKING_DIR is writable
    local test_file="/tmp/test_working_dir_write_$$"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Test writing to WORKING_DIR
TEST_FILE="test_write_$$.txt"
echo "test content" > "$TEST_FILE"
if [ -f "$TEST_FILE" ]; then
    rm -f "$TEST_FILE"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_file"
    
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

test_dev_workspace_not_writable() {
    # Test that DEV_WORKSPACE (parent) is NOT writable
    local test_file="/tmp/test_dev_workspace_no_write_$$"
    
    # Create dev directory if it doesn't exist
    mkdir -p "$HOME/dev"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Try to write to DEV_WORKSPACE (should fail)
echo "test" > "$HOME/dev/should_not_write_$$.txt" 2>/dev/null
EOF
    chmod +x "$test_file"
    
    # This should FAIL because DEV_WORKSPACE should not be writable
    if sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file" 2>/dev/null; then
        # If it succeeds, the test fails (we don't want write access)
        rm -f "$HOME/dev/should_not_write_$$.txt" 2>/dev/null
        rm -f "$test_file"
        return 1
    else
        # If it fails, the test passes (write should be denied)
        rm -f "$test_file"
        return 0
    fi
}

test_tmp_writable() {
    # Test that /tmp is writable
    local test_file="/tmp/test_tmp_write_$$"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Test writing to /tmp
TMP_FILE="/tmp/test_tmp_write_$$.txt"
echo "test content" > "$TMP_FILE"
if [ -f "$TMP_FILE" ]; then
    rm -f "$TMP_FILE"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_file"
    
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

test_npm_cache_writable() {
    # Test that npm cache is writable
    local test_file="/tmp/test_npm_cache_write_$$"
    
    # Create .npm directory if it doesn't exist
    mkdir -p "$HOME/.npm"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Test writing to npm cache
NPM_CACHE_FILE="$HOME/.npm/test_cache_$$.txt"
echo "cache content" > "$NPM_CACHE_FILE"
if [ -f "$NPM_CACHE_FILE" ]; then
    rm -f "$NPM_CACHE_FILE"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_file"
    
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

test_cache_dir_writable() {
    # Test that .cache directory is writable
    local test_file="/tmp/test_cache_write_$$"
    
    # Create .cache directory if it doesn't exist
    mkdir -p "$HOME/.cache"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Test writing to .cache directory
CACHE_FILE="$HOME/.cache/test_cache_$$.txt"
echo "cache content" > "$CACHE_FILE"
if [ -f "$CACHE_FILE" ]; then
    rm -f "$CACHE_FILE"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_file"
    
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -f "$test_file"
    return $result
}

test_audit_log_writable() {
    # Test that AUDIT_LOG_PATH is writable
    local test_file="/tmp/test_audit_log_write_$$"
    local audit_dir="/tmp/test_audit_$$"
    
    mkdir -p "$audit_dir"
    
    cat > "$test_file" << EOF
#!/bin/bash
# Test writing to audit log path
AUDIT_FILE="$audit_dir/audit_test_\$\$.log"
echo "audit entry" > "\$AUDIT_FILE"
if [ -f "\$AUDIT_FILE" ]; then
    rm -f "\$AUDIT_FILE"
    exit 0
else
    exit 1
fi
EOF
    chmod +x "$test_file"
    
    sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="$audit_dir" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file"
    
    local result=$?
    rm -rf "$audit_dir"
    rm -f "$test_file"
    return $result
}

test_home_not_writable() {
    # Test that HOME directory root is NOT writable
    local test_file="/tmp/test_home_no_write_$$"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Try to write to HOME directory root (should fail)
echo "test" > "$HOME/should_not_write_$$.txt" 2>/dev/null
EOF
    chmod +x "$test_file"
    
    # This should FAIL because HOME root should not be writable
    if sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file" 2>/dev/null; then
        # If it succeeds, the test fails
        rm -f "$HOME/should_not_write_$$.txt" 2>/dev/null
        rm -f "$test_file"
        return 1
    else
        # If it fails, the test passes (write should be denied)
        rm -f "$test_file"
        return 0
    fi
}

test_system_dirs_not_writable() {
    # Test that system directories are NOT writable
    local test_file="/tmp/test_system_no_write_$$"
    
    cat > "$test_file" << 'EOF'
#!/bin/bash
# Try to write to /usr (should fail)
echo "test" > "/usr/should_not_write_$$.txt" 2>/dev/null
EOF
    chmod +x "$test_file"
    
    # This should FAIL
    if sandbox-exec \
        -D DEV_WORKSPACE="$HOME/dev" \
        -D WORKING_DIR="$(pwd)" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
        -D HOME="$HOME" \
        -f ../profiles/claude-code-sandbox.sb \
        "$test_file" 2>/dev/null; then
        # If it succeeds, the test fails
        rm -f "$test_file"
        return 1
    else
        # If it fails, the test passes
        rm -f "$test_file"
        return 0
    fi
}

# Main test execution
echo "========================================="
echo "File System Write Access Restriction Tests"
echo "========================================="
echo ""

# First verify the sandbox profile exists
if [ ! -f "../profiles/claude-code-sandbox.sb" ]; then
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
    -f ../profiles/claude-code-sandbox.sb \
    /bin/bash -c "echo 'Pre-task validation OK'"; then
    echo -e "${RED}Pre-task validation failed! Cannot proceed with tests.${NC}"
    exit 1
fi
echo -e "${GREEN}Pre-task validation passed${NC}"
echo ""

# Run tests
run_test "WORKING_DIR is writable" test_working_dir_writable
run_test "DEV_WORKSPACE is NOT writable" test_dev_workspace_not_writable
run_test "/tmp is writable" test_tmp_writable
run_test "NPM cache is writable" test_npm_cache_writable
run_test ".cache directory is writable" test_cache_dir_writable
run_test "AUDIT_LOG_PATH is writable" test_audit_log_writable
run_test "HOME root is NOT writable" test_home_not_writable
run_test "System directories NOT writable" test_system_dirs_not_writable

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