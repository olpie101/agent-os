# Claude Code Sandbox - Future Configuration File Approach

## Overview

This document outlines a proposed configuration file approach for the Claude Code Sandbox, designed to replace environment variables with a more manageable and flexible configuration system.

## Motivation

The current environment variable approach has limitations:
- Requires setting multiple variables for each session
- No validation of configuration before execution
- Difficult to manage multiple configurations
- No way to share configurations across team
- Limited ability to express complex rules

## Proposed Configuration Format

### YAML Configuration File

Location: `~/.claude-code/sandbox.yaml` or `.claude-sandbox.yaml` in project root

```yaml
# Claude Code Sandbox Configuration
version: "1.0"

# Global defaults
defaults:
  workspace: "${HOME}/dev"
  verbose: false
  audit:
    enabled: true
    path: "${workspace}/.sandbox-audit"
    rotate_daily: true
    retention_days: 30

# Network configuration
network:
  nats:
    url: "nats://localhost:4222"
    credentials: null
  allowed_ports:
    - 80    # HTTP
    - 443   # HTTPS
    - 22    # SSH/Git
    - 3000  # React
    - 3001  # React alternate
    - 5000  # Flask
    - 5173  # Vite
    - 8000  # Django
    - 8080  # Spring/Tomcat
    - 4200  # Angular
    - 9000  # Play
  custom_ports: []  # User-defined additional ports

# File system permissions
filesystem:
  read:
    # System directories (always allowed)
    system:
      - /usr
      - /bin
      - /sbin
      - /System
      - /Library/Frameworks
    
    # Development tools
    development:
      - /opt/homebrew  # Apple Silicon
      - /usr/local     # Intel/Linux
      - "${HOME}/.nvm"
      - "${HOME}/.rbenv"
      - "${HOME}/.pyenv"
    
    # User-defined read paths
    custom: []
  
  write:
    # Package manager caches
    caches:
      - "${HOME}/.npm"
      - "${HOME}/.yarn"
      - "${HOME}/.cache"
      - "${HOME}/.cargo/registry"
    
    # Temporary directories
    temp:
      - /tmp
      - /var/tmp
      - /private/tmp
    
    # User-defined write paths
    custom: []
  
  # Explicit deny list (always blocked)
  deny:
    - "${HOME}/.ssh"
    - "${HOME}/.aws"
    - "${HOME}/.gcp"
    - "${HOME}/.azure"
    - "${HOME}/.kube"
    - "${HOME}/.docker"
    - "${HOME}/.gnupg"
    - "${HOME}/Library/Keychains"
    - "${HOME}/.git-credentials"
    - "${HOME}/.netrc"  # Can be overridden in profiles

# Execution permissions
execution:
  shells:
    - /bin/sh
    - /bin/bash
    - /bin/zsh
  
  # Language interpreters
  languages:
    - /usr/bin/python3
    - /usr/bin/ruby
    - /usr/bin/node
    - /usr/local/bin/node
    - /opt/homebrew/bin/node
  
  # Build tools
  build_tools:
    - /usr/bin/make
    - /usr/bin/gcc
    - /usr/bin/clang
  
  # Custom executables
  custom: []

# Named profiles for different scenarios
profiles:
  # Default profile
  default:
    workspace: "${defaults.workspace}"
    working_dir: "${PWD}"
    inherit: defaults
  
  # Restricted profile for untrusted code
  restricted:
    workspace: "${PWD}"
    working_dir: "${PWD}"
    network:
      allowed_ports: [80, 443]  # Only HTTP/HTTPS
    filesystem:
      read:
        custom: []  # No additional paths
      write:
        custom: []  # No additional paths
    execution:
      custom: []  # No custom executables
  
  # Development profile with more access
  development:
    inherit: defaults
    workspace: "${HOME}/dev"
    filesystem:
      read:
        custom:
          - "${HOME}/.config/git"
          - "${HOME}/.netrc"  # Allow for dev tools
    execution:
      custom:
        - "${workspace}/node_modules/.bin"  # Project binaries
  
  # Data science profile
  datascience:
    inherit: defaults
    workspace: "${HOME}/notebooks"
    network:
      allowed_ports:
        - 8888  # Jupyter
        - 8787  # RStudio
    filesystem:
      read:
        custom:
          - "${HOME}/datasets"  # Read-only data access
    execution:
      custom:
        - /usr/local/bin/jupyter
        - /opt/anaconda/bin

# Project-specific overrides
projects:
  - path: "${HOME}/dev/sensitive-project"
    profile: restricted
    workspace: "${HOME}/dev/sensitive-project"
    
  - path: "${HOME}/dev/ml-project"
    profile: datascience
    filesystem:
      read:
        custom:
          - "/mnt/training-data"
    
  - path: "${HOME}/dev/client-work/*"
    profile: default
    audit:
      enabled: true
      retention_days: 90  # Longer retention for client work
```

### JSON Alternative

For environments preferring JSON:

```json
{
  "version": "1.0",
  "defaults": {
    "workspace": "${HOME}/dev",
    "verbose": false,
    "audit": {
      "enabled": true,
      "path": "${workspace}/.sandbox-audit",
      "rotate_daily": true,
      "retention_days": 30
    }
  },
  "profiles": {
    "default": {
      "workspace": "${defaults.workspace}",
      "working_dir": "${PWD}",
      "inherit": "defaults"
    },
    "restricted": {
      "workspace": "${PWD}",
      "working_dir": "${PWD}",
      "network": {
        "allowed_ports": [80, 443]
      }
    }
  }
}
```

