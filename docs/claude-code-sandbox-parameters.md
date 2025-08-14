# Claude Code Sandbox Parameters Reference

## Overview

This document provides a comprehensive reference for all parameters used by the Claude Code Sandbox security profile. These parameters control file system access, network permissions, and audit logging behavior.

## Core Parameters

### DEV_WORKSPACE

**Type:** Directory path  
**Default:** `$HOME/dev`  
**Purpose:** Primary development workspace with full read access  
**Access Level:** Read-only  

The DEV_WORKSPACE parameter defines the root directory for all development projects. Claude Code has read access to this entire directory tree but cannot modify files outside of WORKING_DIR.

**Example:**
```bash
DEV_WORKSPACE="/Users/john/projects"
```

### WORKING_DIR

**Type:** Directory path  
**Default:** Current working directory (`pwd`)  
**Purpose:** Active project directory with read/write access  
**Access Level:** Read/Write  

The WORKING_DIR parameter specifies where Claude Code can create, modify, and delete files. This should be set to your current project directory.

**Example:**
```bash
WORKING_DIR="/Users/john/projects/my-app"
```

### AGENT_OS_DIR

**Type:** Directory path  
**Default:** `$HOME/.agent-os`  
**Purpose:** Agent OS configuration and scripts  
**Access Level:** Read/Execute  

Contains Agent OS instructions, standards, and executable scripts that Claude Code needs to access for following development workflows.

**Example:**
```bash
AGENT_OS_DIR="/Users/john/.agent-os"
```

### HOME

**Type:** Directory path  
**Default:** User's home directory  
**Purpose:** Reference point for user-specific paths  
**Access Level:** Restricted (specific subdirectories only)  

Used internally to construct paths to configuration files and tools. Direct access to HOME is restricted; only specific subdirectories are accessible.

**Accessible HOME subdirectories:**
- `.agent-os/` - Agent OS configuration
- `.nvm/` - Node Version Manager
- `.npm/` - NPM cache (write access)
- `.yarn/` - Yarn cache (write access)
- `.cache/` - General cache directory
- `.config/` - Limited configuration files
- `.netrc` - Network credentials (required for some tools)
- `.CFUserTextEncoding` - Text encoding settings
- `.gitconfig` - Git configuration (read-only)

## Network Parameters

### NATS_URL

**Type:** URL string  
**Default:** `nats://localhost:4222`  
**Purpose:** NATS message queue server connection  
**Required:** No (uses default if not specified)  

Specifies the NATS server URL for message queue operations used by Agent OS PEER pattern and other features.

**Example:**
```bash
NATS_URL="nats://my-server.local:4222"
```

### NATS_CREDS

**Type:** File path  
**Default:** Empty (no credentials)  
**Purpose:** NATS authentication credentials  
**Required:** No  

Path to NATS credentials file for authenticated connections.

**Example:**
```bash
NATS_CREDS="/path/to/nats.creds"
```

## Logging Parameters

### AUDIT_LOG_PATH

**Type:** Directory path  
**Default:** `${DEV_WORKSPACE}/.sandbox-audit/${PROJECT_NAME}`  
**Purpose:** Audit log storage location  
**Access Level:** Write  

Directory where sandbox audit logs are written when verbose mode is enabled.

**Example:**
```bash
AUDIT_LOG_PATH="/var/log/claude-code-sandbox"
```

### VERBOSE_MODE

**Type:** Boolean string  
**Default:** `"false"`  
**Purpose:** Enable detailed audit logging  
**Values:** `"true"` or `"false"`  

When enabled, the sandbox logs all file access attempts, network connections, and process executions.

**Example:**
```bash
VERBOSE_MODE="true"
```

## Optional Parameters

### EXTRA_EXEC_PATH

**Type:** Directory path  
**Default:** Empty (not set)  
**Purpose:** Additional executable directory  
**Required:** No  

Allows specification of an additional directory containing executables that Claude Code should be able to run. Useful for custom tool installations.

**Example:**
```bash
EXTRA_EXEC_PATH="/usr/local/custom-tools/bin"
```

## Parameter Validation

The sandbox performs the following validations:

1. **Directory Existence**: DEV_WORKSPACE and WORKING_DIR must exist
2. **Path Containment**: WORKING_DIR should be within or equal to DEV_WORKSPACE for optimal security
3. **Write Permissions**: AUDIT_LOG_PATH must be writable if VERBOSE_MODE is enabled
4. **URL Format**: NATS_URL must be a valid URL if specified
5. **File Existence**: NATS_CREDS file must exist if specified

## Parameter Precedence

Parameters are resolved in the following order:
1. Command-line arguments (highest priority)
2. Environment variables
3. Default values (lowest priority)

## Security Implications

### Expanding DEV_WORKSPACE

Setting DEV_WORKSPACE to a broad directory (e.g., `$HOME`) reduces security by granting read access to more files. Keep it focused on actual development directories.

### WORKING_DIR Outside DEV_WORKSPACE

While allowed, having WORKING_DIR outside DEV_WORKSPACE means Claude Code won't be able to read related project files, potentially limiting functionality.

### VERBOSE_MODE Performance

Enabling verbose logging impacts performance and creates large log files. Use only for debugging and disable in production use.

### EXTRA_EXEC_PATH Risks

Adding executable paths increases the attack surface. Only add trusted, necessary paths and avoid system directories.

## Common Configurations

### Standard Development
```bash
DEV_WORKSPACE="$HOME/dev"
WORKING_DIR="$HOME/dev/my-project"
SANDBOX_VERBOSE="false"
```

### Restricted Project Access
```bash
DEV_WORKSPACE="/specific/project"
WORKING_DIR="/specific/project"
SANDBOX_VERBOSE="false"
```

### Debug Mode
```bash
DEV_WORKSPACE="$HOME/dev"
WORKING_DIR="$(pwd)"
SANDBOX_VERBOSE="true"
```

### With Custom Tools
```bash
DEV_WORKSPACE="$HOME/dev"
WORKING_DIR="$(pwd)"
EXTRA_EXEC_PATH="/opt/custom-compiler/bin"
```

## Troubleshooting Parameters

If Claude Code cannot access expected files:
1. Verify DEV_WORKSPACE includes the files
2. Check WORKING_DIR for write operations
3. Enable VERBOSE_MODE to see denials
4. Review AUDIT_LOG_PATH for detailed logs

If network operations fail:
1. Check NATS_URL is correct
2. Verify NATS_CREDS if authentication is required
3. Enable VERBOSE_MODE to see network denials

If commands aren't found:
1. Check standard paths are accessible
2. Set EXTRA_EXEC_PATH for custom installations
3. Verify executables are in allowed directories