# Claude Code Sandbox Troubleshooting Guide

## Overview

This guide helps diagnose and resolve common issues when using the Claude Code Sandbox. Each issue includes symptoms, causes, and step-by-step solutions.

## Quick Diagnostics

### Test Basic Sandbox Operation

```bash
# Test if sandbox executes at all
sandbox-exec -f claude-code-sandbox.sb \
  -D DEV_WORKSPACE="$HOME/dev" \
  -D WORKING_DIR="$(pwd)" \
  -D AGENT_OS_DIR="$HOME/.agent-os" \
  -D HOME="$HOME" \
  -D NATS_URL="nats://localhost:4222" \
  -D NATS_CREDS="" \
  -D AUDIT_LOG_PATH="/tmp/test" \
  -D VERBOSE_MODE="false" \
  -D EXTRA_EXEC_PATH="" \
  /bin/echo "Sandbox works"
```

If this fails, the sandbox profile has syntax errors or missing parameters.

## Common Issues and Solutions

## 1. File Access Denied

### Symptoms
- "Permission denied" errors when reading files
- "Operation not permitted" messages
- Claude Code cannot see expected files

### Diagnosis
```bash
# Enable verbose mode to see denials
SANDBOX_VERBOSE="true" ./claude-code-sandbox-launcher.sh claude-code

# Check audit logs
tail -f ~/dev/.sandbox-audit/*/sandbox-*.log | grep "denied"
```

### Solutions

#### Files Outside DEV_WORKSPACE
**Problem:** Trying to read files outside the configured workspace  
**Solution:** 
```bash
# Option 1: Move files into DEV_WORKSPACE
cp -r /external/project ~/dev/

# Option 2: Expand DEV_WORKSPACE
DEV_WORKSPACE="/Users/john" ./claude-code-sandbox-launcher.sh claude-code
```

#### Sensitive Files Blocked
**Problem:** Attempting to access .ssh, .aws, or other protected directories  
**Solution:** These are intentionally blocked. Copy only needed non-sensitive files:
```bash
# Copy only public keys if needed
cp ~/.ssh/id_rsa.pub ~/dev/project/deploy_key.pub
```

#### Symlink Issues
**Problem:** Symlinks pointing outside DEV_WORKSPACE  
**Solution:** 
```bash
# Check where symlinks point
ls -la ~/dev/project/
# Replace with real files or adjust DEV_WORKSPACE
```

## 2. Cannot Write/Modify Files

### Symptoms
- Cannot save changes
- "Read-only file system" errors
- New files cannot be created

### Diagnosis
```bash
# Check WORKING_DIR setting
echo "WORKING_DIR=$WORKING_DIR"
pwd

# Verify write permissions
touch test_write.txt && echo "Write OK" && rm test_write.txt
```

### Solutions

#### Wrong WORKING_DIR
**Problem:** WORKING_DIR not set to current project  
**Solution:**
```bash
cd ~/dev/my-project
WORKING_DIR="$(pwd)" ./claude-code-sandbox-launcher.sh claude-code
```

#### Trying to Write Outside WORKING_DIR
**Problem:** Attempting to modify files in read-only areas  
**Solution:** Ensure all modifications happen within WORKING_DIR:
```bash
# Set WORKING_DIR to project root
WORKING_DIR="~/dev/entire-project" ./claude-code-sandbox-launcher.sh claude-code
```

## 3. Network Connection Failures

### Symptoms
- Cannot download packages
- API calls fail
- "Network is unreachable" errors
- DNS resolution failures with curl/wget

### Diagnosis
```bash
# Test network access within sandbox
sandbox-exec -f claude-code-sandbox.sb [params] \
  /usr/bin/curl -I https://google.com

# Check DNS resolution
sandbox-exec -f claude-code-sandbox.sb [params] \
  /usr/bin/dig google.com
```

### Known Issues

#### DNS Resolution with curl/wget
**Problem:** curl and wget fail DNS lookups inside sandbox  
**Status:** Known limitation in Task 8.6  
**Workaround:** 
```bash
# Use IP addresses directly if possible
curl http://142.250.80.46  # Google's IP

# Or use tools outside sandbox for downloads
curl -o ~/dev/package.tar.gz https://example.com/package.tar.gz
# Then use from within sandbox
```

