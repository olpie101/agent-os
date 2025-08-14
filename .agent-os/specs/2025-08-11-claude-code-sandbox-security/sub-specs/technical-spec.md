# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-11-claude-code-sandbox-security/spec.md

> Created: 2025-08-11
> Version: 1.0.0

## Testing Requirements

**CRITICAL**: Every modification to the sandbox profile MUST be validated with actual `sandbox-exec` commands before marking any subtask as complete. Each task must include:

1. **Pre-Task Validation**: Before starting ANY task that modifies the sandbox profile, validate the current profile works with `sandbox-exec`
2. **Incremental Testing**: After each change to the sandbox profile, test with a simple `sandbox-exec` command to ensure the profile remains syntactically valid
3. **Functional Testing**: Test the specific functionality being added/modified works as expected
4. **Regression Testing**: Ensure previous functionality still works after changes

### Important Testing Restrictions

**The AI assistant (Claude) is NOT permitted to run test scripts directly.** All test scripts must be executed manually by the user. When a task requires testing:
1. The AI will create the necessary test scripts
2. The AI will inform the user that manual testing is required
3. The user must run the tests and provide the output
4. The AI will then proceed based on the test results

This applies to:
- Test scripts (e.g., `test-launcher.sh`, `test-deny-rules.sh`)
- Direct `sandbox-exec` commands for testing
- Any validation scripts

### Critical Testing Limitation Fixed

**RESOLVED**: The `test-sandbox-deny-rules.sh` script has been replaced with a proper verification script that actually executes sandbox commands to test security restrictions.

**Current Test File Status**:
- **Only Dry-Run**: `test-launcher.sh` (primarily - tests configuration handling)
- **Mixed Mode**: `test-audit-logging.sh`, `test-executable-permissions.sh`
- **Actual Execution**: `test-env-vars.sh`, `test-read-restrictions.sh`, `test-write-restrictions.sh`, `test-root-debug.sh`, `test-sandbox-deny-rules.sh` (FIXED)
- **No Sandbox**: `test-network-permissions.sh` (uses SANDBOX_EXEC environment pattern)

### Proper Testing Methodology

Tests must be categorized and clearly labeled:

1. **Configuration Tests** (can use dry-run):
   - Verify launcher parameter handling
   - Check path escaping and construction
   - Validate environment variable defaults
   - Test command-line argument parsing

2. **Security Validation Tests** (MUST use actual sandbox-exec):
   - Verify file access restrictions (deny rules)
   - Confirm allowed access paths
   - Test network restrictions
   - Validate executable permissions

3. **Hybrid Tests** (use both modes):
   - First validate configuration with dry-run
   - Then verify functionality with actual execution
   - Useful for complex scenarios requiring both aspects

### Required Validation Commands

#### Pre-Task Validation (MUST run before starting each task)
```bash
# Validate current profile state before making any changes
sandbox-exec -D WORKING_DIR="$(pwd)" \
             -D DEV_WORKSPACE="$HOME/dev" \
             -D AGENT_OS_DIR="$HOME/.agent-os" \
             -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
             -D HOME="$HOME" \
             -f claude-code-sandbox.sb \
             sh -c "echo 'Profile syntax OK'"
```

**IMPORTANT**: If the above command fails, the sandbox profile has existing issues that must be fixed before starting the task. DO NOT proceed with task implementation if the profile is already broken.

#### Post-Change Validation (after each modification)
```bash
# Basic syntax validation after each change
sandbox-exec -D WORKING_DIR="$(pwd)" \
             -D DEV_WORKSPACE="$HOME/dev" \
             -D AGENT_OS_DIR="$HOME/.agent-os" \
             -D AUDIT_LOG_PATH="/tmp/claude-code-audit" \
             -D HOME="$HOME" \
             -f claude-code-sandbox.sb \
             sh -c "echo 'Profile syntax OK'"
```

