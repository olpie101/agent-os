#!/bin/bash
# verify-sandbox-security.sh
# Manual verification script for sandbox security restrictions
# This script MUST be run to properly validate that sensitive directories are blocked

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== MANUAL SANDBOX SECURITY VERIFICATION ===${NC}"
echo "This script runs actual sandbox-exec commands to verify security restrictions"
echo "Unlike test-sandbox-deny-rules.sh, this actually executes the sandbox"
echo ""

# Check if sandbox-exec is available
if ! command -v sandbox-exec >/dev/null 2>&1; then
    echo -e "${RED}ERROR: sandbox-exec command not found${NC}"
    echo "This test requires macOS sandbox-exec to be available"
    exit 1
fi

# Check if launcher exists
if [ ! -f "./claude-code-sandbox-launcher.sh" ]; then
    echo -e "${RED}ERROR: claude-code-sandbox-launcher.sh not found${NC}"
    echo "Please run this script from the agent-os directory"
    exit 1
fi

echo -e "${YELLOW}Testing DENIED access (should fail with 'Operation not permitted')${NC}"
echo "========================================="

# Test 1: Verify sensitive directories are denied
echo ""
echo "Test 1: .ssh directory access:"
echo "Command: ls \$HOME/.ssh"
if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh ls "$HOME/.ssh" 2>&1 | grep -q "Operation not permitted"; then
    echo -e "${GREEN}✓ PASS${NC} - Access correctly denied"
else
    echo -e "${RED}✗ FAIL${NC} - Access was NOT denied (security risk!)"
fi

echo ""
echo "Test 2: .aws directory access:"
echo "Command: ls \$HOME/.aws"
if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh ls "$HOME/.aws" 2>&1 | grep -q "Operation not permitted"; then
    echo -e "${GREEN}✓ PASS${NC} - Access correctly denied"
else
    echo -e "${RED}✗ FAIL${NC} - Access was NOT denied (security risk!)"
fi

echo ""
echo "Test 3: .gitconfig file access:"
echo "Command: cat \$HOME/.gitconfig"
if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh cat "$HOME/.gitconfig" 2>&1 | grep -q "Operation not permitted"; then
    echo -e "${GREEN}✓ PASS${NC} - Access correctly denied"
else
    echo -e "${RED}✗ FAIL${NC} - Access was NOT denied (security risk!)"
fi

echo ""
echo "Test 4: .bash_history access:"
echo "Command: cat \$HOME/.bash_history"
if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh cat "$HOME/.bash_history" 2>&1 | grep -q "Operation not permitted"; then
    echo -e "${GREEN}✓ PASS${NC} - Access correctly denied"
else
    echo -e "${RED}✗ FAIL${NC} - Access was NOT denied (security risk!)"
fi

echo ""
echo -e "${YELLOW}Testing ALLOWED access (should succeed or show 'No such file')${NC}"
echo "========================================="

# Test allowed directories
echo ""
echo "Test 5: .claude directory access:"
echo "Command: ls \$HOME/.claude"
OUTPUT=$(WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh ls "$HOME/.claude" 2>&1 || true)
if echo "$OUTPUT" | grep -q "Operation not permitted"; then
    echo -e "${RED}✗ FAIL${NC} - Access was denied (should be allowed)"
else
    echo -e "${GREEN}✓ PASS${NC} - Access correctly allowed"
    echo "  Output: $(echo "$OUTPUT" | head -1)"
fi

echo ""
echo "Test 6: .agent-os directory access:"
echo "Command: ls \$HOME/.agent-os"
OUTPUT=$(WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh ls "$HOME/.agent-os" 2>&1 || true)
if echo "$OUTPUT" | grep -q "Operation not permitted"; then
    echo -e "${RED}✗ FAIL${NC} - Access was denied (should be allowed)"
else
    echo -e "${GREEN}✓ PASS${NC} - Access correctly allowed"
    echo "  Output: $(echo "$OUTPUT" | head -1)"
fi

echo ""
echo "Test 7: DEV_WORKSPACE (/tmp) access:"
echo "Command: ls /tmp"
OUTPUT=$(WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh ls "/tmp" 2>&1 || true)
if echo "$OUTPUT" | grep -q "Operation not permitted"; then
    echo -e "${RED}✗ FAIL${NC} - Access was denied (should be allowed)"
else
    echo -e "${GREEN}✓ PASS${NC} - Access correctly allowed"
    echo "  Output: $(echo "$OUTPUT" | head -1 | cut -c1-50)..."
fi

echo ""
echo "Test 8: Current working directory write access:"
echo "Command: touch /tmp/test_write_$$.txt"
if WORKING_DIR="/tmp" DEV_WORKSPACE="/tmp" ./claude-code-sandbox-launcher.sh touch "/tmp/test_write_$$.txt" 2>&1 >/dev/null; then
    echo -e "${GREEN}✓ PASS${NC} - Write access correctly allowed"
    rm -f "/tmp/test_write_$$.txt"
else
    echo -e "${RED}✗ FAIL${NC} - Write access was denied (should be allowed)"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Expected results:"
echo "  - Tests 1-4: Should show '✓ PASS - Access correctly denied'"
echo "  - Tests 5-8: Should show '✓ PASS - Access correctly allowed'"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC} If any sensitive directory shows as NOT denied,"
echo "there is a security vulnerability in the sandbox configuration!"
echo ""
echo "This verification script actually executes sandbox-exec commands,"
echo "unlike test-sandbox-deny-rules.sh which only uses dry-run mode."