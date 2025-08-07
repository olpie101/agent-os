# Spec Tasks

## Tasks

- [x] 1. Analyze Current Agent OS Process Pattern
  - [x] 1.1 Write tests that validate process flow structure matches Agent OS pattern
  - [x] 1.2 Document XML-like step structure from execute-tasks.md and create-spec.md
  - [x] 1.3 Identify subagent delegation patterns and instruction formats
  - [x] 1.4 Map conditional logic and decision tree structures used in other instructions
  - [x] 1.5 Analyze error handling patterns in existing process flows
  - [x] 1.6 Document the notification_command pattern for reference commands
  - [x] 1.7 Verify understanding of process coordination vs script orchestration
  - [x] 1.8 Create reference guide for Agent OS process design patterns

- [x] 2. Design PEER Process Flow Structure  
  - [x] 2.1 Write tests for PEER process flow validation
  - [x] 2.2 Design XML-like process_flow structure with numbered steps
  - [x] 2.3 Define step delegation to peer-planner subagent with proper instructions
  - [x] 2.4 Define step delegation to peer-executor subagent with proper instructions  
  - [x] 2.5 Define step delegation to peer-express subagent with proper instructions
  - [x] 2.6 Define step delegation to peer-review subagent with proper instructions
  - [x] 2.7 Add argument parsing and validation through process logic
  - [x] 2.8 Verify process flow design follows Agent OS patterns consistently

- [x] 3. Implement Process Validation and Decision Trees
  - [x] 3.1 Write tests for phase validation and conditional logic
  - [x] 3.2 Add conditional logic to ensure Execute phase runs before Express phase
  - [x] 3.3 Add decision trees for handling different instruction types
  - [x] 3.4 Implement validation checkpoints between phase transitions
  - [x] 3.5 Add error handling through conditional blocks and flow control
  - [x] 3.6 Create process state validation without external dependencies
  - [x] 3.7 Add user interaction handling through process flow
  - [x] 3.8 Verify all validation logic works through process coordination

- [x] 4. Add NATS CLI Reference Commands and Remove Script Dependencies
  - [x] 4.1 Write tests verifying no external script dependencies exist
  - [x] 4.2 Add NATS CLI command examples following notification_command pattern
  - [x] 4.3 Remove all calls to ~/.agent-os/scripts/peer/*.sh files from peer.md
  - [x] 4.4 Convert script functionality to process logic and subagent delegation
  - [x] 4.5 Add NATS server validation through process instructions rather than scripts
  - [x] 4.6 Include KV bucket setup instructions as process guidance
  - [x] 4.7 Document NATS CLI commands as reference examples only
  - [x] 4.8 Verify complete elimination of script orchestration dependencies

- [ ] 5. Validate Process-Based PEER Implementation  
  - [ ] 5.1 Write comprehensive tests for complete PEER process flow
  - [ ] 5.2 Test process flow handles Execute phase validation correctly
  - [ ] 5.3 Test process flow prevents false success reporting through validation logic
  - [ ] 5.4 Test subagent coordination follows Agent OS patterns
  - [ ] 5.5 Test conditional logic handles runtime issues appropriately
  - [ ] 5.6 Test process flow maintains backward compatibility with existing subagents
  - [ ] 5.7 Verify process-based approach eliminates all script failure modes
  - [ ] 5.8 Validate redesigned peer.md follows Agent OS instruction standards