## Configuration Loading Order

1. **Built-in defaults** - Hardcoded safe defaults
2. **System configuration** - `/etc/claude-code/sandbox.yaml`
3. **User configuration** - `~/.claude-code/sandbox.yaml`
4. **Project configuration** - `.claude-sandbox.yaml` in project root
5. **Environment variables** - Override specific values
6. **Command-line arguments** - Highest priority

Each level can override previous settings.

## Profile Selection

### Automatic Selection

```bash
# Launcher detects project config
cd ~/dev/my-project
./claude-code-sandbox-launcher.sh claude-code
# Automatically uses .claude-sandbox.yaml if present
```

### Manual Selection

```bash
# Specify profile explicitly
./claude-code-sandbox-launcher.sh --profile=restricted claude-code

# Override profile settings
./claude-code-sandbox-launcher.sh \
  --profile=development \
  --workspace=/specific/path \
  claude-code
```

## Advanced Features

### Template Variables

Support for variable expansion:
- `${HOME}` - User's home directory
- `${PWD}` - Current working directory
- `${workspace}` - Configured workspace path
- `${env:VARNAME}` - Environment variable
- `${defaults.key}` - Reference to defaults section

### Conditional Configuration

```yaml
profiles:
  dynamic:
    workspace: "${HOME}/dev"
    conditional:
      - if: "${env:CI}"
        then:
          audit:
            enabled: false  # Disable in CI
      - if: "${env:DEBUG}"
        then:
          verbose: true
          audit:
            enabled: true
```

### Include External Configuration

```yaml
includes:
  - ~/.claude-code/common.yaml
  - ./team-config.yaml

profiles:
  team:
    inherit: [defaults, team-common]
    workspace: "${HOME}/team-projects"
```

## Migration Path

### Phase 1: Parallel Support
- Configuration file support added alongside environment variables
- Environment variables take precedence for backward compatibility
- Warning messages encourage migration to config files

### Phase 2: Config File Primary
- Configuration file becomes primary method
- Environment variables still supported but deprecated
- Auto-migration tool provided

### Phase 3: Full Migration
- Environment variables only for overrides
- Rich configuration validation
- Config file management tools

## Implementation Benefits

### For Users
- **Simpler setup**: One-time configuration
- **Profile management**: Switch between configurations easily
- **Team sharing**: Commit configs to version control
- **Validation**: Pre-execution configuration checking
- **Documentation**: Self-documenting configuration

### For Security
- **Audit trail**: Configuration changes tracked
- **Policy enforcement**: Mandatory security settings
- **Compliance**: Easier to audit and verify
- **Least privilege**: Profile-based restrictions

### For Maintenance
- **Versioning**: Configuration format versions
- **Migration**: Automated upgrade paths
- **Debugging**: Clear configuration dump
- **Extension**: Easy to add new features

## CLI Tool for Configuration Management

### Proposed Commands

```bash
# Initialize configuration
claude-sandbox config init

# Validate configuration
claude-sandbox config validate

# Show effective configuration
claude-sandbox config show --profile=development

# Edit configuration
claude-sandbox config edit

# List available profiles
claude-sandbox config profiles

# Test configuration
claude-sandbox config test --profile=restricted

# Import/Export configuration
claude-sandbox config export > team-config.yaml
claude-sandbox config import team-config.yaml
```

## Configuration Schema Validation

### JSON Schema for Validation

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Claude Code Sandbox Configuration",
  "type": "object",
  "required": ["version"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+$"
    },
    "defaults": {
      "type": "object",
      "properties": {
        "workspace": {"type": "string"},
        "verbose": {"type": "boolean"},
        "audit": {
          "type": "object",
          "properties": {
            "enabled": {"type": "boolean"},
            "path": {"type": "string"},
            "rotate_daily": {"type": "boolean"},
            "retention_days": {"type": "integer", "minimum": 1}
          }
        }
      }
    }
  }
}
```

## Backward Compatibility

### Environment Variable Mapping

```yaml
# These environment variables map to config file settings
DEV_WORKSPACE      -> defaults.workspace
WORKING_DIR        -> current profile working_dir
AGENT_OS_DIR       -> filesystem.read.custom[]
NATS_URL          -> network.nats.url
NATS_CREDS        -> network.nats.credentials
SANDBOX_VERBOSE   -> defaults.verbose
EXTRA_EXEC_PATH   -> execution.custom[]
```

### Deprecation Warnings

```bash
# When using environment variables
WARNING: Environment variable configuration is deprecated.
Run 'claude-sandbox config migrate' to create a configuration file.
```

## Security Considerations

### File Permissions
- Config files should be readable only by owner (600)
- System configs require root/admin to modify
- Project configs inherit repository permissions

### Sensitive Data
- Never store credentials directly in config
- Use references to secure storage
- Support encrypted values for sensitive settings

### Validation
- Reject configs with overly broad permissions
- Warn about security implications
- Require explicit override for risky settings

## Future Enhancements

### Dynamic Profiles
- Time-based restrictions
- Network-aware profiles
- Resource usage limits
- User/group based profiles

### Integration
- IDE plugins reading config
- CI/CD pipeline integration
- Cloud-based config management
- Team policy distribution

### Monitoring
- Config change tracking
- Usage analytics
- Security compliance reporting
- Performance profiling

## Conclusion

The configuration file approach provides a more maintainable, secure, and user-friendly way to manage Claude Code Sandbox settings. It enables team collaboration, simplifies setup, and provides a foundation for future enhancements while maintaining backward compatibility.