# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-04-peer-agent-pattern/spec.md

## PEER Slash Command Architecture

The `/peer` slash command references an instruction file that orchestrates any Agent OS instruction through four phases using subagents and NATS CLI for state management.

### Key Design Principles

1. **Slash Command Interface**: `/peer --instruction=<name>` and `/peer --continue` patterns
2. **Instruction-Based Orchestration**: PEER logic implemented as an instruction file, not an agent
3. **NATS CLI Storage**: Use NATS CLI commands for all KV operations
4. **Stateful Continuation**: Support resuming from interrupted phases
5. **Preserve Outputs**: Keep original instruction outputs unchanged

## NATS KV Schema

### Key Pattern

For spec-aware instructions:
```
peer.spec.<spec-folder-name>.meta
peer.spec.<spec-folder-name>.cycle.<number>
```

For non-spec instructions:
```
peer.instruction.<instruction-name>.meta
peer.instruction.<instruction-name>.cycle.<number>
```

Where:
- `<spec-folder-name>` is the spec folder without date prefix (e.g., `password-reset-flow`)
- `<instruction-name>` is the instruction being executed (e.g., `analyze-product`)

### Schema Definitions

All KV operations use NATS CLI commands via Bash tool.

#### 1. Meta Key: `peer.spec.<spec-folder-name>.meta`
**Purpose**: Spec metadata and cycle tracking
```json
{
  "spec_name": "password-reset-flow",
  "created_at": "2025-08-04T10:00:00Z",
  "current_cycle": 2,
  "current_phase": "execute",
  "cycles": {
    "1": {
      "instruction": "create-spec",
      "status": "complete",
      "completed_at": "2025-08-04T10:30:00Z"
    },
    "2": {
      "instruction": "execute-tasks", 
      "status": "running",
      "started_at": "2025-08-04T11:00:00Z"
    }
  }
}
```

#### 2. Cycle Key: `peer.spec.<spec-folder-name>.cycle.<number>`
**Purpose**: Complete record of one instruction execution through all PEER phases
```json
{
  "cycle_number": 1,
  "instruction": "create-spec",
  "started_at": "2025-08-04T10:00:00Z",
  "completed_at": "2025-08-04T10:30:00Z",
  "phases": {
    "plan": {
      "status": "complete",
      "output": {
        "steps": ["Gather requirements", "Create spec structure"],
        "estimated_duration": "30 minutes"
      }
    },
    "execute": {
      "status": "complete", 
      "output": {
        "files_created": ["spec.md", "tasks.md", "sub-specs/technical-spec.md"],
        "steps_completed": 12
      }
    },
    "express": {
      "status": "complete",
      "output": {
        "summary": "Password reset spec created with 12 tasks",
        "highlights": ["Database schema included", "Security considerations documented"]
      }
    },
    "review": {
      "status": "complete",
      "output": {
        "quality_score": "high",
        "completeness": true,
        "recommendations": ["Consider adding rate limiting documentation"]
      }
    }
  },
  "result": {
    "success": true,
    "files_created": ["spec.md", "tasks.md", "sub-specs/technical-spec.md"],
    "summary": "Password reset spec successfully created"
  },
  "insights": {
    "learnings": [
      "User prefers database schemas in technical specs",
      "Security considerations are high priority for auth features"
    ],
    "issues_encountered": [
      {
        "phase": "execute",
        "issue": "Unclear if 2FA should be included",
        "resolution": "Asked user for clarification"
      }
    ],
    "questions_for_user": [
      "Should rate limiting be configurable per endpoint?"
    ],
    "recommendations": [
      "Create security checklist for auth-related specs"
    ]
  },
  "status": {
    "current_phase": "complete",
    "progress_percent": 100,
    "last_update": "2025-08-04T10:30:00Z"
  }
}
```

## PEER Implementation Architecture

### File Structure
- **Slash Command**: `@commands/peer.md` - References the instruction file
- **Instruction File**: `@instructions/core/peer.md` - Main orchestration logic (source)
- **User Reference**: `@~/.agent-os/instructions/peer.md` - Copied to user's home directory
- **Phase Agents**: All in `@claude-code/agents/` directory:
  - `@claude-code/agents/peer-planner.md`
  - `@claude-code/agents/peer-executor.md`
  - `@claude-code/agents/peer-express.md`
  - `@claude-code/agents/peer-review.md`
