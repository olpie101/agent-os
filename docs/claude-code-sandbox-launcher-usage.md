# Claude Code Sandbox Launcher Usage Guide

## Overview

The Claude Code Sandbox Launcher (`claude-code-sandbox-launcher.sh`) provides a secure way to run Claude Code with restricted file system access, implementing the principle of least privilege to protect sensitive system and personal files while maintaining full functionality for development tasks.

## Quick Start

### Basic Usage

```bash
# Run Claude Code with default settings
./claude-code-sandbox-launcher.sh claude-code

# Run with custom development workspace
DEV_WORKSPACE=/path/to/projects ./claude-code-sandbox-launcher.sh claude-code

# Test configuration without executing
./claude-code-sandbox-launcher.sh --dry-run claude-code
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `--help` | Display help message with usage information |
| `--dry-run` | Show what would be executed without running it |
| `--verbose` | Enable verbose output and audit logging |

## Environment Variables

The launcher accepts several environment variables to customize the sandbox behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `DEV_WORKSPACE` | `$HOME/dev` | Primary development directory with full read access |
| `WORKING_DIR` | Current directory | Working directory with read/write access |
| `AGENT_OS_DIR` | `$HOME/.agent-os` | Agent OS configuration directory |
| `NATS_URL` | `nats://localhost:4222` | NATS server URL for message queue operations |
| `NATS_CREDS` | None | Path to NATS credentials file (optional) |
| `SANDBOX_VERBOSE` | `false` | Enable verbose audit logging |
| `EXTRA_EXEC_PATH` | None | Additional executable path (optional) |

## Usage Examples

### Standard Development Setup

```bash
# Set up your development workspace
export DEV_WORKSPACE="$HOME/projects"
./claude-code-sandbox-launcher.sh claude-code
```

### Project-Specific Execution

```bash
# Work on a specific project
cd /path/to/my-project
WORKING_DIR=$(pwd) ./claude-code-sandbox-launcher.sh claude-code
```

### With NATS Integration

```bash
# Connect to custom NATS server
NATS_URL="nats://my-server:4222" \
NATS_CREDS="/path/to/creds.json" \
./claude-code-sandbox-launcher.sh claude-code
```

### Debug Mode with Verbose Logging

```bash
# Enable full audit logging for troubleshooting
./claude-code-sandbox-launcher.sh --verbose claude-code

# Or via environment variable
SANDBOX_VERBOSE=true ./claude-code-sandbox-launcher.sh claude-code
```

### Custom Tool Installation

```bash
# Add path for custom tools or language versions
EXTRA_EXEC_PATH="/usr/local/my-tools/bin" \
./claude-code-sandbox-launcher.sh claude-code
```

## Audit Logging

When verbose mode is enabled, the launcher creates detailed audit logs at:
```
${DEV_WORKSPACE}/.sandbox-audit/${PROJECT_NAME}/sandbox-YYYY-MM-DD.log
```

These logs capture:
- File access attempts (read/write)
- Network connections
- Process executions
- Permission denials

## Integration with Development Workflows

### Git Operations

The sandbox allows full git operations within your `WORKING_DIR`:
```bash
cd my-project
./claude-code-sandbox-launcher.sh claude-code
# Claude Code can now perform git operations in my-project/
```

### Package Management

NPM, Yarn, and pip operations are supported with appropriate cache access:
```bash
# Node.js development
cd my-node-app
./claude-code-sandbox-launcher.sh claude-code
# Claude Code can run npm install, npm test, etc.
```

### Build Tools

Make, CMake, and other build tools work within the sandbox:
```bash
cd my-c-project
./claude-code-sandbox-launcher.sh claude-code
# Claude Code can run make, compile, and test
```

## Troubleshooting

### Permission Denied Errors

If you encounter permission issues:
1. Ensure your project is within `DEV_WORKSPACE`
2. Check that `WORKING_DIR` is set correctly
3. Enable verbose mode to see detailed denial reasons

### Network Issues

For network-related problems:
1. Verify NATS_URL is accessible
2. Check firewall settings for required ports
3. Use verbose mode to see network access attempts

### Command Not Found

If executables aren't found:
1. Verify the tool is installed in standard locations
2. Use `EXTRA_EXEC_PATH` for custom installations
3. Check that Homebrew paths are configured correctly

## Best Practices

1. **Set DEV_WORKSPACE once**: Export it in your shell profile for consistency
2. **Use project directories**: Keep projects organized under DEV_WORKSPACE
3. **Enable verbose mode when debugging**: Helps identify permission issues
4. **Review audit logs regularly**: Understand what Claude Code is accessing
5. **Keep sensitive files outside DEV_WORKSPACE**: The sandbox explicitly blocks access to SSH keys, cloud credentials, etc.

## Security Notes

The sandbox provides protection by:
- Restricting file system access to development directories only
- Blocking access to sensitive files (.ssh, .aws, browser data, etc.)
- Limiting network access to standard and development ports
- Preventing execution of system-critical commands
- Logging all access attempts when verbose mode is enabled

For more details on security boundaries, see the [Security Requirements](../specs/2025-08-11-claude-code-sandbox-security/security-requirements.md) document.