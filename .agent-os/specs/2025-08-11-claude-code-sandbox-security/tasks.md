# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-11-claude-code-sandbox-security/spec.md

> Created: 2025-08-11
> Status: Ready for Implementation

## Tasks

> **Note:** Tasks marked with 🔧 require manual intervention for testing/execution

- [x] 1. Define Security Requirements and Boundaries
  - [x] 1.1 Document sensitive directories that must be protected (.ssh, .aws, .gitconfig, etc.)
  - [x] 1.2 Define minimum necessary system directories for Claude Code operation
  - [x] 1.3 Map required development tool paths (Homebrew, language managers, etc.)
  - [x] 1.4 Identify package manager cache locations needing write access
  - [x] 1.5 Create threat model for path traversal and escape attempts
  - [x] 1.6 Document security principles and access control strategy

- [x] 2. Create Launcher Script for Sandbox
  - [x] 2.1 Write tests for launcher script functionality
  - [x] 2.2 Implement environment variable detection and defaults
  - [x] 2.3 Create path escaping logic for audit log directories
  - [x] 2.4 Implement parameter passing to sandbox-exec
  - [x] 2.5 Add audit directory creation if not exists
  - [x] 2.6 🔧 Verify launcher script tests pass

- [x] 3. Environment Variable and Parameter Implementation
  - [x] 3.1 Write tests for DEV_WORKSPACE parameter handling
  - [x] 3.2 Replace `(param "HOME")` with `(param "DEV_WORKSPACE")` in read permissions
  - [x] 3.3 Implement WORKING_DIR and AGENT_OS_DIR parameters
  - [x] 3.4 Implement NATS_URL and NATS_CREDS parameters
  - [x] 3.5 Create fallback logic for undefined parameters
  - [x] 3.6 Implement EXTRA_EXEC_PATH conditional inclusion
  - [x] 3.7 🔧 Verify all parameter tests pass

- [x] 4. File System Read Access Restrictions
  - [x] 4.1 Write tests for restricted read permissions
  - [x] 4.2 Remove `(subpath "/")` and replace with specific system paths
  - [x] 4.3 Implement explicit allow list: /usr, /bin, /sbin, /System, /Library/Frameworks
  - [x] 4.4 Add /opt/homebrew paths for Homebrew users
  - [x] 4.5 Restrict HOME access to specific subdirectories (.agent-os, .nvm, etc.)
  - [x] 4.6 Add language version manager paths (read-only)
  - [x] 4.7 🔧 Verify read restriction tests pass

- [x] 5. File System Write Access Restrictions
  - [x] 5.1 Write tests for write permission boundaries
  - [x] 5.2 Restrict write to WORKING_DIR only (not DEV_WORKSPACE)
  - [x] 5.3 Add package manager cache paths for write access
  - [x] 5.4 Ensure tmp directories remain writable
  - [x] 5.5 Add project-specific audit log path for write
  - [x] 5.6 🔧 Verify write permission tests pass

- [x] 6. Explicit Deny Rules for Sensitive Directories
  - [x] 6.1 Write tests to verify sensitive directories are blocked
  - [x] 6.2 Implement deny rules for .ssh directory
  - [x] 6.3 Implement deny rules for cloud credentials (.aws, .gcp, .azure)
  - [x] 6.4 Implement deny rules for git credentials and shell history
  - [x] 6.5 Implement deny rules for .kube and .android directories
  - [x] 6.6 Add deny rules for browser profiles and password stores
  - [x] 6.7 🔧 Verify all deny rule tests pass (see testing-notes.md for full test requirements)

- [x] 7. Executable Permissions Configuration
  - [x] 7.1 Write tests for executable permissions
  - [x] 7.2 Add core system commands (sh, bash, zsh, etc.)
  - [x] 7.3 Add shell utilities (test, dirname, basename)
  - [x] 7.4 Configure Homebrew executable paths
  - [x] 7.5 Enable execution within DEV_WORKSPACE
  - [x] 7.6 Enable Agent OS scripts execution
  - [x] 7.7 🔧 Verify executable permission tests pass

- [ ] 8. Network Configuration ⚠️ INCOMPLETE - DNS resolution issues with curl/wget
  - [x] 8.1 Write tests for network permissions
  - [x] 8.2 Implement standard ports (80, 443, 22)
  - [x] 8.3 Add common development server ports (3000, 3001, 5000, 5173, 8000, 9000)
  - [x] 8.4 Configure NATS access for localhost:4222
  - [x] 8.5 Add specific dev ports (4200, 8080)
  - [ ] 8.6 🔧 Verify network configuration tests pass ⚠️ Partial: dig works, curl/wget DNS fails - needs audit logging for diagnosis

- [x] 9. Audit Logging Implementation
  - [x] 9.1 Write tests for audit logging functionality
  - [x] 9.2 Implement project-specific audit directories
  - [x] 9.3 Configure audit log format (ISO 8601 timestamps)
  - [x] 9.4 Create log rotation script for daily rotation
  - [x] 9.5 Implement verbose mode logging when enabled
  - [x] 9.6 🔧 Verify audit logging tests pass

- [ ] 10. Integration Testing and Validation
  - [ ] 10.1 Write integration tests for common workflows
  - [ ] 10.2 🔧 Test git operations within WORKING_DIR
  - [ ] 10.3 🔧 Test npm/yarn/pip package operations
  - [ ] 10.4 🔧 Test make and build tool operations
  - [ ] 10.5 🔧 Test NATS KV operations for PEER pattern
  - [ ] 10.6 🔧 Test compiled binary execution in DEV_WORKSPACE
  - [ ] 10.7 🔧 Test that SSH key access is properly blocked
  - [ ] 10.8 🔧 Test that cloud credentials are inaccessible
  - [ ] 10.9 🔧 Verify all integration tests pass

- [x] 11. Documentation and Deployment
  - [x] 11.1 Create launcher script usage documentation
  - [x] 11.2 Document all parameters and their defaults
  - [x] 11.3 Document security boundaries and rationale
  - [x] 11.4 Create migration guide from old to new configuration (skipped - not needed)
  - [x] 11.5 Add examples for common development setups
  - [x] 11.6 Create troubleshooting guide for access issues
  - [x] 11.7 Document future configuration file approach
  - [x] 11.8 Package launcher script and sandbox profile for deployment
