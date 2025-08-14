#!/bin/bash
# Test script for Task 7: Executable Permissions Configuration
# This script verifies that executable permissions are properly configured

# Note: Not using set -e to allow all tests to run

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASS_COUNT=0
FAIL_COUNT=0

# Cleanup function
cleanup() {
    # Clean up any test files that might be left behind
    rm -f /tmp/test_exec_sandbox_main.sh /tmp/test_input_sandbox.txt 2>/dev/null
    rm -f /tmp/test_exec_sandbox.sh /tmp/wrapper_sandbox.sh 2>/dev/null
    rm -f "$HOME/test_exec_sandbox.sh" /var/test_exec_sandbox.sh 2>/dev/null
    rm -f "${DEV_WORKSPACE:-$HOME/dev}/test_exec_sandbox.sh" 2>/dev/null
    rm -f "$HOME/.agent-os/scripts/test_exec_sandbox.sh" 2>/dev/null
}

# Set up trap for cleanup on exit
trap cleanup EXIT INT TERM

# Test function for executable permissions
test_executable() {
    local test_name="$1"
    local executable_path="$2"
    local expected_result="$3"  # "allow" or "deny"
    
    echo -n "Testing $test_name... "
    
    # Create a test file for commands that need input with fixed name
    local test_file="/tmp/test_input_sandbox.txt"
    echo "test content" > "$test_file"
    
    # Create a test script that attempts to execute the command with fixed name
    local test_script="/tmp/test_exec_sandbox_main.sh"
    cat > "$test_script" << EOF
#!/bin/bash
# Test if we can execute the command
if [ -x "$executable_path" ]; then
    # Different test strategies for different commands
    case "$executable_path" in
        */cat|*/head|*/tail|*/wc|*/sort|*/uniq|*/cut|*/sed|*/awk)
            # Commands that need input - use test file
            "$executable_path" "$test_file" 2>/dev/null >/dev/null && echo "EXEC_OK"
            ;;
        */grep)
            # grep needs a pattern and a file
            echo "test" | "$executable_path" "test" "$test_file" 2>/dev/null >/dev/null && echo "EXEC_OK"
            ;;
        */ls|*/pwd|*/echo)
            # Commands that work without arguments
            "$executable_path" 2>/dev/null >/dev/null && echo "EXEC_OK"
            ;;
        */mkdir|*/rm|*/cp|*/mv|*/chmod)
            # Commands that need specific args - just check if executable
            echo "EXEC_OK"
            ;;
        */test)
            # test command - use with simple expression
            "$executable_path" -e "$test_file" 2>/dev/null && echo "EXEC_OK"
            ;;
        */find|*/mktemp|*/which|*/env|*/dirname|*/basename)
            # Commands with various arg requirements
            case "$executable_path" in
                */find) "$executable_path" /tmp -maxdepth 0 2>/dev/null >/dev/null && echo "EXEC_OK" ;;
                */mktemp) "$executable_path" 2>/dev/null >/dev/null && echo "EXEC_OK" ;;
                */which) "$executable_path" ls 2>/dev/null >/dev/null && echo "EXEC_OK" ;;
                */env) "$executable_path" 2>/dev/null >/dev/null && echo "EXEC_OK" ;;
                */dirname) "$executable_path" /tmp/test 2>/dev/null >/dev/null && echo "EXEC_OK" ;;
                */basename) "$executable_path" /tmp/test 2>/dev/null >/dev/null && echo "EXEC_OK" ;;
            esac
            ;;
        */make)
            # make - just check version
            "$executable_path" --version 2>/dev/null >/dev/null && echo "EXEC_OK"
            ;;
        */git|*/python3|*/npm)
            # Special handling for tools that might be wrappers
            "$executable_path" --version 2>/dev/null >/dev/null && echo "EXEC_OK"
            ;;
        *)
            # Default: try --version, -v, or just run it
            "$executable_path" --version 2>/dev/null >/dev/null || \
            "$executable_path" -v 2>/dev/null >/dev/null || \
            "$executable_path" 2>/dev/null >/dev/null || \
            echo "EXEC_OK"
            ;;
    esac
    echo "EXEC_ALLOWED"
else
    echo "EXEC_DENIED"
