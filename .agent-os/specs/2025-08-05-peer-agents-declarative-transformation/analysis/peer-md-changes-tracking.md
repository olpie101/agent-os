# peer.md Changes Tracking Document

> Purpose: Track necessary changes to peer.md instruction file for PEER agents declarative transformation
> Created: 2025-08-05
> Principle: Minimize changes to peer.md while ensuring compatibility

## Current State of peer.md

The peer.md instruction file (version 2.0) has already been transformed to be process-based and declarative. It successfully:
- Uses `<process_flow>` with numbered steps
- Delegates to subagents via `subagent=""` attributes
- Has no external script dependencies
- Uses NATS KV for state management

## Required Changes for Unified State Schema

### 1. State Storage Pattern Changes

**Current** (Lines ~187-189):
```xml
<cycle_state_examples>
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:current" "[CYCLE_NUMBER]"
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:metadata" "{json_metadata}"
</cycle_state_examples>
```

**Proposed Change**:
```xml
<cycle_state_examples>
  # Single unified state object per cycle
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]" "{unified_cycle_state}"
  # Structure includes all phase data, history, and sequence number for locking
</cycle_state_examples>
```

**Impact**: Low - Example only, doesn't affect logic

### 2. Subagent Communication Context

**Current** (Lines ~252-280 for peer-planner):
```xml
REQUEST: "Create execution plan for instruction: [INSTRUCTION_NAME]
          ...
          3. Structure the plan as JSON and store in NATS KV at:
             [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
          
          4. Also store a planning summary at:
             [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan_summary"
```

**Proposed Change**:
```xml
REQUEST: "Create execution plan for instruction: [INSTRUCTION_NAME]
          ...
          State Management:
          - Read cycle state from: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]
          - Use sequence number for optimistic locking
          - Update plan phase in unified state object
          - No temp files - all context from NATS KV"
```

**Impact**: Medium - Changes subagent interface expectations

### 3. Phase Validation Logic

**Current** (Lines ~290-296):
```xml
<phase_validation>
  CHECK: Planning phase completed
  IF plan not available in NATS KV:
    ERROR: "Cannot execute without completed planning phase"
    PROVIDE: "Ensure planning phase completed successfully"
    STOP execution
</phase_validation>
```

**Proposed Change**:
```xml
<phase_validation>
  CHECK: Unified state at [KEY_PREFIX]:cycle:[CYCLE_NUMBER]
  IF state.phases.plan.status != "completed":
    ERROR: "Cannot execute without completed planning phase"
    PROVIDE: "Ensure planning phase completed successfully"
    STOP execution
  EXTRACT: state.sequence for optimistic locking
</phase_validation>
```

**Impact**: Low - Validation logic remains similar

### 4. Context Variable Initialization

**Current** (Lines ~104-108):
```xml
<context_variables>
  - PEER_MODE: "new" or "continue"
  - INSTRUCTION_NAME: from --instruction flag
  - SPEC_NAME: from --spec flag (optional)
</context_variables>
```

**Proposed Addition**:
```xml
<context_variables>
  - PEER_MODE: "new" or "continue"
  - INSTRUCTION_NAME: from --instruction flag
  - SPEC_NAME: from --spec flag (optional)
  - STATE_KEY: "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]"  # Unified state location
  - SCHEMA_VERSION: 2  # For migration support
</context_variables>
```

**Impact**: Low - Additional context for subagents

## Changes NOT Required

These aspects of peer.md can remain unchanged:

1. **Overall process flow structure** - The 11 steps remain the same
2. **NATS availability checks** (Steps 1-2) - Still needed
3. **Argument parsing** (Step 3) - Works as-is
4. **Execution context determination** (Step 4) - No changes
5. **Spec name determination** (Step 6) - Logic unchanged
6. **Cycle completion** (Step 11) - Summary formatting unchanged

## Migration Strategy

### Phase 1: Subagent Updates (No peer.md changes)
- Transform all four PEER subagents to declarative patterns
- Subagents handle both old and new state formats
- Automatic migration on first update

### Phase 2: Soft Transition (Minimal peer.md changes)
- Update state examples to show unified format
- Add STATE_KEY to context variables
- Subagents use unified state exclusively

### Phase 3: Full Integration (Final peer.md updates)
- Update validation logic to check unified state
- Remove references to fragmented keys
- Update documentation examples

## Risk Assessment