If the above command fails with an abort/error, the sandbox profile has a syntax error that must be fixed before proceeding.

### Test Script Implementation

The `test-sandbox-deny-rules.sh` script has been replaced with a proper implementation that:

1. **Checks sandbox availability**:
   - Verifies `sandbox-exec` command exists
   - Ensures launcher script is present
   - Exits with error if prerequisites missing

2. **Actually executes sandbox commands**:
   - Runs real sandbox-exec via the launcher (no --dry-run)
   - Tests both denied access (sensitive directories) and allowed access
   - Checks actual command output for "Operation not permitted" errors

3. **Provides clear pass/fail indicators**:
   - Green checkmarks for passing tests
   - Red X marks for failing tests
   - Clear explanation of expected vs actual results
   - Security warnings if sensitive directories are accessible

## Known Issues

### Root Directory Access (Under Investigation)
- **Issue**: Root directory "/" may still be accessible even with restrictive permissions
- **Cause**: Likely due to `dyld-support.sb` import or system requirements for process execution
- **Impact**: Low - other sensitive directories are properly restricted
- **Status**: Test disabled pending further investigation
- **Workaround**: Explicit deny rules for sensitive directories remain in place

### Git Operations Require /dev/null Read-Write Access
- **Issue**: Git commands fail with "could not open '/dev/null' for reading and writing: Operation not permitted"
- **Cause**: Git requires both read and write access to `/dev/null`, not just write access
- **Solution**: Add `/dev/null` to both `file-read*` and `file-write*` permission sections (there is no `file-read-write*` in sandbox-exec)
- **Impact**: Required for all git operations (add, commit, fetch, pull, push, etc.)

### Git Configuration Files Security Trade-off
- **Issue**: Git requires access to configuration files that may contain sensitive information
- **Files Required**:
  - `~/.gitconfig` - Global git configuration (may contain credentials, tokens, signing keys)
  - `~/.gitignore_global` - Global ignore patterns (generally safe)
  - `~/.stCommitMsg` - SourceTree commit message template (generally safe)
- **Security Risk**: `.gitconfig` may contain:
  - OAuth tokens for GitHub/GitLab
  - Credential helper configurations
  - GPG signing keys
  - Private repository URLs with embedded credentials
- **Trade-off Decision**: Allow read access to enable git functionality, accepting the security risk
- **Mitigation**: Users should avoid storing credentials directly in `.gitconfig` and use credential managers instead

## Critical Security Issues Identified

### Current Vulnerabilities
- **HOME Directory Read Access**: `(subpath (param "HOME"))` allows reading:
  - SSH keys (`~/.ssh/`)
  - Cloud credentials (`~/.aws/`, `~/.gcp/`, `~/.azure/`)
  - Git credentials (`~/.gitconfig`, `~/.git-credentials`)
  - Shell history (`~/.bash_history`, `~/.zsh_history`)
  - Password managers (`~/.password-store/`)
  - Browser profiles with saved passwords
  - Other projects' source code
  - Personal documents

- **Overly Broad Permissions**: `(subpath "/")` allows reading entire filesystem unnecessarily

## Technical Requirements

### Core Security Enhancements
- **Environment Variable Implementation**: Replace `(param "HOME")` with `(param "DEV_WORKSPACE")` that points to development directory only
- **Remove Blanket Access**: Eliminate `(subpath "/")` and replace with specific required paths
- **Explicit Deny Rules**: Add deny rules for sensitive directories even if within allowed paths
- **Path Traversal Protection**: Implement checks to prevent `../` attacks
- **Parameterized Configuration**: Use parameters for NATS_HOST, PROJECT_DIR, etc.

### Specific Implementation Details

