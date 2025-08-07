# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/spec.md

> Created: 2025-08-05
> Updated: 2025-08-06
> Status: Implementation In Progress (Simplified v1)
> Approach: Simplified first iteration without optimistic locking
> Reference: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/implementation/peer-md-alignment-requirements.md

## Phase 1: Critical Prerequisite - Key Delimiter Correction

- [x] 1. Fix NATS KV Key Delimiter Issues Across All Files
  - [x] 1.1 Search all peer agent files for `:` delimiter usage in key patterns
  - [x] 1.2 Replace ALL occurrences of `:` with `.` in NATS KV key patterns (e.g., `peer:spec:name` → `peer.spec.name`)
  - [x] 1.3 Update peer.md instruction file key patterns from `:` to `.`
  - [x] 1.4 Update peer-planner.md key patterns from `:` to `.` (only one instance found in event)
  - [x] 1.5 Update peer-executor.md key patterns from `:` to `.` (verified clean)
  - [x] 1.6 Update peer-express.md key patterns from `:` to `.` (verified clean)
  - [x] 1.7 Update peer-review.md key patterns from `:` to `.` (verified clean)
  - [x] 1.8 Verify no `:` delimiters remain in any NATS KV key patterns
  - [x] 1.9 Document delimiter change in implementation notes (created delimiter-change-log.md)

## Phase 2: Create Central Schema Definition

- [x] 2. Create Unified State Schema File
  - [x] 2.1 Create new file `instructions/meta/unified_state_schema.md`
  - [x] 2.2 Add schema version header (Version: 1 - Simplified, no locking)
  - [x] 2.3 Define metadata fields (instruction_name, spec_name, key_prefix, cycle_number, timestamps, status)
  - [x] 2.4 Define context fields (peer_mode, spec_aware, user_requirements)
  - [x] 2.5 Define phases structure (plan, execute, express, review with status/output/timestamps)
  - [x] 2.6 EXCLUDE all sequence number fields (no sequence, sequence_at_start, sequence_at_complete)
  - [x] 2.7 EXCLUDE history arrays (keep v1 simple)
  - [x] 2.8 Add clear field descriptions and constraints for each field
  - [x] 2.9 Add JSON example showing complete unified state object
  - [x] 2.10 Add usage examples for reading and writing state
  - [x] 2.11 Document strict phase ownership rules (each agent updates only its phase)
  - [x] 2.12 Ensure all examples use `.` delimiter for keys

## Phase 3: Update peer.md Instruction File

- [x] 3. Align peer.md with Unified State Model
  - [x] 3.1 Add reference to `@instructions/meta/unified_state_schema.md` at top of file
  - [x] 3.2 Update Step 5 (Cycle Initialization) to create single unified state object
  - [x] 3.3 Remove fragmented state creation (metadata, plan, execution, express, review as separate keys)
  - [x] 3.4 Create unified state JSON with all phases initialized to "pending"
  - [x] 3.5 Store unified state at single key: `[KEY_PREFIX].cycle.[CYCLE_NUMBER]`
  - [x] 3.6 Update Step 7 (Planning) to pass STATE_KEY instead of multiple parameters
  - [x] 3.7 Update Step 8 (Execution) to read unified state and check phases.plan.status
  - [x] 3.8 Update Step 9 (Express) to read unified state and check phases.execute.status
  - [x] 3.9 Update Step 10 (Review) to pass single STATE_KEY for all phase data
  - [x] 3.10 Update Step 11 (Completion) to update unified state metadata.status
  - [x] 3.11 Remove ALL references to separate phase keys
  - [x] 3.12 Ensure all NATS operations use simple read/write (no sequence checks)

## Phase 4: Transform peer-planner.md to Simplified v1

