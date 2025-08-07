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

- [x] 7. Create external script files for complex operations
  - [x] 7.1 Create dev/agent-os/scripts/peer/ directory structure
  - [x] 7.2 Write check-nats-health.sh with 24-hour caching logic
  - [x] 7.3 Write setup-kv-bucket.sh for bucket creation and verification
  - [x] 7.4 Write parse-arguments.sh to handle command-line arguments
  - [x] 7.5 Write determine-context.sh for instruction classification
  - [x] 7.6 Write initialize-cycle.sh for PEER cycle setup
  - [x] 7.7 Write finalize-cycle.sh for cycle completion
  - [x] 7.8 Add self-documentation headers to all scripts
  - [x] 7.9 Test scripts independently to ensure proper functionality

- [x] 8. Fix peer.md instruction structure to use external scripts
  - [x] 8.1 Replace complex inline bash with script calls in Step 1 (NATS health)
  - [x] 8.2 Replace bucket setup logic with script call in Step 2
  - [x] 8.3 Use parse-arguments.sh in Step 3 instead of inline parsing
  - [x] 8.4 Use determine-context.sh in Step 4 for classification
  - [x] 8.5 Use initialize-cycle.sh in Step 5 for cycle creation
  - [x] 8.6 Update agent invocation steps to use context from scripts
  - [x] 8.7 Use finalize-cycle.sh in final step for cleanup
  - [ ] 8.8 Test that scripts execute properly through instruction

- [x] 9. Fix Task tool agent parameter passing
  - [x] 9.1 Review how create-spec.md passes parameters to subagents via Task tool
  - [x] 9.2 Update peer.md Task tool calls to match working parameter patterns
  - [x] 9.3 Ensure agents receive context in the format they expect
  - [ ] 9.4 Test agent parameter passing with structured data

- [ ] 10. Resolve PEER vs instruction workflow conflicts
  - [ ] 10.1 Handle create-spec user review conflict (spec review happens inside create-spec, not in PEER review)
  - [ ] 10.2 Clarify PEER review phase purpose when wrapped instruction already has review steps
  - [ ] 10.3 Test PEER with instructions that don't have built-in user review (analyze-product)
  - [ ] 10.4 Document when PEER review adds value vs when it conflicts

- [ ] 11. Validate executable instruction approach
  - [ ] 11.1 Compare peer.md structure with working instructions (create-spec.md, execute-tasks.md) 
  - [ ] 11.2 Ensure all NATS operations use actual Bash tool calls, not descriptions
  - [ ] 11.3 Test `/peer --continue` functionality works with proper state persistence
  - [ ] 11.4 Verify pre-flight execution actually happens before process flow

- [x] 12. Update installation scripts for script files
  - [x] 12.1 Add scripts directory creation to setup.sh
  - [x] 12.2 Add script download loop to setup.sh
  - [x] 12.3 Set executable permissions on downloaded scripts
  - [x] 12.4 Add script verification to installation process
  - [ ] 12.5 Test complete installation on clean system

- [x] 13. Implement trap-based cleanup for script-local temp files
  - [x] 13.1 Add trap cleanup to setup-kv-bucket.sh for /tmp/bucket_info.txt
  - [x] 13.2 Add trap cleanup to initialize-cycle.sh for JSON files (/tmp/current_meta.json, /tmp/existing_meta.json, /tmp/updated_meta.json, /tmp/new_cycle.json)
  - [x] 13.3 Add trap cleanup to finalize-cycle.sh for JSON files (/tmp/final_meta.json, /tmp/final_meta_updated.json, /tmp/final_cycle.json, /tmp/final_cycle_updated.json)
  - [x] 13.4 Ensure communication files (/tmp/peer_*.txt) are NOT cleaned by trap handlers
  - [x] 13.5 Update finalize-cycle.sh to clean communication files only on successful completion
  - [x] 13.6 Test trap cleanup functions work correctly on both normal exit and error conditions
  - [x] 13.7 Verify no file contamination occurs between script runs