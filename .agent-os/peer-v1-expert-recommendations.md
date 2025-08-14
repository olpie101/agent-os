# PEER Pattern v1 Implementation - Expert Recommendations

> Created: 2025-08-06
> Purpose: Capture expert feedback for future refinement
> Source: Gemini and Grok review of simplified v1 task list

## Context

These recommendations were provided during expert review of the PEER agents declarative transformation v1 implementation. They are saved here for future consideration but are NOT required for the initial v1 proof-of-concept.

## Gemini's Architectural Recommendations

### Centralize State Machine Logic in peer.md

**Core Principle:** The orchestrator (peer.md) should be the sole manager of global cycle state (`metadata.status` and `metadata.current_phase`). Individual agents should only update their own phase section.

**Benefits:**
- Eliminates inconsistency risks
- Reduces coupling between agents
- Simplifies error recovery
- Makes agents more modular

**Implementation Approach:**
1. **Agent's Responsibility:** 
   - Read unified state
   - Perform its task
   - Update only `phases.<name>.status` and `phases.<name>.output`
   - Write state back

2. **peer.md's Responsibility:**
   - Call each agent
   - Wait for completion
   - Verify `phases.<name>.status == "completed"`
   - Update `metadata.status` and `metadata.current_phase`
   - Proceed to next phase

**Specific Changes Required:**
- Remove metadata update tasks from peer-executor (5.11, 5.12)
- Remove metadata update tasks from peer-express (6.11, 6.12)  
- Remove metadata update tasks from peer-review (7.10, 7.11, 7.13)
- Add explicit state transition logic to peer.md after each phase

## Grok's Robustness Recommendations

### 1. Edge Case Handling

**Phase Failure Scenarios:**
- Add task 8.16: Test phase failure handling (simulate executor failure, verify peer.md detection/abort)
- Add task 8.17: Test invalid state reads (missing key, malformed JSON)

**State Size Considerations:**
- Research NATS KV entry size limits (typically ~1MB)
- Consider artifact pointers for large outputs
- Add validation for state size before writes

**Timestamp Standardization:**
- Enforce ISO 8601 format with timezone
- Use consistent timestamp generation method
- Add validation for timestamp fields

### 2. Implementation Safeguards

**JQ Error Handling:**
- Add error checking after JQ transformations
- Validate JSON output before NATS writes
- Example: `if ! echo "$UPDATED_STATE" | jq empty 2>/dev/null; then error; fi`

**Key Prefix Consistency:**
- Add task 1.10: Validate key prefix consistency across spec/global modes
- Ensure delimiter change doesn't break prefix logic
- Add tests for both modes

**Schema Version Enforcement:**
- Add version check in each agent
- Fail fast if schema version mismatch
- Log version for debugging

### 3. Error Handling Tasks

**NATS Operation Failures:**
- Add task 8.18: Implement NATS command error trapping
- Check exit codes after each NATS operation
- Set phase status to "failed" with error message

**Schema Validation:**
- Add task 8.19: Basic schema validation before updates
- Check required fields exist
- Validate field types match schema

**Phase Ownership Enforcement:**
- Add validation that agents only modify their phase
- Compare before/after state to detect violations
- Log any unexpected changes

### 4. Dependency Management

**Explicit Dependency Checks:**
- Add task 3.14: Add dependency validation in peer.md
- Check prior phase status before invocation
- Abort if dependencies not met

**Failure Propagation:**
- Add task 7.16: Review should detect prior failures
- Skip insights if any phase failed
- Mark review as failed if dependencies failed

### 5. NATS-Specific Considerations

**Bucket Configuration:**
- Add task 1.11: Verify NATS bucket exists and configured correctly
- Check replicas, history settings
- Create setup script if needed

**Key Validity:**
- Validate no invalid characters after delimiter change
- Test with various key patterns
- Document any restrictions

**Revision Tracking:**
- Add task 9.16: Log NATS revision numbers for debugging
- Track revision on each put operation
- Useful for debugging even without optimistic locking

## Testing Enhancements

**Additional Test Scenarios:**
- Task 8.20: Test NATS-specific errors (key not found, invalid format)
- Simulate network failures
- Test with concurrent manual NATS commands
- Verify state recovery after failures

**Polling/Wait Logic:**
- Add task 3.13: Implement polling in peer.md
- Wait for phase completion with timeout
- Add exponential backoff for retries
- Log wait times for performance analysis

## Summary

These recommendations would transform the v1 implementation from a proof-of-concept to a production-ready system. However, they are NOT required for initial v1 success. The simplified approach without these enhancements is sufficient to prove the unified state concept works.

**Priority for v2:**
1. Centralized state management (Gemini)
2. Comprehensive error handling (Grok)
3. Optimistic locking (original design)
4. Performance optimizations

## Decision

For v1: Focus on proving the core concept works with simple read-modify-write patterns.
For v2: Incorporate these recommendations for production readiness.