- [x] 4. Remove Optimistic Locking from peer-planner.md
  - [x] 4.1 Remove ALL references to "sequence" fields in input contract
  - [x] 4.2 Remove ALL references to "optimistic locking" in documentation
  - [x] 4.3 Remove `sequence (for optimistic locking)` from expected state fields
  - [x] 4.4 Remove `sequence (incremented)` from output contract
  - [x] 4.5 Remove `use_optimistic_lock: true` from any configurations
  - [x] 4.6 Replace `<nats_operation type="kv_read_with_sequence">` with simple `kv_read`
  - [x] 4.7 Remove `<capture_sequence>true</capture_sequence>` directives
  - [x] 4.8 Remove all sequence validation checks
  - [x] 4.9 Replace complex retry logic with simple read-modify-write pattern
  - [x] 4.10 Update state write operations to use simple `nats kv put` without ExpectedRevision
  - [x] 4.11 Add reference to `@instructions/meta/unified_state_schema.md`
  - [x] 4.12 Update to read full unified state from single key
  - [x] 4.13 Modify only `phases.plan` section of state
  - [x] 4.14 Write back full state object after updates
  - [x] 4.15 Remove ALL mentions of atomic operations, locking, or sequences

## Phase 5: Transform peer-executor.md to Simplified v1

- [x] 5. Remove Optimistic Locking from peer-executor.md
  - [x] 5.1 Remove ALL references to "sequence" fields in input contract
  - [x] 5.2 Remove ALL references to "optimistic locking" in documentation
  - [x] 5.3 Remove sequence capture and validation logic
  - [x] 5.4 Remove retry with backoff patterns for sequence conflicts
  - [x] 5.5 Replace `kv_update_with_lock` operations with simple `kv_write`
  - [x] 5.6 Remove `expected_sequence` parameters from all NATS operations
  - [x] 5.7 Remove `on_sequence_mismatch` error handlers
  - [x] 5.8 Update to read unified state from single key `[KEY_PREFIX].cycle.[CYCLE_NUMBER]`
  - [x] 5.9 Check `phases.plan.status == "completed"` before executing
  - [x] 5.10 Modify only `phases.execute` section of state
  - [x] 5.11 Update `metadata.status` to "EXECUTING" at start
  - [x] 5.12 Update `metadata.current_phase` to "execute"
  - [x] 5.13 Write back full state object after updates
  - [x] 5.14 Add reference to `@instructions/meta/unified_state_schema.md`
  - [x] 5.15 Remove ALL atomic operation references

## Phase 6: Transform peer-express.md to Simplified v1

- [x] 6. Remove Optimistic Locking from peer-express.md
  - [x] 6.1 Remove ALL references to "sequence" fields throughout file
  - [x] 6.2 Remove ALL optimistic locking documentation and comments
  - [x] 6.3 Remove sequence validation and retry logic
  - [x] 6.4 Replace complex NATS operations with simple read/write
  - [x] 6.5 Remove `use_optimistic_lock` configurations
  - [x] 6.6 Update to read unified state from single key
  - [x] 6.7 Check `phases.execute.status == "completed"` before expressing
  - [x] 6.8 Read plan output from `phases.plan.output`
  - [x] 6.9 Read execution results from `phases.execute.output`
  - [x] 6.10 Modify only `phases.express` section of state
  - [x] 6.11 Update `metadata.status` to "EXPRESSING"
  - [x] 6.12 Update `metadata.current_phase` to "express"
  - [x] 6.13 Write formatted presentation to `phases.express.output`
  - [x] 6.14 Add reference to `@instructions/meta/unified_state_schema.md`
  - [x] 6.15 Ensure simple read-modify-write pattern without locking

## Phase 7: Transform peer-review.md to Simplified v1

- [x] 7. Remove Optimistic Locking from peer-review.md
  - [x] 7.1 Remove ALL sequence number references from file
  - [x] 7.2 Remove ALL optimistic locking patterns and documentation
  - [x] 7.3 Remove retry mechanisms for sequence conflicts
  - [x] 7.4 Replace atomic operations with simple read/write
  - [x] 7.5 Remove `expected_sequence` and related parameters
  - [x] 7.6 Update to read unified state from single key
  - [x] 7.7 Check all phases completed (`plan`, `execute`, `express`)
  - [x] 7.8 Read all phase outputs for comprehensive review
  - [x] 7.9 Modify only `phases.review` section of state
  - [x] 7.10 Update `metadata.status` to "REVIEWING" then "COMPLETED"
  - [x] 7.11 Update `metadata.current_phase` to "review"
  - [x] 7.12 Write review insights to `phases.review.output`
  - [x] 7.13 Set `metadata.completed_at` timestamp on completion
  - [x] 7.14 Add reference to `@instructions/meta/unified_state_schema.md`
  - [x] 7.15 Ensure no locking or sequence references remain

