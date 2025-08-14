# Claude Code Sandbox - Common Development Setup Examples

## Overview

This document provides practical examples for using the Claude Code Sandbox with various development environments and workflows. Each example includes the necessary environment variables and commands.

## Node.js/JavaScript Development

### React Application

```bash
# Navigate to your React project
cd ~/dev/my-react-app

# Run Claude Code with sandbox
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Claude Code can now:
# - Run npm install/yarn install
# - Execute npm start/yarn start
# - Run tests with npm test
# - Build with npm run build
# - Modify source files in src/
# - Update package.json
```

### Next.js Project with Custom Port

```bash
cd ~/dev/nextjs-project

# Include custom development server port if needed
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Supported operations:
# - npm run dev (port 3000 is allowed)
# - API routes development
# - Static site generation
# - Environment variable management
```

### Node.js Backend with NATS

```bash
cd ~/dev/backend-service

# Configure with NATS access
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
NATS_URL="nats://localhost:4222" \
./claude-code-sandbox-launcher.sh claude-code

# Available operations:
# - NATS pub/sub operations
# - npm script execution
# - Database migrations (if in project)
# - Environment configuration
```

## Python Development

### Django Project

```bash
cd ~/dev/django-app

# Set up for Django development
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Claude Code can:
# - Run python manage.py runserver (port 8000 allowed)
# - Execute migrations
# - Run tests
# - Install packages with pip
# - Modify Python source files
```

### Data Science with Jupyter

```bash
cd ~/dev/data-analysis

# Configure for data science work
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Supported workflows:
# - Jupyter notebook operations (port 8888)
# - pip install for scientific packages
# - Data file reading from DEV_WORKSPACE
# - Output generation in WORKING_DIR
```

## Go Development

### Go Module Project

```bash
cd ~/dev/go-service

# Set up for Go development
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Available operations:
# - go mod init/tidy/download
# - go build/run/test
# - Binary execution within WORKING_DIR
# - Package management
```

### Go with Custom Tools

```bash
cd ~/dev/go-project

# Include custom Go tools
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
EXTRA_EXEC_PATH="/usr/local/go/bin" \
./claude-code-sandbox-launcher.sh claude-code

# Enhanced capabilities:
# - Custom linters
# - Code generation tools
# - Additional Go utilities
```

## Multi-Language Projects

### Monorepo with Multiple Services

```bash
cd ~/dev/monorepo

# Configure for monorepo development
DEV_WORKSPACE="$HOME/dev/monorepo" \
WORKING_DIR="$HOME/dev/monorepo" \
./claude-code-sandbox-launcher.sh claude-code

# Supports:
# - Multiple package.json files
# - Different language services
# - Shared dependencies
# - Cross-service operations
```

### Full-Stack Application

```bash
cd ~/dev/fullstack-app

# Set up for full-stack development
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Capabilities:
# - Frontend build (React/Vue/Angular)
# - Backend API development
# - Database operations
# - Docker compose workflows
# - Concurrent server running
```

## Agent OS Workflows

### PEER Pattern Execution

```bash
cd ~/dev/my-project

# Configure for Agent OS PEER pattern
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
AGENT_OS_DIR="$HOME/.agent-os" \
NATS_URL="nats://localhost:4222" \
./claude-code-sandbox-launcher.sh claude-code

# PEER operations available:
# - /peer --instruction=create-spec
# - /peer --instruction=execute-tasks
# - NATS KV operations for state
# - Agent OS script execution
```

### Spec-Driven Development

```bash
cd ~/dev/nexus

# Set up for spec-driven workflow
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
AGENT_OS_DIR="$HOME/.agent-os" \
./claude-code-sandbox-launcher.sh claude-code

# Workflow support:
# - Reading spec files
# - Creating task lists
# - Executing implementation
# - Running tests
# - Updating documentation
```

## Debugging and Troubleshooting

### Verbose Mode for Debugging

