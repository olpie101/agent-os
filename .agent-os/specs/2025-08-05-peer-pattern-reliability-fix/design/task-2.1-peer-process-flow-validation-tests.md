# Task 2.1: PEER Process Flow Validation Tests

## Overview

This document defines validation tests for the redesigned PEER process flow, ensuring it follows Agent OS patterns and addresses all reliability issues identified in the spec.

## Test Categories

### 1. Process Structure Tests

#### Test: Valid Process Flow Structure
- **Validates**: peer.md has proper `<process_flow>` container
- **Expected**:
  - Contains `<process_flow>` tags
  - All steps are numbered sequentially
  - Each step has `number`, `name` attributes
  - Subagent steps have `subagent` attribute

#### Test: Required Steps Present
- **Validates**: All PEER phases have corresponding steps
- **Expected Steps**:
  - Pre-flight checks (NATS availability, bucket setup)
  - Argument parsing and validation
  - Context determination
  - Cycle initialization
  - Planning phase (peer-planner)
  - Execution phase (peer-executor)
  - Express phase (peer-express)
  - Review phase (peer-review)
  - Cycle completion

### 2. Script Dependency Tests

#### Test: No Script References
- **Validates**: No calls to `~/.agent-os/scripts/peer/*.sh`
- **Expected**:
  - No Bash tool calls to script files
  - No SCRIPT: directives pointing to .sh files
  - All logic expressed in process flow

#### Test: Reference Commands Only
- **Validates**: NATS commands follow notification pattern
- **Expected**:
  - Commands in semantic XML tags (e.g., `<nats_health_check>`)
  - No executable Bash blocks
  - Clear indication they are reference examples

### 3. Subagent Delegation Tests

#### Test: Proper Subagent Instructions
- **Validates**: Each subagent step has correct instruction format
- **Expected Pattern**:
  ```xml
  <instructions>
    ACTION: Use [subagent] subagent
    REQUEST: "[Detailed request]"
    WAIT: For [expected outcome]
    PROCESS: [Response handling]
  </instructions>
  ```

#### Test: Context Passing
- **Validates**: State flows correctly between phases
- **Expected**:
  - Planning output available to executor
  - Execution output available to express
  - All outputs available to review
  - Clear data flow documentation

### 4. Conditional Logic Tests

#### Test: Argument Validation Logic
- **Validates**: Proper handling of --instruction, --continue, --spec
- **Expected**:
  - Mutually exclusive validation for --instruction/--continue
  - Clear error messages
  - Proper flow based on arguments

#### Test: Phase Validation Logic
- **Validates**: Execute phase must complete before Express
- **Expected**:
  - Conditional check before Express phase
  - Error if execution incomplete
  - Clear validation checkpoints

#### Test: Error Recovery Paths
- **Validates**: All error conditions have recovery paths
- **Expected**:
  - NATS unavailable → clear instructions
  - Bucket creation failure → recovery steps
  - Phase failures → appropriate handling

### 5. State Management Tests

#### Test: Explicit State Handling
- **Validates**: No implicit state dependencies
- **Expected**:
  - Context passed through defined channels
  - No hardcoded temp file paths in logic
  - State visibility in process flow

#### Test: NATS KV Integration
- **Validates**: Proper NATS KV usage patterns
- **Expected**:
  - Reference commands for KV operations
  - Clear key naming conventions
  - Bucket configuration in process

### 6. Process Coordination Tests

#### Test: Sequential Flow Control
- **Validates**: Steps execute in proper order
- **Expected**:
  - Pre-flight before main flow
  - Initialization before phases
  - Phases in PEER order
  - Completion after all phases

#### Test: Conditional Execution
- **Validates**: Steps can be skipped based on conditions
- **Expected**:
  - Spec name determination only for create-spec
  - Continuation logic for --continue flag
  - Appropriate phase selection

### 7. User Interaction Tests

#### Test: Clear User Communication
- **Validates**: User prompts and messages are clear
- **Expected**:
  - Error messages explain problems
  - Recovery instructions are actionable
  - Status updates at key points

#### Test: User Decision Points
- **Validates**: User has control at appropriate points
- **Expected**:
  - Can abort on errors
  - Can continue from failures
  - Clear prompts for decisions

### 8. Backward Compatibility Tests

#### Test: Existing Subagent Compatibility
- **Validates**: Works with current peer-* subagents
- **Expected**:
  - Same REQUEST format accepted
  - Same output handling
  - No breaking changes

#### Test: NATS KV Schema Compatibility
- **Validates**: Uses same KV structure
- **Expected**:
  - Same key patterns
  - Same data formats
  - Existing cycles can be continued

## Test Execution Plan

### Phase 1: Structure Validation
1. Verify XML structure matches patterns
2. Check all required steps present
3. Validate step attributes

### Phase 2: Logic Validation
1. Trace all conditional paths
2. Verify error handling coverage
3. Check state flow consistency

### Phase 3: Integration Validation
1. Verify subagent communication patterns
2. Check NATS integration approach
3. Validate user interaction points

### Phase 4: Regression Prevention
1. Ensure script dependencies eliminated
2. Verify phase validation implemented
3. Check false success prevention

## Success Criteria

The redesigned peer.md passes all tests when:
1. No script dependencies exist
2. All logic is in process flow
3. Phase validation prevents skipping
4. Error handling is comprehensive
5. State management is explicit
6. Follows all Agent OS patterns
7. Maintains backward compatibility

## Summary

These validation tests ensure the redesigned PEER process flow:
- Eliminates script orchestration failures
- Implements proper phase validation
- Follows Agent OS patterns consistently
- Provides reliable process coordination
- Maintains compatibility with existing components

The tests focus on validating the process structure, logic flow, and integration points rather than executable code, matching the declarative nature of Agent OS instructions.