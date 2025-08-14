# Technical Stack

## Core Technologies

### Application Framework
- **Framework:** Agent OS (Multi-Agent Orchestration System)
- **Version:** 2.0+
- **Language:** Shell scripting (Bash), Markdown specifications

### State Management
- **Primary:** NATS Jetstream with KV storage
- **Version:** 2.10+
- **Storage Pattern:** Unified state schema with JSON documents

### Agent Architecture
- **Pattern:** PEER (Plan, Execute, Express, Review)
- **Coordination:** Process-based multi-agent system
- **State Schema:** Unified state v1.1 with cycle-based storage

## Agent Infrastructure

### Agent Runtime
- **Platform:** Claude Code / Cursor compatible
- **Execution:** Subagent delegation through markdown instructions
- **Communication:** NATS KV state sharing between agents

### Scripting Environment
- **Primary Language:** Bash shell scripts
- **Data Processing:** jq for JSON manipulation
- **File System:** Standard Unix tools and file operations
- **Error Handling:** Exit codes and structured error messages

### Documentation Format
- **Specifications:** Markdown with YAML frontmatter
- **Configuration:** YAML embedded in markdown
- **Standards:** Markdown documentation files

## Infrastructure

### State Storage
- **Provider:** NATS KV (Key-Value store)
- **Bucket:** agent-os-peer-state
- **Replication:** 3 replicas
- **History:** 50 revisions per key
- **Access Pattern:** Read-modify-write with JSON documents

### Agent Coordination
- **Pattern:** PEER cycle execution
- **State Key Format:** [KEY_PREFIX].cycle.[CYCLE_NUMBER]
- **Phase Ownership:** Each agent owns its phase data
- **Handoff Protocol:** State-based with phase completion markers

### Development Tools
- **Version Control:** Git integration through git-workflow agent
- **Testing:** Shell script test suites with executable permission validation
- **Sandbox:** Claude Code sandbox with security boundaries
- **Auditing:** Comprehensive logging and rotation system

## Deployment

### Hosting Platform
- **Environment:** Local development with Claude Code integration
- **Dependencies:** NATS server, jq, standard Unix tools
- **Setup Scripts:** Automated setup for Claude Code and Cursor
- **Security:** Sandbox restrictions with audit logging

### Agent Distribution
- **Storage:** Local file system with .agent-os directory structure
- **Instructions:** Markdown files in instructions/core/ directory
- **Agents:** Markdown specifications in claude-code/agents/ directory
- **Standards:** Global standards in standards/ directory

### Integration Patterns
- **IDE Support:** Claude Code, Cursor, compatible AI coding tools
- **Command Interface:** /peer command with instruction delegation
- **State Persistence:** Automatic state management across sessions
- **Error Recovery:** Graceful degradation with continuation support

---

*This tech stack reflects the actual implementation of Agent OS multi-agent PEER pattern system with NATS KV state management and shell-based orchestration.*