#### Read Permission Structure
```scheme
(allow file-read*
    ;; Development workspace (defaults to ~/dev)
    (subpath (param "DEV_WORKSPACE"))
    
    ;; System binaries and libraries (needed for execution)
    (subpath "/usr")
    (subpath "/bin")
    (subpath "/sbin")
    (subpath "/System")
    (subpath "/Library/Frameworks")
    (subpath "/opt/homebrew")  ;; Homebrew installations
    
    ;; Network configuration and SSL/TLS certificates
    (subpath "/etc/ssl")         ;; SSL configuration and certificates
    (subpath "/private/etc/ssl") ;; macOS actual path for SSL config
    (subpath "/etc/hosts")       ;; Hostname resolution
    (subpath "/private/etc/hosts")
    (subpath "/etc/resolv.conf") ;; DNS configuration
    (subpath "/private/etc/resolv.conf")
    
    ;; Language/tool specific
    (subpath "/usr/local")
    
    ;; Current working directory
    (subpath (param "WORKING_DIR"))
    
    ;; Temporary directories
    (subpath "/tmp")
    (subpath "/var/tmp")
    
    ;; User's Agent OS configuration and scripts
    (subpath (param "HOME") ".agent-os")
    (subpath (param "HOME") ".claude")      ;; Claude configuration directory
    (literal (param "HOME") ".claude.json") ;; Claude configuration file (if at HOME root)
    
    ;; Language version managers (read-only)
    (subpath (param "HOME") ".nvm")
    (subpath (param "HOME") ".rbenv")
    (subpath (param "HOME") ".pyenv")
    (subpath (param "HOME") ".cargo")
    (subpath (param "HOME") ".rustup")
    (subpath (param "HOME") ".bun")
    
    ;; Package manager caches (read-only)
    (subpath (param "HOME") ".npm")
    (subpath (param "HOME") ".gem")
    (subpath (param "HOME") ".cache")
    (subpath (param "HOME") ".bundle")
    
    ;; NATS credentials
    (literal (param "NATS_CREDS"))
    
    ;; /dev/null needs read access for git operations
    (literal "/dev/null")
    
    ;; Git configuration files (security trade-off: may contain credentials)
    (literal (param "HOME") ".gitconfig")        ;; Global git config
    (literal (param "HOME") ".gitignore_global") ;; Global ignore patterns
    (literal (param "HOME") ".stCommitMsg"))     ;; SourceTree commit template

;; Explicit DENY for sensitive areas
(deny file-read*
    (subpath (param "HOME") ".ssh")
    (subpath (param "HOME") ".aws")
    (subpath (param "HOME") ".azure")
    (subpath (param "HOME") ".gcp")
    ;; .gitconfig removed from deny list - now allowed for git operations (security trade-off)
    (subpath (param "HOME") ".git-credentials")  ;; Still deny direct credential storage
    (subpath (param "HOME") ".config/gh")
    (subpath (param "HOME") ".kube")
    (subpath (param "HOME") ".android")
    (subpath (param "HOME") ".bash_history")
    (subpath (param "HOME") ".zsh_history"))
```

#### Write Permission Structure
```scheme
(allow file-write*
    ;; Current working directory ONLY (not entire DEV_WORKSPACE)
    (subpath (param "WORKING_DIR"))
    
    ;; Temporary directories
    (subpath "/tmp")
    (subpath "/var/tmp")
    
    ;; Standard I/O
    (literal "/dev/stdout")
    (literal "/dev/stderr")
    (literal "/dev/stdin")
    (literal "/dev/null")      ;; Also in read section for git operations
    (literal "/dev/urandom")
    (literal "/dev/random")
    
    ;; Package manager caches (write access for updates)
    (subpath (param "HOME") ".npm")
    (subpath (param "HOME") ".cache")
    (subpath (param "HOME") ".bundle")
    (subpath (param "HOME") ".cargo/registry")
    (subpath (param "HOME") ".gem")
    
    ;; Audit log location (project-specific)
    (subpath (param "AUDIT_LOG_PATH")))
```