#### Custom Ports Blocked
**Problem:** Development server on non-standard port  
**Solution:** Use standard development ports:
- 3000, 3001 (React/Node)
- 5000, 5173 (Vite/Flask)
- 8000, 8080 (Django/Spring)
- 4200 (Angular)
- 9000 (Play)

## 4. Command Not Found

### Symptoms
- "command not found" errors
- Tools installed but not accessible
- Build scripts fail

### Diagnosis
```bash
# Check if command exists
which npm
which python3

# Check Homebrew installation
ls /opt/homebrew/bin/  # Apple Silicon
ls /usr/local/bin/     # Intel Mac
```

### Solutions

#### Homebrew Tools Not Found
**Problem:** Tools installed via Homebrew not accessible  
**Solution:**
```bash
# Verify Homebrew paths are included
ls /opt/homebrew/bin/your-tool

# Add to PATH if needed (in your shell profile)
export PATH="/opt/homebrew/bin:$PATH"
```

#### Custom Tools Location
**Problem:** Tools in non-standard locations  
**Solution:**
```bash
# Use EXTRA_EXEC_PATH
EXTRA_EXEC_PATH="/custom/tools/bin" \
./claude-code-sandbox-launcher.sh claude-code
```

#### Language Version Managers
**Problem:** nvm/rbenv/pyenv commands not found  
**Solution:** Source the initialization scripts first:
```bash
# In your shell before launching
source ~/.nvm/nvm.sh
nvm use 18
./claude-code-sandbox-launcher.sh claude-code
```

## 5. Git Operations Fail

### Symptoms
- Cannot clone repositories
- Push/pull operations fail
- Git config not found

### Diagnosis
```bash
# Check git config access
cat ~/.gitconfig

# Test git operation
git status
```

### Solutions

#### Git Config Not Found
**Problem:** .gitconfig not accessible  
**Note:** .gitconfig is allowed but .git-credentials is blocked  
**Solution:**
```bash
# Ensure git is configured
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

#### SSH Key Access Denied
**Problem:** Cannot use SSH keys for git  
**Solution:** Use HTTPS with tokens:
```bash
# Use HTTPS URLs instead of SSH
git clone https://github.com/user/repo.git

# Store credentials temporarily
git config --global credential.helper cache
```

## 6. Package Manager Issues

### Symptoms
- npm install fails
- pip packages won't install
- Cargo/gem/yarn errors

### Diagnosis
```bash
# Check cache directories
ls ~/.npm
ls ~/.cache/pip

# Test package manager
npm --version
pip --version
```

### Solutions

#### Cache Directory Access
**Problem:** Package manager cache not writable  
**Solution:** Cache directories should be writable. Check:
```bash
# Verify cache paths are set correctly
npm config get cache  # Should be ~/.npm
yarn config get cache # Should be ~/.yarn/cache
```

#### Global Package Installation
**Problem:** Cannot install global packages  
**Solution:** Install locally instead:
```bash
# Instead of global
npm install -g typescript  # Will fail

# Use local installation
npm install --save-dev typescript
npx tsc  # Run local version
```

## 7. Agent OS/PEER Pattern Issues

### Symptoms
- PEER commands fail
- NATS connection errors
- Agent OS scripts not found

### Diagnosis
```bash
# Check NATS connectivity
nc -zv localhost 4222

# Verify Agent OS directory
ls ~/.agent-os

# Test NATS operations
nats server ping
```

### Solutions

#### NATS Not Running
**Problem:** NATS server not started  
**Solution:**
```bash
# Start NATS server
nats-server -js

# Or with Docker
docker run -p 4222:4222 nats:latest -js
```

#### Agent OS Directory Missing
**Problem:** AGENT_OS_DIR not found  
**Solution:**
```bash
# Clone or create Agent OS structure
git clone [agent-os-repo] ~/.agent-os

# Or set correct path
AGENT_OS_DIR="/correct/path/.agent-os" \
./claude-code-sandbox-launcher.sh claude-code
```

## 8. Audit Logging Issues

### Symptoms
- No audit logs generated
- Cannot find log files
- Log directory permission errors

### Diagnosis
```bash
# Check if verbose mode is enabled
echo $SANDBOX_VERBOSE

# Look for audit directory
ls ~/dev/.sandbox-audit/

