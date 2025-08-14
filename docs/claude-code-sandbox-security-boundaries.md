# Claude Code Sandbox Security Boundaries

## Overview

This document details the security boundaries implemented in the Claude Code Sandbox, explaining what is accessible, what is restricted, and the rationale behind each decision. The sandbox follows the principle of least privilege to protect sensitive data while maintaining development functionality.

## Security Philosophy

The Claude Code Sandbox implements defense in depth through:

1. **Default Deny**: All access is denied by default
2. **Explicit Allow Lists**: Only specifically permitted operations are allowed
3. **Layered Restrictions**: Multiple security layers prevent bypass attempts
4. **Audit Capability**: All operations can be logged for review

## File System Boundaries

### Allowed Read Access

#### Development Workspace (`DEV_WORKSPACE`)
**Scope:** Full recursive read access  
**Rationale:** Developers need to read project files, dependencies, and related code  
**Risk Level:** Low - Limited to development files only  

#### System Binaries and Libraries
**Paths:** `/usr`, `/bin`, `/sbin`, `/System`, `/Library/Frameworks`  
**Rationale:** Required for executing development tools and system commands  
**Risk Level:** Low - Read-only access to public system files  

#### Package Managers
**Paths:** `/opt/homebrew`, `/usr/local`, npm/yarn/pip caches  
**Rationale:** Development tools installation and package management  
**Risk Level:** Low - Standard development tool locations  

#### Configuration Files (Limited)
**Allowed:**
- `.gitconfig` - Git operations
- `.netrc` - Network authentication for tools
- Language version managers (`.nvm`, `.rbenv`, etc.)

**Rationale:** Essential for development tool operation  
**Risk Level:** Medium - Contains some configuration but not credentials  

### Allowed Write Access

#### Working Directory (`WORKING_DIR`)
**Scope:** Full read/write/delete access  
**Rationale:** Primary location for code modifications  
**Risk Level:** Low - User explicitly specifies this directory  

#### Temporary Directories
**Paths:** `/tmp`, `/var/tmp`, `/private/tmp`  
**Rationale:** Build processes, test outputs, temporary files  
**Risk Level:** Low - System-managed temporary space  

#### Package Caches
**Paths:** `~/.npm`, `~/.yarn`, `~/.cache`  
**Rationale:** Package managers need to cache downloads  
**Risk Level:** Low - Only package data, not credentials  

#### Audit Logs
**Path:** `${DEV_WORKSPACE}/.sandbox-audit/`  
**Rationale:** Security logging when verbose mode enabled  
**Risk Level:** Low - Append-only audit trail  

### Explicitly Denied Access

#### SSH Keys and Certificates
**Path:** `~/.ssh/`  
**Rationale:** Prevents unauthorized server access and identity theft  
**Risk Level:** Critical - Would allow system compromise  
**Bypass Prevention:** Explicit deny rule before allow rules  

#### Cloud Provider Credentials
**Paths:** `~/.aws/`, `~/.gcp/`, `~/.azure/`, related config  
**Rationale:** Prevents unauthorized cloud resource access  
**Risk Level:** Critical - Could lead to massive cloud bills or data breach  
**Bypass Prevention:** Multiple path patterns to catch all variants  

#### Browser Data
**Paths:** Chrome, Firefox, Safari, Edge profiles  
**Rationale:** Contains cookies, passwords, session tokens  
**Risk Level:** High - Personal data and authenticated sessions  
**Bypass Prevention:** Covers all major browsers and profile locations  

#### Password Managers
**Paths:** Keychain, 1Password, Bitwarden, etc.  
**Rationale:** Master passwords and all stored credentials  
**Risk Level:** Critical - Complete identity compromise possible  
**Bypass Prevention:** Explicit paths for all common managers  

#### Shell History
**Files:** `.bash_history`, `.zsh_history`, etc.  
**Rationale:** May contain passwords typed in commands  
**Risk Level:** Medium - Potential credential exposure  
**Bypass Prevention:** All common shell history files  

#### Container and Orchestration
**Paths:** `.docker/`, `.kube/`  
**Rationale:** Container registry credentials and cluster access  
**Risk Level:** High - Infrastructure access  
**Bypass Prevention:** Directory-level blocking  

