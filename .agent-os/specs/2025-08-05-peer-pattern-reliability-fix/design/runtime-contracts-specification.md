# Runtime Contracts Specification for PEER Process Flow

## Overview

This document specifies the runtime contracts and implementation refinements recommended by expert analysis for the PEER v2.0 process flow, ensuring maximum robustness and operational excellence.

## Runtime Environment Contracts

### 1. Failure Context Variable Injection

**Requirement**: The Agent OS runtime must provide automatic context variables when failures occur.

**Context Variables Required**:
```xml
[FAILURE_PHASE]   - The phase where failure occurred (planning, execution, express, review)
[FAILURE_STEP]    - The specific step number that failed (e.g., "7", "8")
[ERROR_MESSAGE]   - The error message from the failed operation
```

**Implementation Contract**:
- When any `DELEGATE` instruction fails, the runtime captures:
  - The current phase name from process context
  - The step number from the executing step
  - The error output from the failed subagent
- These variables are automatically available in the `failure_handler` blocks

**Fallback Pattern** (if runtime doesn't provide):
```xml
<subagent_error_contract>
  Failing subagents MUST output JSON to stderr:
  {
    "error": "Brief error description",
    "details": "Detailed error information",
    "phase": "current_phase_name",
    "step": "current_step_number"
  }
</subagent_error_contract>
```

### 2. Subagent Error Reporting

**Standard Contract**: All subagents must follow a consistent error reporting pattern.

**Error Output Format**:
```json
{
  "status": "failed",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "phase": "planning|execution|express|review",
      "step": "step_number",
      "context": "Additional context information"
    }
  }
}
```

**Exit Codes**:
- 0: Success
- 1: General failure
- 2: Invalid arguments
- 3: State conflict (e.g., initialization race condition)
- 4: External dependency failure (e.g., NATS unavailable)

## Atomicity Contracts

### 1. State Manager Initialize Operation

**Contract**: The `peer-state-manager` subagent's `initialize` action MUST be atomic.

**Implementation Requirements**:
```yaml
action: initialize
behavior: create-if-not-exists
atomicity: true
idempotency: false (fails if exists)
```

**Detailed Behavior**:
1. Check if key `[KEY_PREFIX].cycle.[CYCLE_NUMBER].state` exists
2. If exists:
   - Return error with exit code 3 (state conflict)
   - Include existing cycle metadata in error details
3. If not exists:
   - Create key atomically using NATS KV create operation
   - Ensure no other process can create between check and create
   - Return success with created cycle metadata

**NATS KV Implementation**:
```bash
# Atomic create (fails if exists)
nats kv create agent-os-peer-state "peer.spec.user-auth.cycle.42.state" "INITIALIZING"

# Returns error if key already exists
# Exit code: 1
# Error: nats: key exists
```

### 2. Subagent Result Persistence

**Contract**: Subagents are responsible for persisting their own results.

**Implementation Pattern**:
```xml
<subagent_invocation>
  REQUEST: "Execute task with parameters...
            
            Output Key: [OUTPUT_KEY]
            
            You MUST persist your results directly to NATS KV at: [OUTPUT_KEY]
            Your final action MUST be to store 'completed' at: [COMPLETION_KEY]"
            
  WAIT: For key [COMPLETION_KEY] to exist with value 'completed'
  TIMEOUT: 300 seconds (configurable per phase)
  ON_TIMEOUT: Mark phase as failed
</subagent_invocation>
```

**Subagent Responsibilities**:
1. Perform the requested work
2. Persist results to the specified output key
3. Set completion marker as final action
4. Handle partial results on failure

## Cleanup Contracts

### 1. Failure Cleanup Handler

**Requirement**: Add cleanup operations to all failure handlers.

**Implementation**:
```xml
<failure_handler name="phase_failed">
  <actions>
    - step_id: F.1
      name: "Update Failure State"
      instruction: |
        UPDATE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].status = "[PHASE]_FAILED"
        UPDATE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].failed_at = "[TIMESTAMP]"
        UPDATE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].error = "[ERROR_MESSAGE]"
    
    - step_id: F.2
      name: "Perform Cleanup"
      instruction: |
        DELEGATE to="peer-cleanup" with_payload='{
          "task_id": "[CYCLE_NUMBER]",
          "cleanup_type": "failure",
          "phase": "[FAILURE_PHASE]"
        }'
      on_fail: "continue"  # Best-effort cleanup
    
    - step_id: F.3
      name: "Notify and Exit"
      instruction: |
        DISPLAY: "❌ [PHASE] phase failed: [ERROR_MESSAGE]"
        STOP: Execution with failure status
  </actions>
</failure_handler>
```

### 2. Cleanup Subagent Contract

**Service**: `peer-cleanup`

**Actions Supported**:
```yaml
cleanup_type: failure
  - Remove temporary files in /tmp/peer_*
  - Clean partial outputs from failed phase
  - Log cleanup actions to audit trail
  
cleanup_type: success
  - Archive intermediate artifacts
  - Compress large outputs
  - Remove working directories
  - Update cleanup timestamp
```

**Cleanup Scope by Phase**:
- **Planning**: Remove draft plans, temporary analysis files
- **Execution**: Clean build artifacts, temporary repos, generated files
- **Express**: Remove formatting drafts, temporary renders
- **Review**: Clean analysis artifacts, comparison files

## Concurrency Contracts

### 1. Distributed Lock Pattern

**Implementation**: Use NATS KV create operation as distributed lock.

```bash
# Acquire lock (atomic)
nats kv create agent-os-peer-state "peer.locks.[INSTRUCTION].[SPEC]" "{\"owner\":\"[PROCESS_ID]\",\"acquired\":\"[TIMESTAMP]\"}"

# Release lock
nats kv delete agent-os-peer-state "peer.locks.[INSTRUCTION].[SPEC]"
```

### 2. Cycle Number Generation

**Contract**: Cycle numbers must be globally unique and sequential.

**Implementation**:
```bash
# Atomic increment
NEXT_CYCLE=$(nats kv update agent-os-peer-state "peer.global.next_cycle" "$((CURRENT+1))")
```

## State Model Extension (Future)

### Retry-Capable State Model

For future v2.1 implementation supporting retries:

**Extended States**:
```yaml
states:
  - INITIALIZED
  - PLANNING
  - PLANNING_COMPLETE
  - PLANNING_FAILED
  - PLANNING_RETRY_PENDING
  - EXECUTION
  - EXECUTION_COMPLETE
  - EXECUTION_FAILED
  - EXECUTION_RETRY_PENDING
  - EXPRESS
  - EXPRESS_COMPLETE
  - EXPRESS_FAILED
  - REVIEW
  - REVIEW_COMPLETE
  - REVIEW_FAILED
  - COMPLETED
  - FAILED
  - ABANDONED
```

**Retry Metadata**:
```yaml
retry_context:
  attempt_count: 1-3
  last_error: "error details"
  retry_after: "timestamp"
  backoff_seconds: 30|60|120
```

## Implementation Checklist

### Immediate Actions Required

- [ ] Verify Agent OS runtime provides failure context variables
- [ ] Implement atomic initialize in peer-state-manager
- [ ] Add cleanup step to all failure handlers
- [ ] Update subagent contracts for error reporting
- [ ] Document timeout values for each phase
- [ ] Test concurrent initialization handling

### Testing Requirements

1. **Concurrency Test**: Launch multiple PEER processes for same task
2. **Failure Injection**: Test each phase failure with cleanup verification
3. **Atomicity Test**: Verify no partial states on crash
4. **Cleanup Test**: Ensure all artifacts removed on failure
5. **Timeout Test**: Verify timeout handling for each phase

## Summary

These contracts ensure the PEER v2.0 implementation achieves production-grade reliability through:
- Atomic state initialization preventing race conditions
- Consistent error reporting enabling debugging
- Comprehensive cleanup preventing resource leaks
- Clear subagent responsibilities ensuring atomicity
- Future-ready state model supporting retries

Implementation of these contracts transforms PEER from "working" to "production-ready" as identified by expert analysis.