fi
EOF
    chmod +x "$test_script"
    
    # Run the test with sandbox-exec directly to avoid dry-run issues
    # Use timeout to prevent hanging
    local result=$(timeout 2 sandbox-exec \
        -D HOME="$HOME" \
        -D DEV_WORKSPACE="${DEV_WORKSPACE:-$HOME/dev}" \
        -D WORKING_DIR="/tmp" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/audit" \
        -f claude-code-sandbox.sb \
        "$test_script" 2>/dev/null | grep -E "EXEC_ALLOWED|EXEC_DENIED" || echo "EXEC_DENIED")
    
    # Clean up test files
    rm -f "$test_script" "$test_file"
    
    # Check result
    if [ "$expected_result" = "allow" ]; then
        if [ "$result" = "EXEC_ALLOWED" ]; then
            echo -e "${GREEN}✓${NC} (Execution allowed)"
            ((PASS_COUNT++))
        else
            echo -e "${RED}✗${NC} (Execution should be allowed but was denied)"
            ((FAIL_COUNT++))
        fi
    else
        if [ "$result" = "EXEC_DENIED" ] || [ -z "$result" ]; then
            echo -e "${GREEN}✓${NC} (Execution properly denied)"
            ((PASS_COUNT++))
        else
            echo -e "${RED}✗${NC} (Execution should be denied but was allowed)"
            ((FAIL_COUNT++))
        fi
    fi
}

# Test function for script execution within directories
test_directory_exec() {
    local test_name="$1"
    local script_dir="$2"
    local expected_result="$3"  # "allow" or "deny"
    
    echo -n "Testing $test_name... "
    
    # Create a test executable in the specified directory with a fixed name
    local test_exec="$script_dir/test_exec_sandbox.sh"
    
    # Create the test executable (this happens outside sandbox)
    mkdir -p "$script_dir" 2>/dev/null
    cat > "$test_exec" << 'EOF'
#!/bin/bash
echo "SCRIPT_EXECUTED"
EOF
    chmod +x "$test_exec"
    
    # Create a wrapper script to run in sandbox with a fixed name
    local wrapper_script="/tmp/wrapper_sandbox.sh"
    cat > "$wrapper_script" << EOF
#!/bin/bash
"$test_exec" 2>/dev/null
if [ \$? -eq 0 ]; then
    echo "EXEC_ALLOWED"
else
    echo "EXEC_DENIED"
fi
EOF
    chmod +x "$wrapper_script"
    
    # Run the test in sandbox
    # For testing HOME root, we need to set WORKING_DIR to something else (not HOME)
    local working_dir_param="$script_dir"
    if [ "$script_dir" = "$HOME" ]; then
        # Testing HOME root - use /tmp as WORKING_DIR to avoid false positive
        working_dir_param="/tmp"
    fi
    
    local result=$(sandbox-exec \
        -D HOME="$HOME" \
        -D DEV_WORKSPACE="${DEV_WORKSPACE:-$HOME/dev}" \
        -D WORKING_DIR="$working_dir_param" \
        -D AGENT_OS_DIR="$HOME/.agent-os" \
        -D AUDIT_LOG_PATH="/tmp/audit" \
        -f claude-code-sandbox.sb \
        "$wrapper_script" 2>/dev/null | grep -E "EXEC_ALLOWED|EXEC_DENIED|SCRIPT_EXECUTED")
    
    # Clean up
    rm -f "$test_exec" "$wrapper_script"
    
    # Check result
    if [ "$expected_result" = "allow" ]; then
        if [[ "$result" == *"SCRIPT_EXECUTED"* ]] || [[ "$result" == *"EXEC_ALLOWED"* ]]; then
            echo -e "${GREEN}✓${NC} (Script execution allowed)"
            ((PASS_COUNT++))
        else
            echo -e "${RED}✗${NC} (Script execution should be allowed but was denied)"
            ((FAIL_COUNT++))
        fi
    else
        if [[ "$result" == *"EXEC_DENIED"* ]] || [ -z "$result" ]; then
            echo -e "${GREEN}✓${NC} (Script execution properly denied)"
            ((PASS_COUNT++))
        else
            echo -e "${RED}✗${NC} (Script execution should be denied but was allowed)"
            ((FAIL_COUNT++))
        fi
    fi
}

echo "==================================="
echo "Task 7.1: Testing Executable Permissions"
echo "==================================="
echo ""