## Phase 8: Critical Bug Fix - Spec Name Determination

- [x] 8. Fix create-spec KEY_PREFIX Issue
  - [x] 8.1 Identify that spec name determination happens AFTER KEY_PREFIX is set
  - [x] 8.2 Move spec name extraction logic from Step 6 into Step 4
  - [x] 8.3 Add conditional logic in Step 4 for create-spec instruction
  - [x] 8.4 Extract spec name from user requirements when --spec not provided
  - [x] 8.5 Set SPEC_NAME variable before KEY_PREFIX determination
  - [x] 8.6 Update KEY_PREFIX logic to use determined spec name
  - [x] 8.7 Remove or simplify Step 6 since determination now happens earlier
  - [x] 8.8 Update peer-planner.md Step 4 to handle pre-determined spec names
  - [ ] 8.9 Test that create-spec now uses correct peer.spec.[NAME] keys
  - [ ] 8.10 Verify spec name flows correctly to all PEER phases

## Phase 9: Standardize NATS KV Operations

- [ ] 9. Implement Standardized NATS KV Operations
  - [x] 9.1 Create `scripts/peer/read-state.sh` wrapper script
  - [x] 9.2 Create `scripts/peer/update-state.sh` wrapper script
  - [x] 9.3 Make both scripts executable with proper permissions
  - [x] 9.4 Create `instructions/meta/nats-kv-operations.md` documentation
  - [x] 9.4a Create `scripts/peer/create-state.sh` wrapper script for new keys
  - [x] 9.4b Update setup.sh to install wrapper scripts to ~/.agent-os/scripts/peer/
    - [x] 9.4b.1 Create scripts/peer directory in setup.sh
    - [x] 9.4b.2 Add download/copy commands for all three wrapper scripts
    - [x] 9.4b.3 Make scripts executable after installation
    - [x] 9.4b.4 Add nats-kv-operations.md to meta instructions download
  - [x] 9.4c Update instructions/meta/nats-kv-operations.md paths
    - [x] 9.4c.1 Update all script paths from scripts/peer/ to ~/.agent-os/scripts/peer/
    - [x] 9.4c.2 Update examples to use installed path
    - [x] 9.4c.3 Update testing commands to use installed path
  - [x] 9.5 Update peer.md Step 5 and Step 11 to use wrapper scripts from installed path
  - [x] 9.6 Update peer-planner.md to add pre-flight checks and use wrapper scripts
    - [x] 9.6.1 Add pre-flight check block at beginning
    - [x] 9.6.2 Remove all <to_stream> references
    - [x] 9.6.3 Replace direct NATS calls with wrapper scripts using ~/.agent-os/scripts/peer/ path
  - [x] 9.7 Update peer-executor.md to add pre-flight checks and use wrapper scripts
    - [x] 9.7.1 Add pre-flight check block at beginning
    - [x] 9.7.2 Remove all <to_stream> references
    - [x] 9.7.3 Replace direct NATS calls with wrapper scripts using ~/.agent-os/scripts/peer/ path
  - [x] 9.8 Update peer-express.md to add pre-flight checks and use wrapper scripts
    - [x] 9.8.1 Add pre-flight check block at beginning
    - [x] 9.8.2 Remove all <to_stream> references
    - [x] 9.8.3 Replace direct NATS calls with wrapper scripts using ~/.agent-os/scripts/peer/ path
  - [x] 9.9 Update peer-review.md to add pre-flight checks and use wrapper scripts
    - [x] 9.9.1 Add pre-flight check block at beginning
    - [x] 9.9.2 Remove all <to_stream> references
    - [x] 9.9.3 Replace direct NATS calls with wrapper scripts using ~/.agent-os/scripts/peer/ path
  - [x] 9.10 Remove ALL direct NATS CLI calls from agent files
  - [x] 9.11 Test wrapper scripts with sample state operations
    - [x] 9.11.1 Test create-state.sh with new test key
    - [x] 9.11.2 Test create-state.sh with duplicate key (error case)
    - [x] 9.11.3 Test read-state.sh with created test key
    - [x] 9.11.4 Test read-state.sh with non-existent key (error case)
    - [x] 9.11.5 Test update-state.sh with simple status update (fixed revision extraction bug)
    - [x] 9.11.6 Test update-state.sh with complex nested update
  - [x] 9.12 Verify error propagation works correctly
    - [x] 9.12.1 Test read-state.sh error output goes to stderr
    - [x] 9.12.2 Test update-state.sh JQ filter error handling
    - [x] 9.12.3 Test update-state.sh revision mismatch error
    - [x] 9.12.4 Verify exit codes are non-zero on errors
  - [x] 9.13 Verify JSON logging provides useful debugging info
    - [x] 9.13.1 Test small JSON shows full content
    - [x] 9.13.2 Test large JSON shows preview only
    - [x] 9.13.3 Verify revision number is logged
    - [x] 9.13.4 Verify JSON size is logged
  - [x] 9.14 Test complete PEER cycle with wrapper scripts
    - [x] 9.14.1 Initialize test state
    - [x] 9.14.2 Test planning phase update
    - [x] 9.14.3 Test execution phase update
    - [x] 9.14.4 Verify final state integrity
  - [ ] 9.15 Document recovery procedures for corrupted state