## Network Boundaries

### Allowed Connections

#### Standard Web Ports
**Ports:** 80 (HTTP), 443 (HTTPS)  
**Rationale:** Package downloads, API calls, web services  
**Risk Level:** Low - Standard web traffic  

#### Development Servers
**Ports:** 3000, 3001, 5000, 5173, 8000, 8080, 9000  
**Rationale:** Local development servers and hot reload  
**Risk Level:** Low - Local development only  

#### Version Control
**Port:** 22 (SSH for Git)  
**Rationale:** Git operations over SSH  
**Risk Level:** Medium - Requires existing SSH keys (which are blocked)  

#### NATS Message Queue
**Port:** 4222  
**Rationale:** Agent OS PEER pattern operations  
**Risk Level:** Low - Local message queue  

### Network Restrictions

- No access to privileged ports (<1024 except specified)
- No raw socket creation
- No network interface manipulation
- DNS resolution allowed for development needs

## Process Execution Boundaries

### Allowed Executables

#### System Shells
**Commands:** `sh`, `bash`, `zsh`  
**Rationale:** Script execution and command interpretation  
**Risk Level:** Medium - Can run other commands  

#### Development Tools
**Location:** Within `DEV_WORKSPACE`  
**Rationale:** Running project scripts and built binaries  
**Risk Level:** Medium - User-controlled code  

#### Package Managers
**Commands:** `npm`, `yarn`, `pip`, `gem`, `cargo`  
**Rationale:** Dependency management  
**Risk Level:** Medium - Can download arbitrary packages  

#### Build Tools
**Commands:** `make`, `cmake`, `gcc`, `go`, `rust`  
**Rationale:** Compilation and building  
**Risk Level:** Low - Output restricted to WORKING_DIR  

### Execution Restrictions

- No sudo or privilege escalation
- No system service manipulation
- No kernel module loading
- No system configuration changes

## Security Trade-offs

### Convenience vs Security Decisions

1. **`.gitconfig` Access**
   - **Trade-off:** Allowed despite potential for credential helpers
   - **Mitigation:** `.git-credentials` still blocked
   - **Justification:** Essential for git operations

2. **`.netrc` Access**
   - **Trade-off:** Contains plaintext passwords for some services
   - **Mitigation:** Limited to development-related services
   - **Justification:** Required for many development tools

3. **Package Manager Execution**
   - **Trade-off:** Can install arbitrary code
   - **Mitigation:** Caches isolated, system packages protected
   - **Justification:** Core development requirement

## Bypass Prevention Strategies

### Path Traversal Protection
- No relative path resolution outside boundaries
- Symlinks followed but destination checked
- Parent directory access blocked at boundary

### Environment Variable Injection
- Parameters validated before use
- No shell expansion in parameters
- Paths canonicalized before checking

### Race Condition Prevention
- Permissions checked at access time
- No TOCTOU vulnerabilities in permission checks
- Atomic operations where possible

## Monitoring and Compliance

### Audit Logging
When `VERBOSE_MODE` is enabled:
- All file access attempts logged
- Network connections recorded
- Process executions tracked
- Permission denials highlighted

### Compliance Verification
Regular testing should verify:
- Sensitive directories remain inaccessible
- New bypass techniques are blocked
- Development workflows still function
- Audit logs capture violations

## Security Incident Response

If a security boundary is breached:

1. **Immediate:** Disable sandbox execution
2. **Investigate:** Review audit logs for access patterns
3. **Patch:** Update sandbox rules to prevent recurrence
4. **Verify:** Test that legitimate access still works
5. **Document:** Record incident and resolution

## Future Considerations

### Potential Enhancements
- Encrypted credential storage with controlled access
- Time-based access restrictions
- Per-project permission profiles
- Integration with system security frameworks

### Known Limitations
- Cannot prevent malicious code in dependencies
- Network egress filtering is limited
- Some development tools require broader access
- Performance impact when verbose logging enabled

## Conclusion

The Claude Code Sandbox provides strong security boundaries that protect sensitive data while enabling productive development. The explicit deny rules for critical paths combined with restricted allow lists create a robust security posture that follows the principle of least privilege.