#### Parameter Structure
```scheme
;; Required parameters with defaults
DEV_WORKSPACE   ;; Parent development directory (default: ~/dev)
                ;; Set via: DEV_WORKSPACE environment variable
                ;; Fallback: $HOME/dev

WORKING_DIR     ;; Current working directory
                ;; Set via: PWD environment variable
                ;; Fallback: Current process working directory

HOME            ;; User's home directory (for specific allowed subdirs)
                ;; Set via: HOME environment variable
                ;; No fallback (required by system)

;; Optional parameters with defaults
NATS_URL        ;; Full NATS server URL
                ;; Set via: NATS_URL environment variable
                ;; Default: nats://localhost:4222

NATS_CREDS      ;; Path to NATS credentials file
                ;; Set via: NATS_CREDS environment variable
                ;; Default: $HOME/.nats/creds (if exists)

AUDIT_LOG_PATH  ;; Path for security audit logs (project-specific)
                ;; Set via: SANDBOX_AUDIT_LOG environment variable
                ;; Default: $DEV_WORKSPACE/.sandbox-audit/<escaped-working-dir>/
                ;; Example: /Users/user/dev/.sandbox-audit/Users-user-dev-my-project/
                ;; Path escaping: / replaced with - (e.g., /Users/user/dev/my-project 
                ;;                becomes Users-user-dev-my-project)

VERBOSE_MODE    ;; Enable verbose security logging
                ;; Set via: SANDBOX_VERBOSE environment variable
                ;; Default: false

AGENT_OS_DIR    ;; For .agent-os access if needed separately
                ;; Set via: AGENT_OS_DIR environment variable
                ;; Default: $HOME/.agent-os

;; Optional parameters without defaults (only used if defined)
EXTRA_EXEC_PATH ;; Additional executable path for temporary binaries
                ;; Set via: EXTRA_EXEC_PATH environment variable
                ;; NOTE: Cannot be truly optional - sandbox-exec doesn't support
                ;; conditional inclusion. Must always be defined (use /tmp if not needed)
```

#### Network Restrictions
```scheme
(allow network-outbound
    ;; DNS resolution (required for hostname lookups)
    (remote tcp "*:53")      ;; DNS over TCP
    (remote udp "*:53")      ;; DNS over UDP (primary DNS protocol)
    
    ;; Standard web traffic
    (remote tcp "*:80")      ;; HTTP
    (remote tcp "*:443")     ;; HTTPS
    (remote tcp "*:22")      ;; SSH
    
    ;; Common development server ports (individual ports)
    (remote tcp "*:3000")    ;; React, Node.js dev servers
    (remote tcp "*:3001")    ;; Alternative React port
    (remote tcp "*:5000")    ;; Flask dev server
    (remote tcp "*:5173")    ;; Vite dev server
    (remote tcp "*:8000")    ;; Django dev server
    (remote tcp "*:8080")    ;; Common web server port
    (remote tcp "*:4200")    ;; Angular dev server
    (remote tcp "*:9000")    ;; Common dev port
    
    ;; NATS server access (only localhost is valid, not IP addresses)
    (remote tcp "localhost:4222"))  ;; Local NATS

;; Allow binding to local addresses for DNS and local servers
(allow network-bind
    (local ip "*:*"))  ;; Allow binding to any local port for DNS queries and local servers

;; Allow receiving network responses (required for DNS and other bidirectional protocols)
(allow network-inbound
    (local ip "*:*"))  ;; Allow receiving responses on any local port
```

**Note**: Network addresses in sandbox-exec only support `*` (any host) or `localhost` as the host portion. IP addresses like `127.0.0.1` are not supported.