- **Script Files**: All in `@scripts/peer/` directory:
  - `@scripts/peer/check-nats-health.sh` - NATS availability check with caching
  - `@scripts/peer/setup-kv-bucket.sh` - Bucket creation and verification
  - `@scripts/peer/parse-arguments.sh` - Command line argument parsing
  - `@scripts/peer/determine-context.sh` - Instruction classification logic
  - `@scripts/peer/initialize-cycle.sh` - PEER cycle initialization
  - `@scripts/peer/finalize-cycle.sh` - Cycle completion and cleanup

### Script Architecture and Design

#### Script Organization
Scripts are organized to separate concerns and improve maintainability:

1. **Infrastructure Scripts** (Run conditionally with caching):
   - `check-nats-health.sh`: Checks NATS server availability
   - `setup-kv-bucket.sh`: Ensures required KV bucket exists

2. **Core Execution Scripts** (Run every time):
   - `parse-arguments.sh`: Parses command-line arguments
   - `determine-context.sh`: Classifies instruction type
   - `initialize-cycle.sh`: Sets up PEER cycle state
   - `finalize-cycle.sh`: Completes cycle and cleanup

#### Script Documentation Standards
Each script must be self-documenting with:
```bash
#!/bin/bash
# Script: script-name.sh
# Purpose: Brief description of what the script does
# Parameters: List of expected parameters
# Output: What the script outputs (files, stdout, exit codes)
# Cache: If applicable, caching strategy used
# Dependencies: External commands or files required

# Cleanup function for script-local temp files
cleanup() {
    rm -f /tmp/script_specific_*.tmp
    # DO NOT delete files needed by other scripts
}

# Set trap for cleanup on exit
trap cleanup EXIT
```

#### Caching Strategy
Infrastructure checks use intelligent caching to reduce overhead:

1. **NATS Health Check Cache**:
   - Cache file: `/tmp/.peer-nats-check`
   - Format: `timestamp:status`
   - TTL: 24 hours
   - Invalidation: On NATS operation failure

2. **Bucket Existence Cache**:
   - Checked on first NATS health check of the day
   - No separate cache (piggybacks on health check)

#### Script Execution Pattern
The peer.md instruction calls scripts using Bash tool:
```bash
# Simple script execution
dev/agent-os/scripts/peer/check-nats-health.sh

# Script with parameters
dev/agent-os/scripts/peer/parse-arguments.sh "$@"

# Conditional execution based on exit code
if dev/agent-os/scripts/peer/determine-context.sh; then
    # Context is spec-aware
else
    # Context is non-spec
fi
```

#### Parameter Simplification
Instead of complex bash logic in instructions, scripts handle:
- Argument parsing from command line
- Context inference from instruction names
- File-based communication via `/tmp/peer_*.txt` files
- JSON construction and parsing for NATS operations

#### Temp File Management
Scripts use two categories of temp files:

1. **Inter-script Communication Files** (cleaned by finalize-cycle.sh on success):
   - `/tmp/peer_args.txt` - Created by parse-arguments.sh, needed by others
   - `/tmp/peer_context.txt` - Created by determine-context.sh, needed by others
   - `/tmp/peer_cycle.txt` - Created by initialize-cycle.sh, needed by agents

2. **Script-local Temp Files** (MUST be cleaned by creating script using trap):
   - **check-nats-health.sh**: None (cache file `/tmp/.peer-nats-check` is intentionally kept)
   - **setup-kv-bucket.sh**: `/tmp/bucket_info.txt`
   - **parse-arguments.sh**: None (creates communication file only)
   - **determine-context.sh**: None (creates communication file only)
   - **initialize-cycle.sh**: `/tmp/current_meta.json`, `/tmp/existing_meta.json`, `/tmp/updated_meta.json`, `/tmp/new_cycle.json`
   - **finalize-cycle.sh**: `/tmp/final_meta.json`, `/tmp/final_meta_updated.json`, `/tmp/final_cycle.json`, `/tmp/final_cycle_updated.json`