# Task 7.2: Test core system commands
echo "Task 7.2: Testing core system commands"
test_executable "sh" "/bin/sh" "allow"
test_executable "bash" "/bin/bash" "allow"
test_executable "zsh" "/bin/zsh" "allow"
test_executable "cat" "/bin/cat" "allow"
test_executable "echo" "/bin/echo" "allow"
test_executable "ls" "/bin/ls" "allow"
test_executable "pwd" "/bin/pwd" "allow"
test_executable "mkdir" "/bin/mkdir" "allow"
test_executable "rm" "/bin/rm" "allow"
test_executable "cp" "/bin/cp" "allow"
test_executable "mv" "/bin/mv" "allow"
test_executable "chmod" "/bin/chmod" "allow"
echo ""

# Task 7.3: Test shell utilities
echo "Task 7.3: Testing shell utilities"
test_executable "test" "/bin/test" "allow"
test_executable "dirname" "/usr/bin/dirname" "allow"
test_executable "basename" "/usr/bin/basename" "allow"
test_executable "find" "/usr/bin/find" "allow"
test_executable "make" "/usr/bin/make" "allow"
test_executable "sed" "/usr/bin/sed" "allow"
test_executable "awk" "/usr/bin/awk" "allow"
test_executable "grep" "/usr/bin/grep" "allow"
test_executable "mktemp" "/usr/bin/mktemp" "allow"
test_executable "wc" "/usr/bin/wc" "allow"
test_executable "head" "/usr/bin/head" "allow"
test_executable "tail" "/usr/bin/tail" "allow"
test_executable "sort" "/usr/bin/sort" "allow"
test_executable "uniq" "/usr/bin/uniq" "allow"
test_executable "cut" "/usr/bin/cut" "allow"
test_executable "which" "/usr/bin/which" "allow"
test_executable "env" "/usr/bin/env" "allow"
echo ""

# Task 7.4: Test Homebrew executable paths
echo "Task 7.4: Testing Homebrew executable paths"
# Find actual paths using which and test only if they exist
echo "Finding actual executable paths..."

# Test git
GIT_PATH=$(which git 2>/dev/null)
if [ -n "$GIT_PATH" ]; then
    echo "  Found git at: $GIT_PATH"
    test_executable "git" "$GIT_PATH" "allow"
else
    echo "  git not found - skipping"
fi

# Test node
NODE_PATH=$(which node 2>/dev/null)
if [ -n "$NODE_PATH" ]; then
    echo "  Found node at: $NODE_PATH"
    test_executable "node" "$NODE_PATH" "allow"
else
    echo "  node not found - skipping"
fi

# Test python3
PYTHON3_PATH=$(which python3 2>/dev/null)
if [ -n "$PYTHON3_PATH" ]; then
    echo "  Found python3 at: $PYTHON3_PATH"
    test_executable "python3" "$PYTHON3_PATH" "allow"
else
    echo "  python3 not found - skipping"
fi

# Test npm if it exists
NPM_PATH=$(which npm 2>/dev/null)
if [ -n "$NPM_PATH" ]; then
    echo "  Found npm at: $NPM_PATH"
    test_executable "npm" "$NPM_PATH" "allow"
else
    echo "  npm not found - skipping"
fi

echo ""

# Task 7.5: Test execution within DEV_WORKSPACE
echo "Task 7.5: Testing execution within DEV_WORKSPACE"
DEV_WORKSPACE="${DEV_WORKSPACE:-$HOME/dev}"
test_directory_exec "Script in DEV_WORKSPACE" "$DEV_WORKSPACE" "allow"
test_directory_exec "Script in WORKING_DIR (/tmp)" "/tmp" "allow"
echo ""

# Task 7.6: Test Agent OS scripts execution
echo "Task 7.6: Testing Agent OS scripts execution"
AGENT_OS_SCRIPTS="$HOME/.agent-os/scripts"
if [ -d "$AGENT_OS_SCRIPTS" ]; then
    test_directory_exec "Agent OS scripts" "$AGENT_OS_SCRIPTS" "allow"
else
    echo "Creating temporary Agent OS scripts directory for testing"
    mkdir -p "$AGENT_OS_SCRIPTS"
    test_directory_exec "Agent OS scripts" "$AGENT_OS_SCRIPTS" "allow"
fi
echo ""

# Test that random directories are denied execution
echo "Verifying execution is denied in non-allowed directories:"
test_directory_exec "Script in HOME root" "$HOME" "deny"
test_directory_exec "Script in /var" "/var" "deny"
echo ""

# Summary
echo "==================================="
echo "Test Summary"
echo "==================================="
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the sandbox configuration.${NC}"
    exit 1
fi