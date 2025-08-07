# Spec Requirements Document

> Spec: PEER Agent Pattern Implementation
> Created: 2025-08-04

## Overview

Implement PEER (Plan, Execute, Express, Review) agent pattern in Agent OS as a slash command that orchestrates any instruction through four phases. The `/peer` command will use NATS CLI for state management and support continuation of interrupted executions, improving task decomposition, execution quality, and output consistency.

**Status Update**: Initial testing revealed critical execution issues that require fixes before the pattern can function as designed.

## User Stories

### Slash Command Usage

As an Agent OS developer, I want to use the `/peer` slash command to run any instruction through the PEER pattern, so that complex tasks are automatically broken down, executed, presented, and reviewed with consistent quality.

Usage patterns:
- `/peer --instruction=create-spec` - Run create-spec through PEER phases
- `/peer --instruction=execute-tasks` - Run execute-tasks through PEER phases  
- `/peer --continue` - Resume from last incomplete phase using NATS KV state

### Automated Quality Assurance

As a user of Agent OS, I want automated review of generated outputs, so that I receive high-quality, consistent results without manual quality checks.

The Review agent will automatically evaluate outputs from the Express agent, checking for completeness, accuracy, and adherence to standards. If quality issues are detected, it can initiate another PEER cycle with specific feedback for improvement.

## Spec Scope

1. **Slash Command Implementation** - Create `/peer` command that orchestrates any instruction through Plan, Execute, Express, Review phases
2. **NATS CLI Integration** - Use NATS CLI for cycle-based state storage with meta key tracking and phase outputs
3. **Continuation Support** - Enable `/peer --continue` to resume from last incomplete phase using stored state
4. **Agent Files Only** - Implement entirely through markdown agent files without external scripts or code
5. **Git Workflow Enhancement** - Update git-workflow agent to use Zen MCP precommit when available

## Out of Scope

- Modifying existing agents (context-fetcher, date-checker, file-creator, git-workflow, test-runner)
- Changing the base agent framework or core Agent OS architecture
- Creating UI or visual representations of PEER cycles
- Implementing PEER pattern in non-core instructions

## Issues Discovered During Testing

### Test Execution: `/peer --instruction=create-spec`

**What Worked:**
- Agents executed in correct sequence (planner → executor → express → review)
- Create-spec functionality completed successfully
- Spec files were created with accurate content

**Critical Issues Identified:**

1. **NATS State Management Not Functioning**
   - No NATS KV operations occurred during execution
   - Only peer-express agent checked NATS availability
   - No cycle metadata or phase outputs were stored
   - Continuation support cannot work without state persistence

2. **Peer Instruction Structure Problem**
   - The peer.md instruction contains NATS operations as descriptions rather than executable steps
   - Pre-flight check contains detailed Bash commands but they're in descriptive XML blocks, not actual steps
   - Claude bypassed the instruction orchestration and directly invoked agents
   - The instruction follows create-spec.md patterns but NATS operations aren't in executable steps

3. **Agent Parameter Mismatch**
   - Task tool invocations don't pass the parameters agents expect
   - Agents expect structured context (meta_data, cycle_number, etc.) but receive simple descriptions

4. **Missing User Review Integration**
   - PEER review phase conflicts with built-in create-spec user review
   - User wasn't prompted to review spec before PEER execution continued
   - Two different review mechanisms operating independently

5. **Complex Bash Scripts in Instructions**
   - Current bash scripts embedded in instruction file are too complex with heredocs and multi-line logic
   - Shell variable conflicts (e.g., 'history' is a reserved variable)
   - Parser errors due to complex nesting and escaping issues

### Root Cause Analysis

Comparing with working instructions like create-spec.md, the issue is that peer.md has NATS operations written as descriptive content in `<pre_flight_check>` rather than as executable process steps. The XML blocks contain bash commands but they're documentation, not actual tool invocations that Claude executes. Working instructions put executable operations in `<step>` elements with proper tool calls.

### Additional Requirements Based on Execution Issues

1. **Script Extraction**: Complex bash operations should be extracted into separate, self-documenting script files in `dev/agent-os/scripts/peer/` directory
2. **Intelligent Caching**: Infrastructure checks (NATS availability, bucket existence) should be cached and only run when necessary (e.g., once per day or on connectivity failure)
3. **Simplified Logic**: Some operations can be inferred from input rather than requiring bash scripts (e.g., argument parsing, context determination)

## Expected Deliverable

1. Slash command implementation supporting `/peer --instruction=<name>` and `/peer --continue` patterns
2. PEER instruction file that orchestrates the pattern and four phase agent markdown files for execution
3. Complete execution history in NATS KV with cycle-based tracking and phase output preservation
4. **[UPDATED]** Fixed peer.md instruction that actually executes NATS operations using tool calls
5. **[UPDATED]** Proper agent parameter passing for seamless integration
6. **[NEW]** External script files in `dev/agent-os/scripts/peer/` directory for complex operations
7. **[NEW]** Intelligent caching mechanism for infrastructure checks to reduce overhead
8. **[NEW]** Self-documenting scripts with clear parameters and return values
9. **[NEW]** Trap-based cleanup for all script-local temporary files to prevent data contamination