#### Trap-based Cleanup Implementation

Each script that creates local temp files must implement trap-based cleanup:

```bash
#!/bin/bash
# Script: setup-kv-bucket.sh

# Cleanup function - ONLY for local temp files
cleanup() {
    rm -f /tmp/bucket_info.txt
}

# Set trap for cleanup on any exit
trap cleanup EXIT
```

**initialize-cycle.sh cleanup example:**
```bash
cleanup() {
    # Clean up only local JSON files used internally
    rm -f /tmp/current_meta.json /tmp/existing_meta.json 
    rm -f /tmp/updated_meta.json /tmp/new_cycle.json
    # DO NOT clean up /tmp/peer_*.txt files here
}
trap cleanup EXIT
```

**finalize-cycle.sh cleanup example:**
```bash
cleanup() {
    # Clean up local JSON files
    rm -f /tmp/final_meta.json /tmp/final_meta_updated.json
    rm -f /tmp/final_cycle.json /tmp/final_cycle_updated.json
}
trap cleanup EXIT

# At the END of successful execution only:
# Clean up ALL communication files
rm -f /tmp/peer_*.txt
```

**Important Rules:**
1. Scripts MUST use trap to clean their own local temp files
2. Scripts MUST NOT use trap to clean inter-script communication files
3. Only finalize-cycle.sh cleans communication files, and only on successful completion
4. Cache files (like `/tmp/.peer-nats-check`) are intentionally preserved

### Critical Issues Discovered in Testing

**Test Execution**: `/peer --instruction=create-spec` on 2025-08-05

**Issue 1: NATS State Management Non-Functional**
- No NATS KV operations occurred during execution
- Only peer-express agent checked NATS (all others bypassed state management)
- No cycle metadata, phase outputs, or state persistence
- Continuation support completely broken

**Issue 2: Instruction Orchestration Bypassed**  
- peer.md instruction file contains XML-style pseudo-code rather than executable instructions
- Claude recognized PEER pattern conceptually and directly invoked agents
- NATS pre-flight checks, bucket operations, and state updates never executed
- Bash tool commands in instruction file are embedded in XML tags and not executed

**Issue 3: Agent Parameter Mismatch**
- Task tool invocations pass simple descriptions instead of structured parameters
- Agents expect meta_data, cycle_number, context objects but receive basic prompts
- Agent specifications don't match actual invocation patterns

**Architecture Problem**: The peer.md instruction is written as a specification document with process flow descriptions rather than as an executable instruction using Claude Code's available tools.

### Required Architecture Fixes Based on Test Analysis

**Fix 1: Move NATS Operations from Descriptions to Executable Steps**
- Current issue: peer.md has NATS operations in `<pre_flight_check>` as descriptive XML blocks
- Solution: Move NATS operations to numbered `<step>` elements with actual Bash tool calls
- Pattern: Follow create-spec.md structure where executable operations are in process steps
- Implementation: Convert existing bash commands from documentation to actual tool invocations

**Fix 2: Restructure Instruction Flow to Match Working Patterns**
- Current issue: peer.md structure doesn't follow the step-by-step pattern of working instructions
- Solution: Reorganize as sequential steps following create-spec.md/execute-tasks.md patterns:
  - Step 1: NATS availability check (Bash tool)
  - Step 2: NATS KV bucket setup (Bash tool) 
  - Step 3: Argument parsing and validation
  - Step 4: Context determination (spec vs non-spec)
  - Step 5-8: Agent invocation steps with proper NATS updates
- Pattern: Each step uses specific tools and produces concrete outputs

**Fix 3: Fix Agent Parameter Passing to Match Working Instructions**
- Current issue: Task tool calls pass simple descriptions instead of structured parameters
- Solution: Review how create-spec.md invokes subagents and match that pattern
- Implementation: Update Task tool calls to pass context in expected format
- Validation: Ensure agents receive meta_data, cycle_number, context as specified

