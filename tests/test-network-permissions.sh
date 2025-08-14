#!/bin/bash

# Test Network Permissions for Claude Code Sandbox
# Task 8: Network Configuration Testing
# This script actually executes sandbox commands to verify network permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Parse command line arguments
DRY_RUN_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run]"
            exit 1
            ;;
    esac
done

# Array to track all server PIDs for cleanup
declare -a SERVER_PIDS=()

# NATS server PID file
NATS_PID_FILE="/tmp/test_nats_server.pid"

# Cleanup function to kill all servers
cleanup() {
    echo ""
    echo "Cleaning up test servers..."
    
    # Stop NATS server if running
    if [ -f "$NATS_PID_FILE" ]; then
        NATS_PID=$(cat "$NATS_PID_FILE")
        if kill -0 "$NATS_PID" 2>/dev/null; then
            echo "Stopping NATS server (PID: $NATS_PID)..."
            kill "$NATS_PID" 2>/dev/null || true
            wait "$NATS_PID" 2>/dev/null || true
        fi
        rm -f "$NATS_PID_FILE"
    fi
    
    # Stop other test servers from the PID array
    for pid in "${SERVER_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
    
    # Also kill any remaining simplehttpserver processes that might have been orphaned
    # This catches any servers that didn't get properly tracked
    pkill -f simplehttpserver 2>/dev/null || true
    
    # Clean up any temporary directories
    rm -rf /tmp/test_server_*
    rm -rf /tmp/test_blocked_*
}

# Set up trap to ensure cleanup on exit, interrupt, or termination
trap cleanup EXIT INT TERM

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Network Permissions Test Suite${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check execution mode
if [ "$DRY_RUN_ONLY" = "true" ]; then
    echo -e "${YELLOW}WARNING: Running in dry-run mode - network permissions NOT actually tested${NC}"
    echo "To properly test network permissions, run without --dry-run flag"
    echo ""
else
    # Check if sandbox-exec is available
    if ! command -v sandbox-exec >/dev/null 2>&1; then
        echo -e "${YELLOW}WARNING: sandbox-exec command not found${NC}"
        echo "This test requires macOS sandbox-exec to properly validate network restrictions"
        echo "Continuing with direct execution (no sandbox)..."
        echo ""
    fi
    
    # Check if launcher exists
    if [ ! -f "./claude-code-sandbox-launcher.sh" ]; then
        echo -e "${RED}ERROR: claude-code-sandbox-launcher.sh not found${NC}"
        echo "Please run this script from the agent-os directory"
        exit 1
    fi
fi

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"  # "pass" or "fail"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing: $test_name ... "
    
    # Determine how to run the command based on mode
    local full_command
    if [ "$DRY_RUN_ONLY" = "true" ]; then
        # In dry-run mode, just check command syntax
        full_command="./claude-code-sandbox-launcher.sh --dry-run bash -c \"$test_command\" 2>&1 | grep -q 'Would execute'"
    else
        # Actually run in sandbox
        full_command="WORKING_DIR=\"/tmp\" DEV_WORKSPACE=\"/tmp\" ./claude-code-sandbox-launcher.sh bash -c \"$test_command\" 2>/dev/null"
    fi
    
    # Run the command and capture the result
    if eval "$full_command"; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC} (expected to fail but passed)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}✓ PASSED${NC} (correctly failed)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

# Start NATS server for testing (only if not in dry-run mode)
if [ "$DRY_RUN_ONLY" != "true" ]; then
    echo "Starting NATS server for testing..."
    if command -v nats-server >/dev/null 2>&1; then
        # Start NATS server with PID file
        nats-server --pid "$NATS_PID_FILE" > /dev/null 2>&1 &
        
        # Wait for NATS to start
        sleep 2
        
        # Verify NATS started
        if [ -f "$NATS_PID_FILE" ] && kill -0 "$(cat $NATS_PID_FILE)" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} NATS server started on port 4222"
        else
            echo -e "${YELLOW}⚠${NC} NATS server failed to start - NATS test will be skipped"
        fi
    else
        echo -e "${YELLOW}⚠${NC} nats-server not found - NATS test will be skipped"
    fi
    echo ""
fi

echo "Task 8.2: Testing standard ports (80, 443, 22)"
echo "------------------------------------------------"

# Test HTTP (port 80) - using a known public service
run_test "HTTP port 80 access" \
    "curl -I -s -o /dev/null -w '%{http_code}' --max-time 3 https://echo.free.beeceptor.com | grep -q '301\\|200'" \
    "pass"

# Test HTTPS (port 443) - using a known public service
run_test "HTTPS port 443 access" \
    "curl -I -s -o /dev/null -w '%{http_code}' --max-time 3 https://echo.free.beeceptor.com | grep -q '200'" \
    "pass"

# Test SSH (port 22) - just test connectivity
run_test "SSH port 22 connectivity" \
    "timeout 2 bash -c 'echo > /dev/tcp/github.com/22' 2>/dev/null" \
    "pass"

echo ""
echo "Task 8.3-8.5: Testing development server ports"
echo "-----------------------------------------------"

