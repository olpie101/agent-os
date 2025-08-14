# Security Requirements and Boundaries

> Created: 2025-08-11
> Purpose: Define security boundaries for Claude Code sandbox
> Status: Complete

## 1.1 Sensitive Directories That Must Be Protected

The following directories contain sensitive information and must be explicitly denied access:

### Authentication & Credentials
- `~/.ssh/` - SSH keys for server access and git authentication
- `~/.aws/` - AWS credentials and configuration
- `~/.gcp/` - Google Cloud Platform credentials
- `~/.azure/` - Azure credentials
- `~/.gitconfig` - Git configuration with potential tokens
- `~/.git-credentials` - Stored git credentials
- `~/.config/gh/` - GitHub CLI authentication
- `~/.gnupg/` - GPG keys

### System & Infrastructure
- `~/.kube/` - Kubernetes configurations and certificates
- `~/.docker/` - Docker credentials and configs
- `~/.android/` - Android SDK credentials
- `~/.gradle/` - Gradle credentials

### History & Personal Data
- `~/.bash_history` - Command history
- `~/.zsh_history` - Z shell history
- `~/.password-store/` - Password manager data
- `~/Library/Keychains/` - macOS keychain
- Browser profiles with saved passwords

## 1.2 Minimum Necessary System Directories

Claude Code requires access to these system directories for normal operation:

### Core System Paths
- `/usr/` - System utilities and libraries
- `/bin/` - Essential command binaries
- `/sbin/` - System binaries
- `/System/` - macOS system files
- `/Library/Frameworks/` - macOS frameworks

### Development Tools
- `/opt/homebrew/` - Homebrew installations (Apple Silicon)
- `/usr/local/` - Traditional Unix installations (Intel Macs)
- `/tmp/` and `/var/tmp/` - Temporary file operations

## 1.3 Required Development Tool Paths

### Homebrew Locations
- `/opt/homebrew/bin/` - Homebrew binaries
- `/opt/homebrew/opt/` - Formula-specific directories (e.g., coreutils)
- `/opt/homebrew/Cellar/` - Versioned installations
- `/usr/local/bin/` - Intel Mac Homebrew

### Language Version Managers (Read-Only)
- `~/.nvm/` - Node Version Manager
- `~/.rbenv/` - Ruby environment
- `~/.pyenv/` - Python environment
- `~/.cargo/` - Rust toolchain
- `~/.rustup/` - Rust version manager
- `~/.bun/` - Bun runtime

### Claude & Agent OS Configuration
- `~/.claude/` - Claude configuration and CLAUDE.md
- `~/.claude.json` - Claude settings file
- `~/.agent-os/` - Agent OS standards and instructions

## 1.4 Package Manager Cache Locations Needing Write Access

The following directories need write access for package operations:

- `~/.npm/` - NPM global packages and cache
- `~/.cache/` - General application caches
- `~/.bundle/` - Ruby bundler cache
- `~/.cargo/registry/` - Rust package registry
- `~/.gem/` - Ruby gems

## 1.5 Threat Model for Path Traversal and Escape Attempts

### Attack Vectors to Prevent

#### Path Traversal
- **Threat**: Using `../` sequences to escape allowed directories
- **Mitigation**: Sandbox validates resolved paths at kernel level
- **Example**: Attempting `DEV_WORKSPACE/../.ssh/` would be blocked

#### Symlink Attacks
- **Threat**: Creating symlinks pointing to sensitive directories
- **Mitigation**: Sandbox follows symlinks and validates final destination
- **Example**: Symlink from project to `~/.aws/` would be blocked

#### Environment Variable Injection
- **Threat**: Manipulating parameters to gain broader access
- **Mitigation**: Parameters validated before sandbox instantiation
- **Example**: Setting `DEV_WORKSPACE=/` would be rejected

#### Directory Confusion
- **Threat**: Creating directories with similar names to bypass restrictions
- **Mitigation**: Explicit deny rules take precedence over allow rules
- **Example**: Creating `.ssh/` within project doesn't grant HOME `.ssh/` access

### Defense Layers

1. **Parameter Validation** - Launcher script validates inputs
2. **Explicit Deny Rules** - Sensitive directories blocked even if in allowed paths
3. **Kernel-Level Enforcement** - macOS sandbox enforces at system level
4. **Audit Logging** - All access attempts logged for review

## 1.6 Security Principles and Access Control Strategy

### Core Principles

#### Principle of Least Privilege
- Grant only minimum necessary access for development
- Start restrictive, expand only when justified
- Write access limited to current working directory only

#### Defense in Depth
- Multiple layers of protection
- Allow rules define permitted access
- Deny rules explicitly block sensitive areas
- Audit logging tracks all attempts

#### Explicit Over Implicit
- Be explicit about what's allowed
- No blanket filesystem access
- Each permission must be justified

#### Fail Secure
- Default to denying access when uncertain
- Blocked access logged for review
- No silent failures

### Access Control Model

#### Read Permissions
- **DEV_WORKSPACE**: All development projects (read-only)
- **WORKING_DIR**: Current project directory
- **System Paths**: Required for tool execution
- **Specific HOME Subdirs**: Only as needed (.agent-os, .claude, version managers)

#### Write Permissions
- **WORKING_DIR**: Current project only
- **Temporary Directories**: /tmp, /var/tmp
- **Package Caches**: As required for package managers
- **Audit Logs**: Project-specific audit directory

#### Execute Permissions
- **System Commands**: Core Unix utilities
- **Homebrew Tools**: Development tools
- **DEV_WORKSPACE**: For compiled binaries
- **Agent OS Scripts**: For automation

#### Network Permissions
- **Standard Ports**: 80, 443, 22
- **Dev Server Ports**: 3000-3999, 5000-5999, 8000-8999
- **NATS**: Configurable via NATS_URL parameter

### Audit Strategy

- **Location**: Project-specific directories for easy correlation
- **Format**: ISO 8601 timestamps with clear action/result
- **Rotation**: Daily with 7-day retention
- **Monitoring**: Review blocked attempts for false positives

---

This document defines the security boundaries for the Claude Code sandbox implementation. All subsequent implementation must adhere to these requirements.