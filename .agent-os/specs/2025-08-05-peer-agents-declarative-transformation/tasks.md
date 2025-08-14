# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/spec.md

> Created: 2025-08-05
> Updated: 2025-08-08
> Status: Implementation In Progress (Simplified v1)
> Approach: Simplified first iteration without optimistic locking
> Reference: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/implementation/peer-md-alignment-requirements.md
> 
> **IMPORTANT:** File pattern inconsistency identified in task 15.4.7. While file injection pattern was implemented,
> there's a mismatch in file naming conventions. See sub-specs/file-pattern-consistency.md for details.
> Task 15.4.7.5 attempted to fix this but introduced incorrect CYCLE_NUMBER extraction.
> Task 15.4.7.7 provides the correct fix.

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

## Phase 14: Hybrid Wrapper Script Enhancement for peer-express

- [x] 14. Implement Hybrid File Injection Support for peer-express
  - [x] 14.1 Enhance update-state.sh with --json-file support
    - [x] 14.1.1 Maintain backward compatibility with legacy mode (positional args only)
    - [x] 14.1.2 Add --json-file flag for loading JSON from files via --slurpfile
    - [x] 14.1.3 Validate file existence before attempting to load
    - [x] 14.1.4 Validate JSON syntax in files before injection
    - [x] 14.1.5 Validate variable names follow jq naming rules
    - [x] 14.1.6 Parse multiple --json-file arguments correctly
  - [x] 14.2 Update peer-express.md to use hybrid approach
    - [x] 14.2.1 Keep JQ filter as primary transformation logic
    - [x] 14.2.2 Use --json-file for complex JSON injection
    - [x] 14.2.3 Create temporary files in /tmp/peer-express/ directory
    - [x] 14.2.4 Add JSON validation before state update
    - [x] 14.2.5 Use $var[0] syntax for --slurpfile array access
    - [x] 14.2.6 Ensure all output arrays preserve full content (no truncation)
    - [x] 14.2.7 Store structured data only (no pre-formatted markdown in state)
  - [x] 14.3 Test hybrid wrapper functionality
    - [x] 14.3.1 Test legacy mode with direct KV test entries
    - [x] 14.3.2 Test --json-file with valid JSON files
    - [x] 14.3.3 Test --json-file with missing files (error handling)
    - [x] 14.3.4 Test --json-file with malformed JSON (validation)
    - [x] 14.3.5 Test invalid variable names (validation)
    - [x] 14.3.6 Test multiple --json-file arguments in one command
    - [x] 14.3.7 Verify no truncation occurs in output arrays
  - [x] 14.4 Document hybrid approach usage
    - [x] 14.4.1 Update nats-kv-operations.md with --json-file syntax
    - [x] 14.4.2 Add examples showing hybrid approach for complex JSON
    - [x] 14.4.3 Document that --slurpfile creates arrays (use $var[0])
    - [x] 14.4.4 Document temporary file location standard (/tmp/peer-express/)
    - [x] 14.4.5 Note that legacy mode remains default for simple updates
  - [x] 14.5 Standardize JSON creation to prevent --rawfile usage
    - [x] 14.5.1 Update json-creation-standards.md to clarify it applies when creating JSON
    - [x] 14.5.2 Specify jq with --arg as the ONLY approved method
    - [x] 14.5.3 Explicitly prohibit --rawfile in the standard
    - [x] 14.5.4 Add multi-line content handling pattern (file to variable to --arg)
    - [x] 14.5.5 Move implementation details to json-implementation-guide.md subspec
    - [x] 14.5.6 Add express agent specific requirements to implementation guide
    - [x] 14.5.7 Clarify Write tool usage as agent action (not bash command)
    - [x] 14.5.8 Reorder operations to show Write tool first, then bash script
    - [x] 14.5.9 Update all multi-line examples to use Write tool pattern
    - [x] 14.5.10 Add critical note that standard must provide multi-line examples
    - [x] 14.5.11 Update json-creation-standards.md to add complete multi-line examples
    - [x] 14.5.12 Show Write tool usage as agent action (outside bash context)
    - [x] 14.5.13 Add bash script example that reads file created by Write tool
    - [x] 14.5.14 Include express agent specific example with formatted markdown output

## Phase 15: Refine-Spec Agent Customization Integration

