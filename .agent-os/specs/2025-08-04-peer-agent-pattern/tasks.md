# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-04-peer-agent-pattern/spec.md

> Created: 2025-08-04
> Status: Ready for Implementation

## Tasks

- [ ] 1. Create PEER slash command and instruction file
  - [x] 1.1 Create @commands/peer.md file following existing command pattern
  - [x] 1.2 Create @instructions/core/peer.md as main orchestration file
  - [x] 1.3 Implement command parsing for --instruction, --continue, and --spec flags
  - [x] 1.4 Add NATS CLI integration for state checking using Bash tool
  - [x] 1.5 Create pre-flight check for NATS server availability
  - [x] 1.6 Implement spec determination logic (explicit or latest)
  - [x] 1.7 Implement instruction classification (spec-aware vs non-spec)
  - [ ] 1.8 Test slash command invocation patterns

- [ ] 2. Implement PEER phase agents
  - [x] 2.1 Create @claude-code/agents/peer-planner.md agent with instruction decomposition
  - [x] 2.2 Create @claude-code/agents/peer-executor.md agent that delegates to instruction subagents
  - [x] 2.3 Create @claude-code/agents/peer-express.md agent for output formatting
  - [x] 2.4 Create @claude-code/agents/peer-review.md agent for quality assessment
  - [x] 2.5 Add NATS CLI state updates to each agent using Bash tool
  - [ ] 2.6 Test phase transitions and state persistence

- [x] 3. Configure NATS KV storage
  - [x] 3.1 Verify bucket exists with correct configuration (replicas=3, history=50)
  - [x] 3.2 Implement KV operations using NATS CLI commands via Bash
  - [x] 3.3 Create helper patterns for JSON construction and parsing
  - [x] 3.4 Implement cycle key storage with phase outputs
  - [x] 3.5 Test state persistence and retrieval

- [ ] 4. Implement continuation support
  - [x] 4.1 Add state detection logic for --continue flag
  - [x] 4.2 Implement phase resumption from stored state
  - [x] 4.3 Handle partial phase completions
  - [ ] 4.4 Test continuation across different phases
  - [ ] 4.5 Verify insights preservation on continuation

- [x] 5. Create git-commit instruction with PEER enhancement
  - [x] 5.1 Create @instructions/core/git-commit.md instruction file
  - [x] 5.2 Implement MCP availability detection in PEER executor
  - [x] 5.3 Add special git-commit handling to peer-executor agent
  - [x] 5.4 Integrate mcp__zen__precommit workflow when available
  - [x] 5.5 Implement fallback to standard git-workflow delegation
  - [ ] 5.6 Test both MCP and non-MCP execution scenarios

- [x] 6. Update installation scripts
  - [x] 6.1 Document required updates to setup.sh for new instruction files
  - [x] 6.2 Document required updates to setup-claude-code.sh for commands and agents
  - [x] 6.3 Create file manifest listing all PEER pattern files
  - [x] 6.4 Add installation verification steps
  - [x] 6.5 Update setup.sh to include peer.md and git-commit.md instructions
  - [x] 6.6 Update setup-claude-code.sh commands loop to include peer and git-commit
  - [x] 6.7 Update setup-claude-code.sh agents array to include PEER phase agents
  - [x] 6.8 Update setup-claude-code.sh usage instructions with PEER examples
  - [ ] 6.9 Test installation script updates on clean system

## Critical Issues Discovered During Testing

### Test Result: `/peer --instruction=create-spec` 
- ✅ Agents executed in sequence (planner → executor → express → review)
- ✅ Create-spec functionality worked correctly
- ❌ No NATS operations occurred (state management completely non-functional)
- ❌ peer.md instruction was bypassed (Claude invoked agents directly)
- ❌ Agent parameters don't match expectations

## Required Fixes Based on Test Analysis

- [ ] 7. Fix peer.md instruction structure to follow working patterns
  - [ ] 7.1 Move NATS pre-flight checks from `<pre_flight_check>` descriptions to executable `<step>` elements
  - [ ] 7.2 Add NATS server availability check as Step 1 using Bash tool
  - [ ] 7.3 Add NATS KV bucket creation/verification as Step 2 using Bash tool
  - [ ] 7.4 Add argument parsing and validation as Step 3
  - [ ] 7.5 Add context determination (spec vs non-spec instructions) as Step 4
  - [ ] 7.6 Restructure agent invocation steps to follow create-spec.md pattern
  - [ ] 7.7 Add cycle metadata creation and updates in each step using Bash tool
  - [ ] 7.8 Test that NATS operations actually execute during instruction run

- [ ] 8. Fix Task tool agent parameter passing
  - [ ] 8.1 Review how create-spec.md passes parameters to subagents via Task tool
  - [ ] 8.2 Update peer.md Task tool calls to match working parameter patterns
  - [ ] 8.3 Ensure agents receive context in the format they expect
  - [ ] 8.4 Test agent parameter passing with structured data

- [ ] 9. Resolve PEER vs instruction workflow conflicts
  - [ ] 9.1 Handle create-spec user review conflict (spec review happens inside create-spec, not in PEER review)
  - [ ] 9.2 Clarify PEER review phase purpose when wrapped instruction already has review steps
  - [ ] 9.3 Test PEER with instructions that don't have built-in user review (analyze-product)
  - [ ] 9.4 Document when PEER review adds value vs when it conflicts

- [ ] 10. Validate executable instruction approach
  - [ ] 10.1 Compare peer.md structure with working instructions (create-spec.md, execute-tasks.md) 
  - [ ] 10.2 Ensure all NATS operations use actual Bash tool calls, not descriptions
  - [ ] 10.3 Test `/peer --continue` functionality works with proper state persistence
  - [ ] 10.4 Verify pre-flight execution actually happens before process flow