#!/bin/bash

# Test Runner Script for Claude Code Hooks
# This script runs all test files using UV

set -e  # Exit on error

echo "🧪 Running All Claude Code Hook Tests"
echo "====================================="
echo ""

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_FILES=()

# Function to run a test file
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file")
    
    echo "📝 Testing: $test_name"
    echo "   Path: $test_file"
    
    # Run the test and capture the output
    if output=$(uv run "$test_file" 2>&1); then
        # Extract test results from output
        if echo "$output" | grep -q "passed"; then
            passed=$(echo "$output" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+")
            echo "   ✅ Result: $passed tests passed"
            PASSED_TESTS=$((PASSED_TESTS + passed))
            TOTAL_TESTS=$((TOTAL_TESTS + passed))
        fi
    else
        echo "   ❌ Result: Test failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_FILES+=("$test_file")
    fi
    
    # Check for failures in output even if exit code is 0
    if echo "$output" | grep -q "failed"; then
        failed=$(echo "$output" | grep -oE "[0-9]+ failed" | grep -oE "[0-9]+" | head -1)
        if [ "$failed" != "0" ] && [ -n "$failed" ]; then
            echo "   ⚠️  Warning: $failed test(s) failed"
            FAILED_TESTS=$((FAILED_TESTS + failed))
            TOTAL_TESTS=$((TOTAL_TESTS + failed))
            FAILED_FILES+=("$test_file")
        fi
    fi
    
    echo ""
}

# Find and run all test files
echo "🔍 Finding test files..."
echo ""

# Test files in hooks/tests/
for test_file in claude-code/hooks/tests/test*.py; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
    fi
done

# Test files in hooks/utils/llm/
for test_file in claude-code/hooks/utils/llm/test*.py; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
    fi
done

# Test files in hooks/utils/tts/
for test_file in claude-code/hooks/utils/tts/test*.py; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
    fi
done

# Summary
echo "====================================="
echo "📊 Test Summary"
echo "====================================="
echo ""
echo "Total Tests Run: $TOTAL_TESTS"
echo "✅ Passed: $PASSED_TESTS"
echo "❌ Failed: $FAILED_TESTS"
echo ""

if [ ${#FAILED_FILES[@]} -gt 0 ]; then
    echo "Failed test files:"
    for file in "${FAILED_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "❌ Some tests failed. Please review the output above."
    exit 1
else
    echo "✅ All tests passed successfully!"
    exit 0
fi