```bash
cd ~/dev/problematic-project

# Enable verbose audit logging
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
SANDBOX_VERBOSE="true" \
./claude-code-sandbox-launcher.sh --verbose claude-code

# Debugging features:
# - File access logging
# - Network connection tracking
# - Permission denial reasons
# - Process execution audit
# Check logs at: ~/dev/.sandbox-audit/*/
```

### Testing Sandbox Restrictions

```bash
# Test that sensitive files are blocked
DEV_WORKSPACE="/tmp/test-workspace" \
WORKING_DIR="/tmp/test-workspace" \
./claude-code-sandbox-launcher.sh claude-code

# Verify protections:
# - Cannot read ~/.ssh/
# - Cannot access ~/.aws/
# - Cannot modify system files
# - Can only write in WORKING_DIR
```

## CI/CD Integration

### GitHub Actions Local Testing

```bash
cd ~/dev/github-project

# Set up for GitHub Actions testing
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Supported operations:
# - act (GitHub Actions locally)
# - Workflow file editing
# - Script testing
# - Environment simulation
```

### Build Pipeline Development

```bash
cd ~/dev/pipeline-project

# Configure for build pipeline work
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Available tools:
# - make commands
# - Docker builds (within limits)
# - Test execution
# - Artifact generation
```

## Custom Development Environments

### Ruby on Rails

```bash
cd ~/dev/rails-app

# Set up for Rails development
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Rails operations:
# - bundle install
# - rails server (port 3000)
# - rails console
# - Database migrations
# - Asset compilation
```

### Rust Development

```bash
cd ~/dev/rust-project

# Configure for Rust
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Rust workflows:
# - cargo build/run/test
# - rustfmt and clippy
# - Binary execution
# - Dependency management
```

### Java/Spring Boot

```bash
cd ~/dev/spring-app

# Set up for Java development
DEV_WORKSPACE="$HOME/dev" \
WORKING_DIR="$(pwd)" \
./claude-code-sandbox-launcher.sh claude-code

# Java capabilities:
# - mvn/gradle commands
# - Spring Boot run (port 8080)
# - Test execution
# - JAR/WAR building
```

## Best Practices

### Project Organization

```bash
# Recommended directory structure
~/dev/
  ├── personal/        # Personal projects
  ├── work/           # Work projects
  ├── experiments/    # Testing and learning
  └── .sandbox-audit/ # Audit logs (auto-created)

# Launch from specific category
DEV_WORKSPACE="$HOME/dev/work" \
WORKING_DIR="$HOME/dev/work/project-x" \
./claude-code-sandbox-launcher.sh claude-code
```

### Environment Variables in Shell Profile

```bash
# Add to ~/.zshrc or ~/.bashrc
export DEV_WORKSPACE="$HOME/dev"
export AGENT_OS_DIR="$HOME/.agent-os"
export NATS_URL="nats://localhost:4222"

# Then simply run
cd ~/dev/my-project
./claude-code-sandbox-launcher.sh claude-code
```

### Alias for Convenience

```bash
# Add to shell profile
alias claude-sandbox='~/tools/claude-code-sandbox-launcher.sh'

# Usage
cd ~/dev/project
claude-sandbox claude-code
```

## Security Considerations

### Minimal Access Pattern

```bash
# Most restrictive setup
DEV_WORKSPACE="/specific/project" \
WORKING_DIR="/specific/project" \
./claude-code-sandbox-launcher.sh claude-code
```

### Audit Review Pattern

```bash
# Run with audit, then review
SANDBOX_VERBOSE="true" \
./claude-code-sandbox-launcher.sh claude-code

# Review audit logs
tail -f ~/dev/.sandbox-audit/*/sandbox-*.log
```

### Testing New Projects

```bash
# Test in isolated environment first
mkdir /tmp/test-project
cd /tmp/test-project

DEV_WORKSPACE="/tmp/test-project" \
WORKING_DIR="/tmp/test-project" \
./claude-code-sandbox-launcher.sh claude-code
```