- [ ] 15. Add refine-spec customizations to all PEER agents
  - [x] 15.1 Update peer-planner.md with refine-spec customization
    - [x] 15.1.1 Add refine-spec planning customization after line 261
    - [x] 15.1.2 Include existing spec analysis phase
    - [x] 15.1.3 Add review recommendations integration
    - [x] 15.1.4 Plan documentation update steps
    - [x] 15.1.5 Include task status preservation planning
  - [x] 15.2 Update peer-executor.md with refine-spec delegation
    - [x] 15.2.1 Add refine-spec delegation context after line 329
    - [x] 15.2.2 Pass spec name parameter correctly
    - [x] 15.2.3 Include review recommendations if available
    - [x] 15.2.4 Add task preservation reminder
    - [x] 15.2.5 Reference refine-spec.md instruction guidelines
  - [x] 15.3 Update peer-express.md with refine-spec formatting
    - [x] 15.3.1 Add refine-spec next steps after line 206
    - [x] 15.3.2 Add refine-spec presentation template after line 263
    - [x] 15.3.3 Show spec name and files updated
    - [x] 15.3.4 List key changes and refinements applied
    - [x] 15.3.5 Display task status preservation metrics
  - [x] 15.4 Update peer-review.md with refine-spec criteria
    - [x] 15.4.1 Add refine-spec review focus after line 205
    - [x] 15.4.2 Check if changes address original requirements
    - [x] 15.4.3 Verify documentation consistency maintained
    - [x] 15.4.4 Validate task status properly preserved
    - [x] 15.4.5 Assess technical feasibility and clarity improvements
    - [x] 15.4.6 Correct pattern to match existing JSON structure format (SET review_focus)
  - [x] 15.4.7 Fix all peer agents to use file injection pattern for complex JSON (PARTIAL - needs consistency fix)
    - [x] 15.4.7.1 Fix peer-planner.md Step 6 (line 277) to use file injection
      - [x] 15.4.7.1.1 Add CREATE_DIR /tmp/peer-planner in planning_output_creation section
      - [x] 15.4.7.1.2 Replace direct --argjson with WRITE_TOOL file creation
      - [x] 15.4.7.1.3 Update JQ_FILTER to use $plan_out[0] (array access)
      - [x] 15.4.7.1.4 Use --json-file "plan_out=${PLAN_FILE}" with wrapper
      - [x] 15.4.7.1.5 Add cleanup: rm -f "${PLAN_FILE}"
    - [x] 15.4.7.2 Fix peer-review.md Steps 8-9 (lines 384-510) for file injection
      - [x] 15.4.7.2.1 Add write_review_files section at end of Step 8
      - [x] 15.4.7.2.2 Add CREATE_DIR /tmp/peer-review in Step 8
      - [x] 15.4.7.2.3 Write review_output and insights to files in Step 8
      - [x] 15.4.7.2.4 Modify Step 9 JQ_FILTER to use $review_out[0] and $insights_data[0]
      - [x] 15.4.7.2.5 Update Step 9 to use --json-file with both files
      - [x] 15.4.7.2.6 Add cleanup for both files in Step 9
    - [x] 15.4.7.3 Fix peer-executor.md Steps 7-8 (lines 366-436) for file injection
      - [x] 15.4.7.3.1 Add write_execution_files section at end of Step 7
      - [x] 15.4.7.3.2 Add CREATE_DIR /tmp/peer-executor in Step 7
      - [x] 15.4.7.3.3 Write execution_output to file in Step 7
      - [x] 15.4.7.3.4 Modify Step 8 JQ_FILTER to use $exec_output[0]
      - [x] 15.4.7.3.5 Update Step 8 to use --json-file "exec_output=${EXEC_FILE}"
      - [x] 15.4.7.3.6 Add cleanup: rm -f "${EXEC_FILE}" in Step 8
    - [x] 15.4.7.4 Verify peer-express.md pattern is reference implementation
      - [x] 15.4.7.4.1 Confirm Steps 6-7 (lines 339-444) remain unchanged
      - [x] 15.4.7.4.2 Document as correct reference pattern
    - [x] 15.4.7.5 Fix file pattern consistency across all agents (INCORRECT IMPLEMENTATION)
      - [x] 15.4.7.5.1 Update peer-planner.md to use ./tmp/peer-planner/plan_output_cycle_[CYCLE_NUMBER].json
      - [x] 15.4.7.5.2 Update peer-executor.md to use ./tmp/peer-executor/execution_output_cycle_[CYCLE_NUMBER].json
      - [x] 15.4.7.5.3 Update peer-review.md to use cycle numbers in both output files
      - [x] 15.4.7.5.4 Ensure all agents use relative ./tmp/ paths (not absolute /tmp/)
      - [x] 15.4.7.5.5 Verify CYCLE_NUMBER is available in all agent contexts
      - [x] 15.4.7.5.6 Update cleanup commands to reference cycle-specific files
      - [ ] 15.4.7.5.7 Test concurrent cycles don't have file conflicts
    - [ ] 15.4.7.6 Test all agents handle complex JSON without escaping
      - [ ] 15.4.7.6.1 Test peer-planner with complex planning output
      - [ ] 15.4.7.6.2 Test peer-review with complex review scores and insights
      - [ ] 15.4.7.6.3 Test peer-executor with complex execution results
      - [ ] 15.4.7.6.4 Verify no direct NATS commands or --argjson used
    - [x] 15.4.7.7 Correct CYCLE_NUMBER usage to match peer-express.md pattern
      - [x] 15.4.7.7.1 Remove explicit CYCLE_NUMBER extraction from peer-planner.md Step 6
      - [x] 15.4.7.7.2 Remove explicit CYCLE_NUMBER extraction from peer-executor.md Steps 7 and 8
      - [x] 15.4.7.7.3 Remove explicit CYCLE_NUMBER extraction from peer-review.md Steps 8 and 9
      - [x] 15.4.7.7.4 Use [CYCLE_NUMBER] as placeholder in WRITE_TOOL commands
      - [x] 15.4.7.7.5 Use ${CYCLE_NUMBER} or [CYCLE_NUMBER] in bash file path variables
      - [x] 15.4.7.7.6 Verify CYCLE_NUMBER is provided by peer.md context
      - [ ] 15.4.7.7.7 Test that placeholders are properly substituted at runtime
  - [ ] 15.5 Test refine-spec integration
    - [ ] 15.5.1 Test refine-spec with previous review recommendations
    - [ ] 15.5.2 Test refine-spec without previous recommendations
    - [ ] 15.5.3 Verify task status preservation works correctly
    - [ ] 15.5.4 Validate output formatting is appropriate
    - [ ] 15.5.5 Confirm review quality assessment functions properly
  - [ ] 15.6 Document integration completion
    - [ ] 15.6.1 Update implementation notes with refine-spec integration
    - [ ] 15.6.2 Add to progress-summary.md
    - [ ] 15.6.3 Verify all peer agents handle refine-spec consistently
    - [ ] 15.6.4 Document any edge cases discovered during testing
    - [ ] 15.6.5 Create example PEER cycle with refine-spec usage