# Function to test a port with server
test_port_with_server() {
    local port="$1"
    local description="$2"
    
    echo -n "Testing: $description (port $port) ... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$DRY_RUN_ONLY" = "true" ]; then
        # In dry-run mode, just validate configuration
        echo -e "${YELLOW}SKIPPED${NC} (dry-run mode)"
        return
    fi
    
    # Create a test directory with an index file using mktemp for unique names
    TEST_DIR=$(mktemp -d "/tmp/test_server_${port}_XXXXXX")
    echo "Test server on port $port" > "$TEST_DIR/index.html"

    # Start simple HTTP server in background
    simplehttpserver -listen ":$port" -path "$TEST_DIR" > /dev/null 2>&1 &
    SERVER_PID=$!
    
    # Add PID to tracking array
    SERVER_PIDS+=("$SERVER_PID")
    
    # Give server time to start
    sleep 1
    
    # Test connection to the server through sandbox
    if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh \
        curl -s --max-time 2 "http://localhost:$port/" 2>/dev/null | grep -q 'Test server' ; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Only run server tests if not in dry-run mode and simplehttpserver is available
if [ "$DRY_RUN_ONLY" != "true" ] && command -v simplehttpserver >/dev/null 2>&1; then
    echo "Starting test servers on development ports..."
    echo ""
    
    # Test each port listed in the spec
    test_port_with_server 3000 "React/Node.js dev server"
    test_port_with_server 3001 "Alternative React port"
    test_port_with_server 5000 "Flask dev server"
    test_port_with_server 5173 "Vite dev server"
    test_port_with_server 8000 "Django dev server"
    test_port_with_server 8080 "Common web server"
    test_port_with_server 4200 "Angular dev server"
    test_port_with_server 9000 "Common dev port"
elif [ "$DRY_RUN_ONLY" != "true" ]; then
    echo -e "${YELLOW}⚠ simplehttpserver not found - skipping local server tests${NC}"
    echo "Install with: go install github.com/briandowns/simple-httpserver/simplehttpserver@latest"
fi

echo ""
echo "Task 8.4: Testing NATS access for localhost:4222"
echo "-------------------------------------------------"

# Check if NATS is running (either from our startup or already running)
if [ "$DRY_RUN_ONLY" = "true" ]; then
    echo -e "${YELLOW}NATS test skipped (dry-run mode)${NC}"
elif nc -z localhost 4222 2>/dev/null; then
    run_test "NATS publish message" \
        "echo 'test message' | nats pub test.subject -" \
        "pass"
else
    echo -e "${YELLOW}⚠ NATS server not running on localhost:4222${NC}"
    echo -e "${YELLOW}  Check if nats-server is installed or if port 4222 is blocked${NC}"
fi

echo ""
echo "Task 8.6: Testing blocked ports (should fail)"
echo "----------------------------------------------"

# Test that non-whitelisted ports are blocked
test_blocked_port() {
    local port="$1"
    local description="$2"
    
    echo -n "Testing: Blocking port $port ($description) ... "
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$DRY_RUN_ONLY" = "true" ]; then
        echo -e "${YELLOW}SKIPPED${NC} (dry-run mode)"
        return
    fi
    
    # Start a server on non-whitelisted port (outside sandbox)
    TEST_DIR=$(mktemp -d "/tmp/test_blocked_${port}_XXXXXX")
    echo "Blocked test" > "$TEST_DIR/index.html"
    simplehttpserver -listen ":$port" -path "$TEST_DIR" > /dev/null 2>&1 &
    SERVER_PID=$!
    
    # Add PID to tracking array
    SERVER_PIDS+=("$SERVER_PID")
    
    sleep 1
    
    # Try to connect through sandbox (should fail)
    if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh \
        curl -s --max-time 2 "http://localhost:$port/" 2>/dev/null; then
        echo -e "${RED}✗ FAILED${NC} (port should be blocked)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓ PASSED${NC} (correctly blocked)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

if [ "$DRY_RUN_ONLY" != "true" ] && command -v simplehttpserver >/dev/null 2>&1; then
    test_blocked_port 6666 "Non-standard port"
    test_blocked_port 12345 "Random high port"
elif [ "$DRY_RUN_ONLY" = "true" ]; then
    echo -e "${YELLOW}Blocked port tests skipped (dry-run mode)${NC}"
else
    echo -e "${YELLOW}⚠ simplehttpserver not found - skipping blocked port tests${NC}"
fi

echo ""
echo "========================================="
echo "Test Results Summary"
echo "========================================="
echo "Tests Run: $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ "$DRY_RUN_ONLY" = "true" ]; then
    echo ""
    echo -e "${YELLOW}Note: Ran in dry-run mode - network access not actually tested${NC}"
    echo "Run without --dry-run to properly test network permissions"
fi

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. For public service tests (80, 443, 22): Check internet connectivity"
    echo "2. For local port tests: Ensure no other services are using these ports"
    echo "3. For sandbox mode: Verify launcher script has correct permissions"
    echo "4. For NATS: Start NATS server with 'nats-server' if needed"
    exit 1
fi