## Phase 10: PEER Coordinator Improvements

- [x] 10. Implement PEER Coordinator Enhancements
  - [x] 10.1 Update peer.md Step 5 with cycle number determination logic
    - [x] 10.1.1 Add logic to read current cycle from `[KEY_PREFIX].cycle.current`
    - [x] 10.1.2 Handle first cycle (returns null/empty) case
    - [x] 10.1.3 Increment cycle number correctly
    - [x] 10.1.4 Add safety check to prevent duplicate cycle numbers
    - [x] 10.1.5 Store new cycle number in `[KEY_PREFIX].cycle.current`
  - [x] 10.2 Add new Step 12 for review results display
    - [x] 10.2.1 Insert new step after Step 11 (cycle finalization)
    - [x] 10.2.2 Extract review output from unified state
    - [x] 10.2.3 Format quality scores and category breakdowns
    - [x] 10.2.4 Display strengths, improvements, and recommendations
    - [x] 10.2.5 Add helpful note about using refine-spec for improvements
  - [x] 10.3 Add refine-spec to spec_aware_instructions list in Step 4
    - [x] 10.3.1 Update the list to include refine-spec
    - [x] 10.3.2 Add refinement context logic for refine-spec
    - [x] 10.3.3 Extract previous cycle's review recommendations
    - [x] 10.3.4 Store recommendations in context for refine-spec use
  - [ ] 10.4 Test cycle number incrementing
    - [ ] 10.4.1 Test first cycle creation (should be 1)
    - [ ] 10.4.2 Test sequential cycle creation
    - [ ] 10.4.3 Test cycle creation after NATS restart
    - [ ] 10.4.4 Verify no duplicate cycles created
  - [ ] 10.5 Test review display functionality
    - [ ] 10.5.1 Run complete PEER cycle with test instruction
    - [ ] 10.5.2 Verify review results are displayed to user
    - [ ] 10.5.3 Test with missing review output (graceful handling)
    - [ ] 10.5.4 Verify formatting of scores and recommendations

## Phase 11: Refine-Spec Instruction Implementation