**Fix 4: Resolve Workflow Integration Conflicts**
- Current issue: PEER review conflicts with built-in instruction review (e.g., create-spec user review)
- Solution: Clarify PEER review purpose when wrapping instructions that already have review steps
- Implementation: Handle different instruction types appropriately (some have review, some don't)
- Testing: Validate PEER works with both review-capable and non-review instructions

### PEER Instruction File
- **Purpose**: Orchestrate the PEER pattern execution flow
- **Responsibilities**: 
  - Verify NATS server availability before proceeding
  - Parse --instruction and --continue flags
  - Check NATS KV state for existing cycles
  - Invoke phase agents as subagents
  - Stop execution if NATS server is unavailable
- **KV Updates**: Manages meta key and coordinates phase transitions through NATS CLI commands

### 1. Planner Agent (peer-planner.md)
- **Purpose**: Decompose instruction into phases and steps
- **KV Updates**: Creates new cycle, updates phase.plan in cycle
- **Output**: Planning strategy with steps and success criteria

### 2. Executor Agent (peer-executor.md) 
- **Purpose**: Execute planned steps using existing subagents
- **KV Updates**: Updates phase.execute and status in cycle
- **Output**: Execution results (unchanged from original instruction)

### 3. Express Agent (peer-express.md)
- **Purpose**: Format and present final results
- **KV Updates**: Updates phase.express and result in cycle
- **Output**: Professional presentation of all outputs

### 4. Review Agent (peer-review.md)
- **Purpose**: Quality check and feedback collection
- **KV Updates**: Updates phase.review and insights in cycle
- **Output**: Quality assessment and improvement recommendations

## PEER Slash Command Implementation

### Command File
The slash command `@commands/peer.md` will follow the standard pattern:
```markdown
# PEER

Execute any Agent OS instruction through the PEER (Plan, Execute, Express, Review) pattern

Refer to the instructions located in @~/.agent-os/instructions/peer.md
```

### Command Patterns
```
/peer --instruction=create-spec
/peer --instruction=execute-tasks  
/peer --instruction=analyze-product
/peer --instruction=<name> --spec=<spec-name>
/peer --continue
/peer --continue --spec=<spec-name>
```

### Optional Parameters
- `--spec=<spec-name>`: Explicitly specify which spec to operate on (without date prefix)
  - Only applicable for spec-aware instructions (execute-tasks, optionally create-spec)
  - Instructions that don't use spec context: analyze-product, plan-product
  - Example: `--spec=password-reset` for `.agent-os/specs/2025-08-04-password-reset/`

### Instruction File Structure

The PEER instruction (`@instructions/core/peer.md`) will follow the Agent OS instruction pattern:

```xml
---
description: PEER Pattern Orchestration for Agent OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# PEER Pattern Execution

<pre_flight_check>
  - Verify NATS server availability using `nats kv ls`
  - Parse command arguments (--instruction, --continue, --spec)
  - Determine spec context
</pre_flight_check>

<process_flow>
  <step number="1" subagent="peer-planner" name="planning_phase">
    <!-- Planning phase implementation -->
  </step>
  
  <step number="2" subagent="peer-executor" name="execution_phase">
    <!-- Execution phase implementation -->
  </step>
  
  <step number="3" subagent="peer-express" name="express_phase">
    <!-- Express phase implementation -->
  </step>
  
  <step number="4" subagent="peer-review" name="review_phase">
    <!-- Review phase implementation -->
  </step>
</process_flow>
```

### Execution Flow

#### New Execution (`/peer --instruction=<name>`)
1. **Pre-flight Check**: Verify NATS server is available using `nats kv ls`
2. **Determine Spec**: 
   - If `--spec` provided: validate spec folder exists
   - If not provided: find latest spec directory by date prefix
3. **Check State**: Use `nats kv get` to check if spec has existing cycles
4. **Initialize**: Create/update meta with new cycle number via `nats kv put`
5. **Create Cycle**: Initialize new cycle key with instruction info
6. **Run Phases**: Execute plan → execute → express → review
7. **Update State**: After each phase, update cycle key with phase output
8. **Finalize**: Mark cycle complete in meta

#### Continue Execution (`/peer --continue`)
1. **Pre-flight Check**: Verify NATS server is available using `nats kv ls`
2. **Determine Spec**: 
   - If `--spec` provided: validate spec folder exists
   - If not provided: find latest spec directory by date prefix
3. **Get State**: Use `nats kv get` to read meta and find current cycle/phase
4. **Load Cycle**: Read current cycle data to understand progress
5. **Resume**: Continue from last incomplete phase
6. **Update State**: Continue updating cycle key with phase outputs
7. **Finalize**: Mark cycle complete when all phases done

### Integration with Existing Instructions

The PEER instruction wraps existing instructions without modifying them:

1. **Instruction Invocation**: PEER calls the target instruction (e.g., create-spec) during the Execute phase
2. **State Preservation**: Original instruction outputs are captured and stored
3. **No Modifications**: Existing instructions remain unchanged
4. **Insights Collection**: PEER agents observe and collect insights from execution

## Git Workflow Enhancement

Instead of modifying the git-workflow agent, create a new git instruction that can be executed through PEER to add MCP precommit validation:

### New Instruction: git-commit

Create `@instructions/core/git-commit.md` that orchestrates git operations with optional MCP validation:

```markdown
---
description: Git commit workflow with optional MCP precommit validation
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Git Commit Workflow

Execute git commit operations with optional Zen MCP precommit validation.

## Usage Examples

### Through PEER (recommended for MCP validation):
```bash
# PEER will check MCP availability and run precommit if available
/peer --instruction=git-commit

# With specific commit message
/peer --instruction=git-commit --message="feat: implement user authentication"

# Skip MCP check even if available
/peer --instruction=git-commit --skip-precommit
```

### Direct execution (bypasses MCP check):
```bash
# Direct execution always skips MCP precommit
/git-commit --message="fix: resolve login issue"
```

## Process Flow

1. Check if executed through PEER (has MCP checking capability)
2. If through PEER and MCP available, run precommit validation
3. Show any issues to user for approval
4. Delegate to git-workflow agent for actual git operations
```

### How PEER Enhances git-commit

When executed through PEER, the executor adds MCP validation:

```yaml
peer_executor_git_handling:
  detect_instruction: git-commit
  pre_execution:
    - check: mcp__zen tools available
    - if_available:
        - run: mcp__zen__precommit
        - show: results to user
        - await: user decision to proceed
    - store: validation results in cycle
  execute:
    - delegate: git-workflow agent
    - pass: commit message and options
    - include: precommit status in context
```

### Usage Flow Example

```bash
# User wants to commit with validation
$ /peer --instruction=git-commit --message="feat: add password reset"

PEER Planning: Analyzing git-commit instruction...
PEER Executing: 
  ✓ Detected Zen MCP available
  ✓ Running precommit validation...
  
  Precommit Results:
  - ⚠️  Missing test coverage for PasswordResetService
  - ⚠️  TODO comment found in auth.go:45
  - ✓ No security issues detected
  
  Proceed with commit? (yes/no): yes
  
  ✓ Delegating to git-workflow agent...
  ✓ Committed: "feat: add password reset"
  ✓ Pushed to origin/feature-password-reset
  
PEER Express: Successfully committed with precommit validation
PEER Review: Validation issues documented for future reference
```

### Benefits

1. **Backwards Compatible**: Existing git-workflow agent unchanged
2. **Optional Enhancement**: MCP validation only when available
3. **User Control**: Always shows issues before proceeding
4. **Multiple Paths**: 
   - `/peer --instruction=git-commit` (with MCP)
   - `/git-commit` (direct, no MCP)
   - Use git-workflow agent directly (unchanged)
5. **PEER Learning**: Review phase captures validation patterns

### Implementation in PEER Executor

The peer-executor agent would handle git-commit specially:

```markdown
# In peer-executor.md

### Special Instruction Handling

#### Git Commit Operations
When instruction is "git-commit":

1. **Check MCP Availability**
   ```bash
   # Check if mcp__zen__precommit is available
   if Task tool can access mcp__zen__precommit; then
     mcp_available=true
   fi
   ```

2. **Run Precommit if Available**
   ```
   IF mcp_available AND NOT --skip-precommit:
     <Task>
       description: "Run MCP precommit validation"
       prompt: "Use mcp__zen__precommit to validate current git changes"
       subagent_type: general-purpose
     </Task>
     
     IF validation_issues:
       PRESENT issues to user
       ASK: "Proceed with commit despite issues? (yes/no)"
       IF user_says_no:
         STOP execution
         RETURN: "Commit cancelled due to validation issues"
   ```

3. **Delegate to git-workflow**
   ```
   <Task>
     description: "Execute git commit workflow"
     prompt: |
       Complete git workflow with these parameters:
       - Message: ${commit_message}
       - MCP Validation: ${mcp_available ? "Completed" : "Not available"}
       ${validation_passed ? "- Validation: Passed" : ""}
       
       Use the git-workflow agent to handle all git operations.
     subagent_type: git-workflow
   </Task>
   ```

4. **Store Validation Results**
   Update cycle with MCP validation details for Review phase insights
```

## Future Considerations

- **Embeddings**: KV insights data can be used for similarity search
- **Learning**: Pattern recognition across multiple spec executions  
- **Optimization**: Identify common issues and automate solutions

## NATS CLI Integration

### Prerequisites
- NATS server must be running
- NATS CLI (`nats`) command must be available
- Proper NATS connection context configured

### KV Bucket Configuration
- **Bucket Name**: `agent-os-peer-state`
- **Replicas**: 3 (for redundancy)
- **History**: 50 (keep last 50 revisions)
- **TTL**: None (tasks may be resumed after extended periods)

### Bucket Creation (One-time Setup)
```bash
nats kv add agent-os-peer-state --replicas=3 --history=50
```

### NATS CLI Commands Reference

#### 1. Check NATS Availability
```bash
# List all KV buckets (verifies NATS connection)
nats kv ls
```

#### 2. Create/Update Meta Key
```bash
# Create or update meta key
echo '{"spec_name":"password-reset-flow","created_at":"2025-08-04T10:00:00Z","current_cycle":1,"current_phase":"plan","cycles":{"1":{"instruction":"create-spec","status":"running","started_at":"2025-08-04T10:00:00Z"}}}' | nats kv put agent-os-peer-state peer.spec.password-reset-flow.meta
```

#### 3. Get Meta Key
```bash
# Retrieve meta key value
nats kv get agent-os-peer-state peer.spec.password-reset-flow.meta --raw
```

#### 4. Check if Key Exists
```bash
# Check existence (non-zero exit code if not found)
nats kv get agent-os-peer-state peer.spec.password-reset-flow.meta > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Key exists"
else
  echo "Key not found"
fi
```

#### 5. Create/Update Cycle Key
```bash
# Store cycle data
echo '{"cycle_number":1,"instruction":"create-spec","started_at":"2025-08-04T10:00:00Z","phases":{}}' | nats kv put agent-os-peer-state peer.spec.password-reset-flow.cycle.1
```

#### 6. List Keys for a Spec
```bash
# Find all keys for a specific spec
nats kv ls agent-os-peer-state | grep "peer.spec.password-reset-flow"
```

### Error Handling
- Non-zero exit codes indicate errors
- Use `2>&1` to capture error messages
- Parse JSON responses when needed

## Installation Script Updates

### Required Updates to setup.sh

The following files need to be added to the base Agent OS installation script:

#### Core Instructions Section
Add to the core instructions download section (after line 200):

```bash
# peer.md
if [ -f "$HOME/.agent-os/instructions/core/peer.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/peer.md already exists - skipping"
else
    curl -s -o "$HOME/.agent-os/instructions/core/peer.md" "${BASE_URL}/instructions/core/peer.md"
    if [ -f "$HOME/.agent-os/instructions/core/peer.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/peer.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/peer.md"
    fi
fi

# git-commit.md
if [ -f "$HOME/.agent-os/instructions/core/git-commit.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "    ⚠️  ~/.agent-os/instructions/core/git-commit.md already exists - skipping"
else
    curl -s -o "$HOME/.agent-os/instructions/core/git-commit.md" "${BASE_URL}/instructions/core/git-commit.md"
    if [ -f "$HOME/.agent-os/instructions/core/git-commit.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "    ✓ ~/.agent-os/instructions/core/git-commit.md (overwritten)"
    else
        echo "    ✓ ~/.agent-os/instructions/core/git-commit.md"
    fi
fi
```

#### Scripts Section
Add to the scripts download section (after instructions):

```bash
# PEER Scripts
echo "  📂 Creating scripts directory..."
mkdir -p "$HOME/.agent-os/scripts/peer"

scripts=("check-nats-health.sh" "setup-kv-bucket.sh" "parse-arguments.sh" "determine-context.sh" "initialize-cycle.sh" "finalize-cycle.sh")

for script in "${scripts[@]}"; do
    if [ -f "$HOME/.agent-os/scripts/peer/${script}" ] && [ "$OVERWRITE_SCRIPTS" = false ]; then
        echo "    ⚠️  ~/.agent-os/scripts/peer/${script} already exists - skipping"
    else
        curl -s -o "$HOME/.agent-os/scripts/peer/${script}" "${BASE_URL}/scripts/peer/${script}"
        chmod +x "$HOME/.agent-os/scripts/peer/${script}"
        if [ -f "$HOME/.agent-os/scripts/peer/${script}" ] && [ "$OVERWRITE_SCRIPTS" = true ]; then
            echo "    ✓ ~/.agent-os/scripts/peer/${script} (overwritten)"
        else
            echo "    ✓ ~/.agent-os/scripts/peer/${script}"
        fi
    fi
done
```

### Required Updates to setup-claude-code.sh

The following files need to be added to the Claude Code setup script:

#### Commands Section
Update the commands loop (line 40) to include the new commands:

```bash
# Commands
for cmd in plan-product create-spec execute-tasks analyze-product peer git-commit; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ]; then
        echo "  ⚠️  ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/commands/${cmd}.md" "${BASE_URL}/commands/${cmd}.md"
        echo "  ✓ ~/.claude/commands/${cmd}.md"
    fi
done
```

#### Agents Section
Update the agents array (line 54) to include the PEER agents:

```bash
# List of agent files to download
agents=("test-runner" "context-fetcher" "git-workflow" "file-creator" "date-checker" "peer-planner" "peer-executor" "peer-express" "peer-review")
```

#### Usage Instructions
Add to the usage instructions section (after line 82):

```bash
echo "Execute any instruction through PEER pattern with:"
echo "  /peer --instruction=<name>"
echo ""
echo "Continue a PEER execution with:"
echo "  /peer --continue"
echo ""
echo "Execute git commits with MCP validation (when available):"
echo "  /peer --instruction=git-commit"
echo ""
```

### File Manifest for Installation

The following files are created by the PEER pattern implementation and need to be included in installation:

#### Instruction Files
- `instructions/core/peer.md` - Main PEER orchestration instruction
- `instructions/core/git-commit.md` - Git commit workflow instruction

#### Command Files
- `commands/peer.md` - PEER slash command
- `commands/git-commit.md` - Git commit slash command

#### Agent Files (Claude Code specific)
- `claude-code/agents/peer-planner.md` - Planning phase agent
- `claude-code/agents/peer-executor.md` - Execution phase agent  
- `claude-code/agents/peer-express.md` - Express phase agent
- `claude-code/agents/peer-review.md` - Review phase agent

#### Script Files
- `scripts/peer/check-nats-health.sh` - NATS health check with caching
- `scripts/peer/setup-kv-bucket.sh` - KV bucket setup
- `scripts/peer/parse-arguments.sh` - Argument parsing
- `scripts/peer/determine-context.sh` - Context determination
- `scripts/peer/initialize-cycle.sh` - Cycle initialization
- `scripts/peer/finalize-cycle.sh` - Cycle finalization

#### Prerequisites
- NATS server must be running for PEER pattern to function
- NATS CLI (`nats`) command must be available in PATH
- MCP Zen tools are optional but enhance git-commit functionality

### Installation Verification

After installation, verify the PEER pattern is properly installed:

```bash
# Check instruction files
ls -la ~/.agent-os/instructions/core/peer.md
ls -la ~/.agent-os/instructions/core/git-commit.md

# Check command files (Claude Code)
ls -la ~/.claude/commands/peer.md
ls -la ~/.claude/commands/git-commit.md

# Check agent files (Claude Code)
ls -la ~/.claude/agents/peer-*.md

# Verify NATS availability
nats --version
nats server check
```