## Phase 16: Architectural Corrections (No Backwards Compatibility Concerns)

- [x] 16. Fix Express Phase Ownership Violation
  - [x] 16.1 Remove root-level result field from peer-express.md
    - [x] 16.1.1 Remove `.result = $cycle_result[0]` from Step 8 JQ_FILTER (line 439)
    - [x] 16.1.2 Verify all cycle result data remains in `phases.express.output`
    - [ ] 16.1.3 Test Express phase only modifies `phases.express.*`
  - [x] 16.2 Update unified_state_schema.md to remove result field
    - [x] 16.2.1 Remove result field definition from schema
    - [x] 16.2.2 Add cycle_summary field owned by Review phase
    - [x] 16.2.3 Document cycle_summary structure (success, instruction, summary, highlights, completion, next_action)
    - [x] 16.2.4 Update schema version to 1.1
  - [x] 16.3 Add cycle_summary creation to peer-review.md
    - [x] 16.3.1 Create cycle_summary from all phase outputs in Step 8
    - [x] 16.3.2 Include success status, instruction name, and summary
    - [x] 16.3.3 Extract highlights from execution and express phases
    - [x] 16.3.4 Calculate completion percentage
    - [x] 16.3.5 Determine next_action based on review assessment
  - [x] 16.4 Update peer.md to display cycle_summary
    - [x] 16.4.1 Modify Step 11 to read cycle_summary from state
    - [x] 16.4.2 Display cycle_summary in final summary output
    - [x] 16.4.3 Remove any references to root.result field

## Phase 17: Fix Hidden Insights Problem

- [x] 17. Fix Hidden Insights Problem
  - [x] 17.1 Update peer.md Step 12 to display insights
    - [x] 17.1.1 Extract insights field from unified state
    - [x] 17.1.2 Add "Questions Requiring Your Input" section with HIGH VISIBILITY
    - [x] 17.1.3 Display questions_for_user prominently
    - [x] 17.1.4 Add "Recommendations & Insights" section
    - [x] 17.1.5 Format process, technical, and efficiency recommendations
    - [x] 17.1.6 Display learnings and patterns identified
  - [x] 17.2 Enhance insights structure in peer-review.md
    - [x] 17.2.1 Ensure questions_for_user are clear and actionable
    - [x] 17.2.2 Include alternative solution approaches when applicable
    - [x] 17.2.3 Add rationale for recommended approaches
    - [x] 17.2.4 Format insights for maximum user value

## Phase 18: Validate Architectural Corrections

- [ ] 18. Validate Architectural Corrections
  - [ ] 18.1 Test complete PEER cycle with corrections
    - [ ] 18.1.1 Verify Express phase respects ownership boundaries
    - [ ] 18.1.2 Confirm cycle_summary properly created by Review
    - [ ] 18.1.3 Validate insights displayed to user
    - [ ] 18.1.4 Check questions_for_user are prominently shown
  - [ ] 18.2 Update documentation
    - [ ] 18.2.1 Document phase ownership rules clearly
    - [ ] 18.2.2 Update examples to show correct patterns
    - [ ] 18.2.3 Add notes about displaying alternative solutions