- [ ] 11. Create refine-spec Instruction
  - [x] 11.1 Create the refine-spec.md instruction file
    - [x] 11.1.1 Create file at `./instructions/core/refine-spec.md`
    - [x] 11.1.2 Add process flow with 10 steps
    - [x] 11.1.3 Ensure technical-spec.md is marked as required
    - [x] 11.1.4 Add conditional logic for spec.md and spec-lite.md updates
    - [x] 11.1.5 Add task preservation rules based on completion status
  - [x] 11.2 Implement spec identification logic (Step 1)
    - [x] 11.2.1 Handle --spec flag parameter
    - [x] 11.2.2 Extract spec name from user input
    - [x] 11.2.3 Find most recent spec if requested
    - [x] 11.2.4 Validate spec folder exists
    - [x] 11.2.5 Error gracefully if spec not found
  - [x] 11.3 Implement dynamic file loading (Step 2)
    - [x] 11.3.1 Load required files (spec.md, spec-lite.md, technical-spec.md, tasks.md)
    - [x] 11.3.2 Scan sub-specs/ directory for all .md files
    - [x] 11.3.3 Load all additional sub-specs dynamically
    - [x] 11.3.4 Extract context from all loaded files
  - [x] 11.4 Implement conditional update logic (Steps 4-8)
    - [x] 11.4.1 Conditionally update spec.md if affected
    - [x] 11.4.2 Conditionally regenerate spec-lite.md if spec.md changed
    - [x] 11.4.3 Update technical-spec.md if technical approach changes
    - [x] 11.4.4 Update other sub-specs as needed
    - [x] 11.4.5 Apply task preservation rules in tasks.md
  - [x] 11.5 Create refinement logging (Step 9)
    - [x] 11.5.1 Create or append to refinement-log.md
    - [x] 11.5.2 Record refinement date and reason
    - [x] 11.5.3 List changes made
    - [x] 11.5.4 Track source of refinement (user/review/implementation)
  - [ ] 11.6 Test refine-spec with uncompleted specs
    - [ ] 11.6.1 Create test spec with no completed tasks
    - [ ] 11.6.2 Run refine-spec with scope changes
    - [ ] 11.6.3 Verify tasks can be freely modified
    - [ ] 11.6.4 Verify no strikethrough applied
  - [ ] 11.7 Test refine-spec with completed tasks
    - [ ] 11.7.1 Create test spec with some completed tasks
    - [ ] 11.7.2 Run refine-spec with scope changes
    - [ ] 11.7.3 Verify completed checkmarks preserved
    - [ ] 11.7.4 Verify strikethrough applied to obsolete completed tasks
  - [ ] 11.8 Test PEER integration
    - [ ] 11.8.1 Run `/peer --instruction=create-spec` for test spec
    - [ ] 11.8.2 Get review recommendations from cycle
    - [ ] 11.8.3 Run `/peer --instruction=refine-spec` with same spec
    - [ ] 11.8.4 Verify recommendations passed to refine-spec
    - [ ] 11.8.5 Verify refinements incorporate recommendations

## Phase 12: Integration Testing and Validation

- [ ] 12. Test Simplified v1 Implementation
  - [ ] 12.1 Create test instruction for basic PEER cycle
  - [ ] 12.2 Initialize unified state with peer.md
  - [ ] 12.3 Verify peer-planner reads and updates state correctly
  - [ ] 12.4 Verify peer-executor reads plan and executes correctly
  - [ ] 12.5 Verify peer-express formats results properly
  - [ ] 12.6 Verify peer-review completes cycle successfully
  - [ ] 12.7 Inspect final unified state for completeness
  - [ ] 12.8 Test with spec-aware instruction (e.g., create-spec)
  - [ ] 12.9 Test with non-spec instruction
  - [ ] 12.10 Verify no temp files created during execution
  - [ ] 12.11 Verify all NATS keys use `.` delimiter
  - [ ] 12.12 Document any issues found during testing
  - [ ] 12.13 Verify state is readable at any point for debugging
  - [ ] 12.14 Confirm sequential orchestration prevents race conditions
  - [ ] 12.15 Create summary report of v1 implementation success

## Phase 13: Documentation and Cleanup

- [ ] 13. Finalize Documentation and Clean Up
  - [ ] 13.1 Update spec.md to reference peer-md-alignment-requirements.md
  - [ ] 13.2 Document simplified v1 approach in implementation notes
  - [ ] 13.3 Create migration guide from old fragmented state to unified state
  - [ ] 13.4 Document known limitations of v1 (no optimistic locking)
  - [ ] 13.5 Create troubleshooting guide for common issues
  - [ ] 13.6 Remove any remaining references to old patterns in comments
  - [ ] 13.7 Verify all files follow consistent formatting
  - [ ] 13.8 Create examples of reading state for debugging
  - [ ] 13.9 Document future v2 improvements (optimistic locking, history)
  - [ ] 13.10 Update README if applicable
  - [ ] 13.11 Archive old script-based implementations if needed
  - [ ] 13.12 Create checklist for v2 implementation
  - [ ] 13.13 Document performance characteristics of v1
  - [ ] 13.14 Create state inspection utilities/examples
  - [ ] 13.15 Final review and sign-off on v1 implementation
