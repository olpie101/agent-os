#!/bin/bash
# Run all sandbox tests sequentially
# This script executes all test scripts for the Claude Code Sandbox Security spec

set -e  # Exit on first error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   Claude Code Sandbox Test Suite${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to run a test script and track results
run_test_script() {
    local script_name="$1"
    local task_name="$2"
    
    echo -e "${YELLOW}Running $task_name tests...${NC}"
    echo "----------------------------------------"
    
    if [ -f "$script_name" ] && [ -x "$script_name" ]; then
        if "$script_name"; then
            echo -e "${GREEN}✅ $task_name: ALL TESTS PASSED${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ $task_name: SOME TESTS FAILED${NC}"
            ((FAILED_TESTS++))
        fi
    else
        echo -e "${RED}❌ $task_name: Test script not found or not executable${NC}"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    echo ""
}

# Run Task 2 tests: Launcher script
if [ -f "tests/test-launcher.sh" ]; then
    run_test_script "tests/test-launcher.sh" "Task 2 - Launcher Script"
else
    echo -e "${YELLOW}Skipping Task 2 tests - test-launcher.sh not found${NC}"
    echo ""
fi

# Run Task 3 tests: Environment variables
run_test_script "tests/test-env-vars.sh" "Task 3 - Environment Variables"

# Run Task 4 tests: Read restrictions
run_test_script "tests/test-read-restrictions.sh" "Task 4 - Read Restrictions"

# Run Task 5 tests: Write restrictions
run_test_script "tests/test-write-restrictions.sh" "Task 5 - Write Restrictions"

# Run Task 6 tests: Deny rules for sensitive directories
run_test_script "tests/test-sandbox-deny-rules.sh" "Task 6 - Deny Rules"

# Run Task 7 tests: Executable permissions
run_test_script "tests/test-executable-permissions.sh" "Task 7 - Executable Permissions"

# Run Task 8 tests: Network configuration
run_test_script "tests/test-network-permissions.sh" "Task 8 - Network Configuration"

# Run Task 9 tests: Audit logging
run_test_script "tests/test-audit-logging.sh" "Task 9 - Audit Logging"

# Final summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}         OVERALL TEST SUMMARY${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Test Suites Run: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TEST SUITES PASSED!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  SOME TEST SUITES FAILED${NC}"
    echo "Please review the output above for details."
    exit 1
fi