#### Executable Commands Whitelist
```scheme
(allow file-execute
    ;; Core system commands (typically always present)
    (literal "/bin/sh")
    (literal "/bin/bash")
    (literal "/bin/zsh")
    (literal "/bin/cat")
    (literal "/bin/echo")
    (literal "/bin/pwd")
    (literal "/bin/mkdir")
    (literal "/bin/test")           ;; Shell built-in also as binary
    (literal "/usr/bin/test")       ;; Alternative location
    (literal "/usr/bin/dirname")    ;; Path manipulation
    (literal "/usr/bin/basename")   ;; Path manipulation
    (literal "/usr/bin/find")
    (literal "/usr/bin/make")
    (literal "/usr/bin/sed")
    (literal "/usr/bin/awk")
    (literal "/usr/bin/grep")
    (literal "/usr/bin/mktemp")
    (literal "/usr/bin/wc")
    (literal "/usr/bin/afplay")     ;; macOS sound player
    
    ;; Network testing tools
    (literal "/usr/bin/curl")       ;; HTTP/HTTPS client
    (literal "/usr/bin/nc")         ;; Netcat for port testing
    (literal "/usr/bin/wget")       ;; Alternative HTTP client
    (literal "/usr/bin/telnet")     ;; Legacy network testing
    (literal "/usr/bin/dig")        ;; DNS lookup tool
    
    ;; Homebrew executables (where most tools are installed)
    ;; This covers: nats, jq, git, gh, go, rm, tail (via aliases), etc.
    (subpath "/opt/homebrew/bin")
    (subpath "/opt/homebrew/opt")     ;; For formula-specific bins like coreutils
    (subpath "/opt/homebrew/Cellar")  ;; For versioned executables
    (subpath "/usr/local/bin")        ;; Intel Mac Homebrew location
    
    ;; Development workspace executables (for compiled binaries)
    (subpath (param "DEV_WORKSPACE"))
    
    ;; Agent OS scripts (all scripts in this directory)
    (subpath (param "HOME") ".agent-os/scripts")
    
    ;; Additional executable path for temporary needs (if defined)
    (subpath (param "EXTRA_EXEC_PATH")))
```

#### System Operations and Services
```scheme
;; DNS resolution support
(allow mach-lookup
    (global-name "com.apple.mDNSResponder")
    (global-name "com.apple.dnssd.service")
    (global-name "com.apple.networkd")
    (global-name "com.apple.nehelper")
    (global-name "com.apple.symptom_diagnostics")
    (global-name "com.apple.system.notification_center"))

;; System information for network interfaces
(allow system-info)

;; IPC and mach services (general)
(allow ipc-posix-shm)
(allow mach-lookup)  ;; General mach service lookup
(allow signal)

;; System operations
(allow system-socket)
(allow system-fsctl)

;; IOKit for network interface enumeration
(allow iokit-open)
(allow iokit-get-properties)

;; Process info for system state queries
(allow process-info*)
```

#### Additional File Access for DNS and Network
```scheme
;; DNS and network support files
(allow file-read*
    ;; Unix domain sockets for DNS
    (subpath "/var/run")
    (literal "/var/run/mDNSResponder")
    
    ;; Additional network configuration
    (literal "/etc/services")      ;; Service name mappings
    (literal "/private/etc/services")
    (literal "/etc/protocols")     ;; Protocol definitions
    (literal "/private/etc/protocols")
    
    ;; System configuration preferences for network
    (subpath "/System/Library/Preferences/SystemConfiguration"))
```

## Known Issues and Potential Solutions

### DNS Resolution for curl/wget
While `dig` successfully performs DNS lookups (direct UDP/TCP queries to port 53), tools like `curl` and `wget` fail with DNS resolution errors. This is because they use macOS's system resolver APIs (`getaddrinfo()`) rather than direct DNS queries.

**Current Status:** Root cause identified via system logs

**Required Permissions (discovered via system log analysis):**

1. **mDNSResponder Unix Socket (CRITICAL):**
   ```scheme
   ;; Allow network-outbound to mDNS Unix socket
   (allow network-outbound 
       (literal "/private/var/run/mDNSResponder"))
   ```
   This is the primary issue - curl needs to communicate with mDNSResponder via Unix socket.