| Change | Risk Level | Mitigation |
|--------|------------|------------|
| Unified state key | Low | Backward compatible read |
| Subagent interface | Medium | Support both formats initially |
| Validation logic | Low | Graceful fallback |
| Context passing | Low | Additional variables only |

## Testing Requirements

Before implementing peer.md changes:

1. **All subagents must be transformed** - Complete Tasks 2-5
2. **State migration tested** - Old format → New format
3. **Concurrent access tested** - Optimistic locking works
4. **Full cycle tested** - All phases complete successfully
5. **Backward compatibility verified** - Can resume old cycles

## Recommendation

**Approach**: Implement subagent transformations first (Tasks 2-5) with backward compatibility, then update peer.md minimally in Task 6.
USER UPDATE: Backwards compatibility is not neccessary.
# TODO: Update this file and others to not worry about backwards compatibility

**Rationale**: 
- Subagents can be updated independently
- Backward compatibility maintains stability
- Gradual migration reduces risk
- peer.md changes are minimal and low-impact

## Updates from Task 3: peer-executor Transformation

### Changes Identified from Executor Transformation

1. **Subagent Communication Update (Lines ~306-326)**
   - Current: Passes plan location as separate key
   - Needed: Pass STATE_KEY for unified state access
   - Impact: Low - Parameter adjustment only

2. **MCP Validation Integration**
   - Current: Not mentioned in peer.md
   - Needed: Document git-commit special handling
   - Impact: None - Handled internally by executor

3. **State Transition Clarity**
   - Current: Status transitions implicit
   - Needed: Explicit status flow (EXECUTING → EXPRESSING)
   - Impact: Documentation only

### No Changes Required For

- Execution phase validation logic - Works with unified state
- Error handling delegation - Executor handles internally
- Continuation support - Already compatible

## Updates from Task 4: peer-express Transformation

### Changes Identified from Express Transformation

1. **Express Phase Communication (Step 9)**
   - Current: Passes separate plan/execution locations
   - Needed: Pass STATE_KEY for unified state
   - Impact: Low - parameter adjustment

2. **Result Storage Pattern**
   - Current: Result stored separately
   - Needed: Include in unified state object
   - Impact: Low - structural adjustment

## Updates from Task 5: peer-review Transformation

### Changes Identified from Review Transformation

1. **Review Phase Communication (Step 10)**
   - Current: Passes multiple phase locations
   - Needed: Pass STATE_KEY for all phase data
   - Impact: Low - parameter adjustment

2. **Cycle Completion Status**
   - Current: Status transitions not explicit
   - Needed: Final status = "COMPLETE"
   - Impact: Documentation clarity

3. **Insights Storage**
   - Current: Not mentioned
   - Needed: Store insights in unified state
   - Impact: Low - additional field

## Comprehensive Summary of Required Changes

### Critical Changes (Must Have)

1. **Add STATE_KEY to context variables (Step 4)**
   ```xml
   <context_variables>
     - STATE_KEY: "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]"  # Unified state location
   </context_variables>
   ```

2. **Update all subagent invocations (Steps 7-10)**
   - Pass STATE_KEY instead of individual phase locations
   - Example for Step 8 (executor):
   ```xml
   REQUEST: "Execute instruction with state at: ${STATE_KEY}"
   ```

3. **Update state examples (Step 5)**
   - Show unified state structure instead of fragmented keys
   - Single state object per cycle

### Nice to Have (Documentation)

1. **Status progression clarity**
   - Document: INITIALIZED → PLANNING → EXECUTING → EXPRESSING → REVIEWING → COMPLETE

2. **Remove backward compatibility notes**
   - As per user update, no backward compatibility needed
   - Simplifies implementation

### No Changes Required

- Overall process flow structure (11 steps remain)
- NATS availability checks (Steps 1-2)
- Argument parsing (Step 3)
- Error handling patterns
- Completion notification

## Final Summary

The peer.md instruction file requires minimal but important adjustments:

**Essential Changes:**
1. Add STATE_KEY to context variables
2. Pass STATE_KEY to all subagents (not separate locations)
3. Update state storage examples to show unified structure

**Documentation Updates:**
4. Clarify status progression flow
5. Remove backward compatibility requirements

These changes maintain the declarative, process-based nature of peer.md while enabling the unified state schema with improved atomicity and reliability. The transformation successfully eliminates all bash script dependencies across all four PEER subagents.
