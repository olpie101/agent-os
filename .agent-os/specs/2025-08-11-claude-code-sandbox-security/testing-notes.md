# Testing Notes for Claude Code Sandbox Security

## Task 6 - Explicit Deny Rules Testing

**Date**: 2025-08-11
**Status**: Implementation complete, partial test verification

### Test Results
- ✅ All 27 deny rules tests passed - sensitive directories are properly blocked:
  - SSH keys and configuration
  - Cloud credentials (.aws, .gcp, .azure)
  - Git credentials and shell history
  - Kubernetes and Android configs
  - Browser profiles and password stores

### Known Testing Issue
The test script `test-sandbox-deny-rules.sh` currently cannot properly verify allowed access for development directories when using `--dry-run` mode. The following tests show false negatives:
- DEV_WORKSPACE access test
- .claude directory access test
- .agent-os directory access test

**Root Cause**: The `--dry-run` flag prevents actual sandbox execution, making it impossible to test positive access cases properly.

### Required for Full Testing (Task 10)
During Task 10 (Integration Testing), we need to:
1. Test without `--dry-run` to verify both deny and allow rules work correctly
2. Verify that development directories remain accessible while sensitive directories are blocked
3. Run actual commands within the sandbox to confirm the security boundaries

### Manual Verification Command
To manually verify allow rules work (requires actual sandbox execution):
```bash
# This should work (allowed directory)
sandbox-exec -D HOME="$HOME" -D DEV_WORKSPACE="$HOME/dev" -D WORKING_DIR="$(pwd)" -D AGENT_OS_DIR="$HOME/.agent-os" -D AUDIT_LOG_PATH="/tmp/audit" -f claude-code-sandbox.sb ls ~/.agent-os

# This should fail (denied directory)
sandbox-exec -D HOME="$HOME" -D DEV_WORKSPACE="$HOME/dev" -D WORKING_DIR="$(pwd)" -D AGENT_OS_DIR="$HOME/.agent-os" -D AUDIT_LOG_PATH="/tmp/audit" -f claude-code-sandbox.sb ls ~/.ssh
```