# Check permissions
ls -la ~/dev/.sandbox-audit/
```

### Solutions

#### Logs Not Created
**Problem:** Verbose mode not enabled  
**Solution:**
```bash
# Enable verbose mode
SANDBOX_VERBOSE="true" ./claude-code-sandbox-launcher.sh claude-code

# Or use flag
./claude-code-sandbox-launcher.sh --verbose claude-code
```

#### Cannot Write Logs
**Problem:** Audit directory not writable  
**Solution:**
```bash
# Create audit directory with correct permissions
mkdir -p ~/dev/.sandbox-audit
chmod 755 ~/dev/.sandbox-audit
```

## Performance Issues

### Symptoms
- Slow file operations
- High CPU usage
- Memory consumption

### Diagnosis
```bash
# Check if verbose logging is enabled
echo $SANDBOX_VERBOSE  # Should be "false" for performance

# Monitor sandbox process
top -pid $(pgrep sandbox-exec)
```

### Solutions

#### Verbose Logging Overhead
**Problem:** Audit logging slowing operations  
**Solution:**
```bash
# Disable verbose mode for normal use
SANDBOX_VERBOSE="false" ./claude-code-sandbox-launcher.sh claude-code
```

#### Large Directory Trees
**Problem:** DEV_WORKSPACE too broad  
**Solution:**
```bash
# Narrow the workspace scope
DEV_WORKSPACE="~/dev/specific-project" \
./claude-code-sandbox-launcher.sh claude-code
```

## Advanced Debugging

### Enable Maximum Verbosity

```bash
# Create debug wrapper
cat > debug-sandbox.sh << 'EOF'
#!/bin/bash
export SANDBOX_VERBOSE="true"
export DEV_WORKSPACE="${DEV_WORKSPACE:-$HOME/dev}"
export WORKING_DIR="${WORKING_DIR:-$(pwd)}"

echo "=== Sandbox Debug Info ==="
echo "DEV_WORKSPACE: $DEV_WORKSPACE"
echo "WORKING_DIR: $WORKING_DIR"
echo "AGENT_OS_DIR: ${AGENT_OS_DIR:-$HOME/.agent-os}"
echo "========================="

./claude-code-sandbox-launcher.sh --verbose "$@"
EOF

chmod +x debug-sandbox.sh
./debug-sandbox.sh claude-code
```

### Test Specific Permissions

```bash
# Test file read
sandbox-exec -f claude-code-sandbox.sb [params] \
  /bin/cat /path/to/test/file

# Test file write
sandbox-exec -f claude-code-sandbox.sb [params] \
  /usr/bin/touch /path/to/test/newfile

# Test network
sandbox-exec -f claude-code-sandbox.sb [params] \
  /usr/bin/nc -zv localhost 3000

# Test execution
sandbox-exec -f claude-code-sandbox.sb [params] \
  /bin/sh -c "echo 'Shell works'"
```

### Analyze Audit Logs

```bash
# Find all denials
grep "denied" ~/dev/.sandbox-audit/*/sandbox-*.log

# Find file operations
grep "file-" ~/dev/.sandbox-audit/*/sandbox-*.log

# Find network operations
grep "network" ~/dev/.sandbox-audit/*/sandbox-*.log

# Real-time monitoring
tail -f ~/dev/.sandbox-audit/*/sandbox-*.log
```

## Getting Help

If issues persist after trying these solutions:

1. **Collect Debug Information:**
```bash
# System info
uname -a
sw_vers

# Sandbox test
./claude-code-sandbox-launcher.sh --dry-run claude-code > debug.log 2>&1

# Recent audit logs
tail -n 100 ~/dev/.sandbox-audit/*/sandbox-*.log > audit.log
```

2. **Check Documentation:**
- [Security Requirements](../specs/2025-08-11-claude-code-sandbox-security/security-requirements.md)
- [Parameters Reference](./claude-code-sandbox-parameters.md)
- [Usage Guide](./claude-code-sandbox-launcher-usage.md)

3. **Common Workarounds:**
- Use broader DEV_WORKSPACE temporarily
- Disable sandbox for specific operations
- Run commands outside sandbox first
- Copy needed files into workspace

## Prevention Tips

1. **Start with test project** to verify configuration
2. **Use consistent directory structure** for all projects
3. **Set environment variables** in shell profile
4. **Keep sensitive files** outside DEV_WORKSPACE
5. **Review audit logs** periodically for unexpected access
6. **Document project-specific** requirements