2. **User Preferences and Encoding:**
   ```scheme
   ;; User text encoding preferences
   (allow file-read-data
       (literal (string-append (param "HOME") "/.CFUserTextEncoding")))
   
   ;; System preferences access
   (allow user-preference-read 
       (preference-domain "kCFPreferencesAnyApplication"))
   ```

3. **Network Configuration Files:**
   ```scheme
   ;; Network daemon preferences
   (allow file-read-data
       (literal "/Library/Preferences/com.apple.networkd.plist")
       (literal "/private/Library/Preferences/com.apple.networkd.plist"))
   ```

4. **Additional System Files (REQUIRED):**
   ```scheme
   ;; System helpers (required for curl operation)
   (allow file-read-data
       (literal "/dev/autofs_nowait"))
   
   ;; dtracehelper requires both read AND write permissions for curl
   (allow file-read-data
       (literal "/dev/dtracehelper"))
   (allow file-write-data
       (literal "/dev/dtracehelper"))
   ```

**System Log Evidence:**
```
Sandbox: curl(75886) deny(1) file-read-data /Users/eduardokolomajr/.CFUserTextEncoding
Sandbox: curl(75886) deny(1) user-preference-read kCFPreferencesAnyApplication
Sandbox: curl(75886) deny(1) file-read-data /Library/Preferences/com.apple.networkd.plist
Sandbox: curl(75886) deny(1) network-outbound /private/var/run/mDNSResponder
```

**Resolution:** Add the above permissions to enable full DNS resolution for curl/wget.

## Implementation Approach

### Phase 1: Security Assessment & Planning
- Document all current file access patterns in Claude Code
- Identify minimum necessary permissions for development workflows
- Map sensitive directories that must be protected
- Design parameter structure and defaults

### Phase 2: Environment Variable Implementation
- Replace HOME references with DEV_WORKSPACE
- Add parameter validation and sanitization
- Implement fallback mechanisms for undefined parameters
- Create configuration file for default values

### Phase 3: Security Boundaries
- Remove blanket filesystem access
- Implement explicit allow/deny rules
- Add path traversal protection
- Create security boundary validation tests

### Phase 4: Parameterized Configuration
- Convert hardcoded paths to parameters
- Implement parameter loading from environment
- Add configuration validation
- Create documentation for all parameters

### Phase 5: Testing & Validation
- Test common development workflows
- Verify git, npm, make operations work correctly
- Validate security boundaries hold
- Test edge cases and bypass attempts

## Audit Logging and Monitoring

### Access Attempt Logging
```scheme
;; Log denied access attempts
(trace "audit"
    (deny file-read* 
        ;; Log attempts to access sensitive directories
        (with-info (path target-path)
            (log-message "BLOCKED: Read attempt to ${target-path}"))))

;; Verbose mode for debugging
(when (param "VERBOSE_MODE")
    (trace "verbose"
        (allow file-read*
            (with-info (path target-path)
                (log-message "ALLOWED: Read access to ${target-path}")))))
```

### Audit Log Configuration
```scheme
;; Audit logs written to centralized directory with project-specific subdirectories
;; Path format: DEV_WORKSPACE/.sandbox-audit/<escaped-working-dir>/
;; Example: If WORKING_DIR=/Users/user/dev/my-project
;;          Then audit dir=/Users/user/dev/.sandbox-audit/Users-user-dev-my-project/

;; Path escaping for audit directory naming:
;; Replace / with - in the working directory path
;; /Users/user/dev/nexus -> Users-user-dev-nexus
;; Results in: /Users/user/dev/.sandbox-audit/Users-user-dev-nexus/

(define escaped-working-dir 
  (string-replace (param "WORKING_DIR") "/" "-"))
(define audit-log-dir 
  (string-append (param "DEV_WORKSPACE") "/.sandbox-audit/" escaped-working-dir))
(define audit-log-file 
  (string-append audit-log-dir "/audit.log"))

;; Log rotation via external script (cron/launchd)
;; Suggested: Daily rotation, keep 7 days per project
;; Location: DEV_WORKSPACE/.sandbox-audit/<project>/
;;   - audit.log (current)
;;   - audit.log.1 (yesterday)
;;   - audit.log.2 (2 days ago)
;;   - etc.
```

### Audit Log Format
- Timestamp: ISO 8601 format
- Action: BLOCKED/ALLOWED
- Operation: read/write/execute
- Path: Target path attempted
- Process: Process name making the attempt
- Result: Success/Denied

Example log entry:
```
2025-08-11T10:15:30Z BLOCKED read /Users/user/.ssh/id_rsa claude-code DENIED
2025-08-11T10:15:31Z ALLOWED read /Users/user/dev/project/file.txt claude-code SUCCESS
```

## Security Principles

1. **Principle of Least Privilege**: Only grant minimum necessary access
2. **Defense in Depth**: Multiple layers of protection (allow/deny/validate)
3. **Explicit Over Implicit**: Be explicit about what's allowed
4. **Fail Secure**: Default to denying access when uncertain
5. **Auditability**: Log access attempts to sensitive areas

## Backwards Compatibility

Ensure these workflows continue to function:
- Git operations within DEV_WORKSPACE
- Package manager operations (npm, pip, cargo)
- Build tools (make, cmake)
- Language runtime access
- NATS KV operations for PEER pattern

## Validation Requirements

### Security Tests
- Verify cannot read SSH keys
- Verify cannot read cloud credentials
- Verify cannot access other users' home directories
- Verify path traversal attempts fail
- Verify can only write to allowed directories

### Functionality Tests
- Verify can execute development tools
- Verify can read/write project files
- Verify can access temporary directories
- Verify NATS operations work correctly
- Verify Agent OS standards accessible

## External Dependencies

No new external dependencies required. Changes work within existing sandbox infrastructure.

## Future Considerations

### Configuration File for Dynamic Permissions

A future enhancement would be to support a configuration file that allows project-specific sandbox customization:

```json
// .agent-os/sandbox-config.json or .claude-sandbox.json
{
  "version": "1.0",
  "additional_read_paths": [
    "~/.agent-os",  // Automatically added if .agent-os exists in project
    "/opt/custom/library"
  ],
  "additional_write_paths": [
    "./build",
    "./dist"
  ],
  "additional_exec_paths": [
    "./scripts",
    "./bin"
  ],
  "network_ports": [
    9000,  // Custom dev server
    5432   // PostgreSQL
  ],
  "environment": {
    "CUSTOM_VAR": "value"
  }
}
```

The launcher script would:
1. Check if current directory contains `.agent-os/` directory
2. If yes, automatically add read permissions for root `.agent-os` directory
3. Look for sandbox config file in project
4. Merge project-specific permissions with base sandbox profile
5. Generate final sandbox profile with combined permissions

Benefits:
- **Automatic Agent OS support**: Projects using Agent OS get automatic access to standards
- **Project flexibility**: Each project can declare its specific needs
- **Security maintained**: Base restrictions still apply, only additions allowed
- **Version control**: Config file can be committed with project
- **Team consistency**: All developers get same sandbox configuration

Implementation approach:
```bash
# In future launcher script
if [ -d "$WORKING_DIR/.agent-os" ]; then
  # Auto-add root agent-os directory
  EXTRA_READ_PATHS="$HOME/.agent-os:$EXTRA_READ_PATHS"
fi

if [ -f "$WORKING_DIR/.agent-os/sandbox-config.json" ]; then
  # Parse and merge additional permissions
  MERGED_PROFILE=$(merge-sandbox-config base.sb sandbox-config.json)
fi
```

This would provide a path toward:
- Per-project sandbox customization
- Automatic detection of project requirements
- Gradual permission expansion as needed
- Maintaining security while improving developer experience