# PEER.MD Alignment Requirements for Declarative Transformation (Simplified v1)

> Created: 2025-08-06  
> Updated: 2025-08-06
> Status: Simplified First Iteration
> Purpose: Document minimal required changes to test unified state approach

## Executive Summary

This document outlines the **simplified first iteration** of aligning `instructions/core/peer.md` with declarative peer agents. We focus on proving the core concept: transitioning from fragmented state to unified state objects, without the complexity of optimistic locking or backward compatibility.

## Core Alignment Goal

Test whether the unified state model works by implementing the simplest possible version first.

## Central Schema Definition Requirement

### Location and Purpose

A central schema definition file should be created at:
```
instructions/meta/unified_state_schema.md
```

This file will:
1. Serve as the single source of truth for the unified state structure
2. Be referenced by both peer.md and all peer agent files
3. Eliminate duplication and ensure consistency
4. Make schema updates easier to manage

### Schema Requirements for v1

The central schema file must define a simplified schema that:
- **EXCLUDES** sequence numbers (no optimistic locking in v1)
- **EXCLUDES** history arrays (can add in v2 if needed)
- **EXCLUDES** sequence_at_start and sequence_at_complete fields
- **INCLUDES** basic metadata fields (instruction, status, phase)
- **INCLUDES** context fields (peer_mode, user_requirements)
- **INCLUDES** phase structure with status and output
- **INCLUDES** clear field descriptions and constraints

### Content Structure for unified_state_schema.md

The central schema file should contain:

1. **Schema Version Information**
   - Version: 1 (simplified, no locking)
   - Purpose: Define unified state structure for PEER cycles

2. **Field Definitions**
   ```
   - version: Schema version (integer)
   - cycle_id: Unique identifier matching KV key
   - metadata: Core cycle information
     - instruction_name: Name of instruction being executed
     - spec_name: Spec name if applicable
     - key_prefix: NATS KV key prefix
     - cycle_number: Sequential cycle number
     - created_at: ISO timestamp
     - updated_at: ISO timestamp  
     - status: INITIALIZED|PLANNING|EXECUTING|EXPRESSING|REVIEWING|COMPLETED|FAILED
     - current_phase: plan|execute|express|review
   - context: Execution context
     - peer_mode: new|continue
     - spec_aware: boolean
     - user_requirements: Original user input
   - phases: Phase-specific data
     - plan/execute/express/review:
       - status: pending|in_progress|completed|failed
       - started_at: ISO timestamp (optional)
       - completed_at: ISO timestamp (optional)
       - output: Phase-specific output object
       - error: Error message if failed (optional)
   ```

3. **Usage Examples**
   - How to read the schema from peer.md
   - How agents should update their phase
   - Strict ownership rules (each agent updates only its phase)

### References in Other Files

All files should reference the central schema:
- peer.md: `@instructions/meta/unified_state_schema.md`
- peer-planner.md: Reference schema for state structure
- peer-executor.md: Reference schema for state structure
- peer-express.md: Reference schema for state structure
- peer-review.md: Reference schema for state structure

## Simplified Unified State Schema (v1)

```json
{
  "version": 1,
  "cycle_id": "peer.spec.my-feature.cycle.1",
  "metadata": {
    "instruction_name": "create-spec",
    "spec_name": "my-feature",
    "key_prefix": "peer.spec.my-feature",
    "cycle_number": 1,
    "created_at": "2025-08-06T10:00:00Z",
    "updated_at": "2025-08-06T10:15:00Z",
    "status": "EXECUTING",
    "current_phase": "execute"
  },
  "context": {
    "peer_mode": "new",
    "spec_aware": true,
    "user_requirements": "Original user input for the instruction"
  },
  "phases": {
    "plan": {
      "status": "completed",
      "started_at": "2025-08-06T10:00:00Z",
      "completed_at": "2025-08-06T10:05:00Z",
      "output": {
        "instruction_type": "spec-aware",
        "phases": ["preparation", "execution", "finalization"],
        "success_criteria": "Spec documentation created and validated"
      }
    },
    "execute": {
      "status": "in_progress",
      "started_at": "2025-08-06T10:05:00Z",
      "output": {
        "progress": "Creating spec files",
        "files_created": [".agent-os/specs/2025-08-06-my-feature/spec.md"]
      }
    },
    "express": {
      "status": "pending"
    },
    "review": {
      "status": "pending"
    }
  }
}
```

### Key Simplifications from Original Design

1. **No sequence numbers** - Simple read/write operations
2. **No history array** - Can add later if needed for debugging
3. **Minimal metadata** - Just what's needed for basic operation
4. **Simple phase structure** - Status, timestamps, and output only
5. **No error arrays** - Handle errors through status and output fields

### Important: Peer Agent Requirements for v1

The declarative peer agent files (peer-planner, peer-executor, peer-express, peer-review) must be updated to:

1. **Remove all sequence field references** - No reading, writing, or checking sequence numbers
2. **Use simple read/write operations** - Direct `nats kv get` and `nats kv put` without conditions
3. **Remove optimistic locking logic** - No retry loops or sequence validation
4. **Follow strict ownership** - Each agent only modifies its own phase section:
   - peer-planner: Only updates `phases.plan`
   - peer-executor: Only updates `phases.execute`
   - peer-express: Only updates `phases.express`
   - peer-review: Only updates `phases.review`
5. **Read full state, write full state** - No partial updates in v1

## Critical Alignment Gaps

### 1. Key Delimiter Change Requirement

**Critical Issue:**
- Current files use `:` as delimiter (e.g., `peer:spec:feature:cycle:1`)
- NATS KV requires `.` as delimiter for valid keys
- ALL key patterns must be updated to use `.` instead of `:`

**Required Changes:**
```
# OLD (invalid for NATS KV updates)
peer:spec:feature-name:cycle:1
peer:global:cycle:2

# NEW (valid for NATS KV)
peer.spec.feature-name.cycle.1
peer.global.cycle.2
```

### 2. State Management Paradigm Shift

**Current peer.md approach:**
- Multiple separate NATS KV entries per cycle (metadata, plan, execution, express, review)
- Direct `nats kv put` commands for each piece of state
- Subagents expect temporary files for context

**Simplified declarative approach (v1):**
- Single unified state object per cycle
- Simple read/write operations (no locking for now)
- All state in NATS KV (no temp files)

### 2. Subagent Invocation Context

**Current peer.md passes:**
```
REQUEST: "Create execution plan for instruction: [INSTRUCTION_NAME]
          Cycle: [CYCLE_NUMBER]
          Spec: [SPEC_NAME] (if applicable)
          Context:
          - NATS KV Bucket: agent-os-peer-state
          - Key Prefix: [KEY_PREFIX]
          - Execution Mode: [PEER_MODE]"
```

**Simplified declarative agents expect:**
```
REQUEST: "Execute planning phase
          STATE_KEY: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]
          
          The unified state object at STATE_KEY contains all context including:
          - instruction_name
          - spec_name
          - cycle_number
          - current phase status"
```

### Example: Peer Agent State Update Pattern (v1)

Instead of the complex optimistic locking pattern, peer agents should use this simple pattern:

```bash
# 1. Read current state
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw)

# 2. Parse and modify only your phase
UPDATED_STATE=$(echo "$STATE" | jq '
  .phases.plan.status = "completed" |
  .phases.plan.output = {
    "instruction_type": "spec-aware",
    "success_criteria": "Spec created"
  } |
  .metadata.updated_at = now | todate
')

# 3. Write back full state (no sequence check)
echo "$UPDATED_STATE" | nats kv put agent-os-peer-state "$STATE_KEY"
```

No sequence numbers, no retry loops, no ExpectedRevision - just simple read-modify-write.

### 4. State Key Structure

**Current peer.md uses (with required delimiter change):**
```
# OLD format with : delimiter (INVALID for NATS KV)
[KEY_PREFIX]:cycle:current
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:metadata

# MUST CHANGE TO . delimiter
[KEY_PREFIX].cycle.current
[KEY_PREFIX].cycle.[CYCLE_NUMBER].metadata
[KEY_PREFIX].cycle.[CYCLE_NUMBER].plan
[KEY_PREFIX].cycle.[CYCLE_NUMBER].execution
[KEY_PREFIX].cycle.[CYCLE_NUMBER].express
[KEY_PREFIX].cycle.[CYCLE_NUMBER].review
```

**Declarative agents expect (with . delimiter):**
```
[KEY_PREFIX].cycle.[CYCLE_NUMBER]  # Single unified state object
```

## Required Changes to peer.md

### Step 5: Cycle Initialization (Lines 157-199)

**Change Required:**
Replace fragmented state initialization with unified state object creation.

```xml
<cycle_state_initialization>
  <!-- REMOVE these lines (note: also fixing delimiter) -->
  nats kv put agent-os-peer-state "[KEY_PREFIX].cycle.current" "[CYCLE_NUMBER]"
  nats kv put agent-os-peer-state "[KEY_PREFIX].cycle.[CYCLE_NUMBER].metadata" "{json_metadata}"
  
  <!-- ADD unified state creation (simplified v1 with . delimiter) -->
  CREATE unified state object:
  {
    "version": 1,
    "cycle_id": "[KEY_PREFIX].cycle.[CYCLE_NUMBER]",
    "metadata": {
      "instruction_name": "[INSTRUCTION_NAME]",
      "spec_name": "[SPEC_NAME]",
      "key_prefix": "[KEY_PREFIX]",
      "cycle_number": [CYCLE_NUMBER],
      "created_at": "[TIMESTAMP]",
      "status": "INITIALIZED",
      "current_phase": "planning"
    },
    "context": {
      "peer_mode": "[PEER_MODE]",
      "spec_aware": [SPEC_AWARE],
      "user_requirements": "[ORIGINAL_USER_INPUT]"
    },
    "phases": {
      "plan": {"status": "pending"},
      "execute": {"status": "pending"},
      "express": {"status": "pending"},
      "review": {"status": "pending"}
    }
  }
  
  <!-- NOTE: No history array in v1 for simplicity -->
  
  STORE using simple write: nats kv put agent-os-peer-state "[KEY_PREFIX].cycle.[CYCLE_NUMBER]" "{unified_state}"
</cycle_state_initialization>
```

### Step 7: Planning Phase (Lines 238-282)

**Change Required:**
Update subagent invocation to pass STATE_KEY instead of multiple parameters.

```xml
<instructions>
  ACTION: Use peer-planner subagent
  REQUEST: "Execute planning phase
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            Read the unified state from NATS KV at STATE_KEY which contains:
            - All context and metadata
            - Current sequence number for optimistic locking
            
            After planning:
            1. Read the current state
            2. Update phases.plan.output with your planning data
            3. Set phases.plan.status = 'completed'
            4. Update metadata.status = 'EXECUTING'
            5. Write the updated state back"
  WAIT: For planning completion
  VERIFY: State updated successfully
</instructions>
```

### Step 8: Execution Phase (Lines 284-328)

**Change Required:**
Simplify phase validation and context passing.

```xml
<phase_validation>
  READ: Unified state from [KEY_PREFIX].cycle.[CYCLE_NUMBER]
  CHECK: phases.plan.status == "completed"
  IF not completed:
    ERROR: "Cannot execute without completed planning phase"
    STOP execution
</phase_validation>

<instructions>
  ACTION: Use peer-executor subagent
  REQUEST: "Execute instruction phase
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            The unified state contains the plan at phases.plan.output.
            Update phases.execute with your progress and results."
  WAIT: For execution completion
  VERIFY: phases.execute.status == "completed"
</instructions>
```

### Step 9: Express Phase (Lines 330-367)

**Change Required:**
Unified state validation and simpler context.

```xml
<phase_validation>
  READ: Unified state from [KEY_PREFIX].cycle.[CYCLE_NUMBER]
  CHECK: phases.execute.status == "completed"
</phase_validation>

<instructions>
  ACTION: Use peer-express subagent
  REQUEST: "Format execution results
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            Access plan at phases.plan.output and execution at phases.execute.output.
            Create professional presentation and update phases.express."
  WAIT: For express completion
  PROCESS: Display formatted results to user
</instructions>
```

### Step 10: Review Phase (Lines 369-406)

**Change Required:**
Single state location for all phase data.

```xml
<instructions>
  ACTION: Use peer-review subagent
  REQUEST: "Review PEER execution
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            All phase outputs available in unified state object.
            Provide improvement recommendations in phases.review."
  WAIT: For review completion
  PROCESS: Share insights for continuous improvement
</instructions>
```

### Step 11: Cycle Completion (Lines 408-446)

**Change Required:**
Update unified state instead of multiple keys.

```xml
<cycle_finalization>
  READ: Current state from [KEY_PREFIX].cycle.[CYCLE_NUMBER]
  UPDATE:
    - metadata.status = "COMPLETED"
    - metadata.completed_at = "[TIMESTAMP]"
  WRITE: Simple update to state
</cycle_finalization>
```

## Benefits of Simplified Alignment (v1)

1. **Simplicity**: Single state object easier to understand and debug
2. **Consistency**: Peer.md and agents use same state model
3. **Performance**: Fewer NATS operations required
4. **Testability**: Easy to verify basic functionality works
5. **Foundation**: Proves the concept before adding complexity

## Implementation Strategy (v1)

### Single Phase Approach
- Implement unified state for new cycles only
- No backward compatibility needed (first iteration)
- No migration from old format required
- Focus on proving the concept works

### Orchestration Approach
- **v1 uses Simple Orchestration**: peer.md controls the flow sequentially
- Each phase must complete before the next begins
- No parallel phase execution in v1
- peer.md waits for each subagent to complete before invoking the next
- This eliminates most race condition risks in controlled testing

## Testing Requirements (Simplified v1)

1. **Basic Functionality**: Verify full PEER cycle completes with unified state
2. **State Transitions**: Each phase reads and updates state correctly
3. **Data Integrity**: All phase outputs are preserved in unified object
4. **Error Handling**: Basic error cases (missing state, invalid phase)
5. **Debug-ability**: Can easily inspect state at any point

## Peer Agent File Updates Required

### Summary: Complete Removal of Optimistic Locking

For the simplified v1 implementation, **ALL references to optimistic locking and sequence numbers must be removed** from:
- peer-planner.md
- peer-executor.md  
- peer-express.md
- peer-review.md

This includes removing the terms "optimistic", "sequence", "locking", "atomic", and related concepts throughout the files.

### Elements to REMOVE from all peer agent files:

1. **In Input Contract:**
   - Remove: `sequence (for optimistic locking)`
   - Remove: Any mention of sequence numbers
   - Remove: All optimistic locking references

2. **In Output Contract:**
   - Remove: `sequence (incremented)`
   - Remove: `use_optimistic_lock: true`
   - Remove: Any optimistic lock parameters

3. **In Process Flow:**
   - Remove: `<nats_operation type="kv_read_with_sequence">`
   - Replace with: Simple `nats kv get` operation
   - Remove: `<capture_sequence>true</capture_sequence>`
   - Remove: All sequence validation checks
   - Remove: `<check field="current_state.sequence" type="integer">`

4. **In State Update Steps:**
   - Remove: Any retry logic for sequence mismatches
   - Remove: `<expected_sequence>${current_state.sequence}</expected_sequence>`
   - Remove: Optimistic locking error handling
   - Remove: "USE: Optimistic locking" comments
   - Remove: "CAPTURE: Sequence number for optimistic locking"
   - Replace with: Simple `nats kv put` operation

5. **In Error Handling:**
   - Remove: Sequence conflict detection
   - Remove: Retry with backoff patterns
   - Remove: `on_sequence_mismatch` handlers

6. **In Documentation/Comments:**
   - Remove: "Always use optimistic locking" guidelines
   - Remove: "Atomic State Updates" sections that reference locking
   - Remove: Any mentions of optimistic locking in descriptions
   - Remove: Any incidental references to sequence numbers or locking in logging, comments, or auxiliary processes

### Example Transformation:

**REMOVE this pattern:**
```xml
<nats_operation type="kv_update_with_lock">
  <bucket>agent-os-peer-state</bucket>
  <key>${STATE_KEY}</key>
  <data>${updated_state}</data>
  <expected_sequence>${current_state.sequence}</expected_sequence>
  <on_conflict>
    <retry_count>3</retry_count>
    <backoff>exponential</backoff>
  </on_conflict>
</nats_operation>
```

**REPLACE with this pattern:**
```xml
<nats_operation type="kv_write">
  <bucket>agent-os-peer-state</bucket>
  <key>${STATE_KEY}</key>
  <data>${updated_state}</data>
</nats_operation>
```

## Implementation Checklist (Simplified v1)

### Key Delimiter Updates:
- [ ] Change ALL key delimiters from `:` to `.` throughout all files
- [ ] Update peer.md to use `.` delimiter (e.g., `peer.spec.feature.cycle.1`)
- [ ] Update all peer agent files to use `.` delimiter
- [ ] Update schema examples to use `.` delimiter

### Central Schema Creation:
- [ ] Create instructions/meta/unified_state_schema.md with v1 schema
- [ ] Ensure schema excludes all sequence and locking references
- [ ] Include clear field descriptions and constraints
- [ ] Add usage examples and ownership rules
- [ ] Use `.` delimiter in all key examples

### Peer.md Updates:
- [ ] Add reference to @instructions/meta/unified_state_schema.md
- [ ] Update Step 5 for unified state initialization (no sequence field)
- [ ] Update Step 7-10 for STATE_KEY passing
- [ ] Update Step 11 for unified state completion
- [ ] Remove all references to sequence numbers or optimistic locking
- [ ] Change all key delimiters from `:` to `.`

### Peer Agent Updates:
- [ ] peer-planner.md: Remove sequence references, use simple read/write, reference central schema, change `:` to `.`
- [ ] peer-executor.md: Remove sequence references, use simple read/write, reference central schema, change `:` to `.`
- [ ] peer-express.md: Remove sequence references, use simple read/write, reference central schema, change `:` to `.`
- [ ] peer-review.md: Remove sequence references, use simple read/write, reference central schema, change `:` to `.`
- [ ] Ensure all agents are updated simultaneously to avoid partial implementation issues
- [ ] Verify all key patterns use `.` delimiter for NATS KV compatibility

### Testing:
- [ ] Test basic read/write of unified state
- [ ] Verify all phases can access needed data
- [ ] Confirm no sequence-related errors occur
- [ ] Document unified state structure

## Risk Assessment (v1)

### Potential Issues
- **State Size**: Single object might be larger than fragmented approach
  - Mitigation: Use artifact pointers for large outputs (store actual data elsewhere, reference in state)
- **Race Conditions**: Simple read/write pattern vulnerable to concurrent updates
  - Mitigation: Enforce sequential phase execution in v1, address with locking in v2
- **Debugging**: Need good logging to track state changes
  - Mitigation: Add comprehensive logging of state transitions
- **Phase Dependencies**: All phases must agree on state structure
  - Mitigation: Central schema enforces consistency

### Mitigations
- Keep state structure simple initially
- Add comprehensive logging of state transitions
- Clear documentation of expected fields
- Sequential phase orchestration (peer.md controls flow)
- Monitor for state overwrites during testing

## Success Criteria (v1)

1. Full PEER cycle completes with unified state
2. No temp file dependencies
3. Each phase can read and update its section
4. State is inspectable at any point
5. Clear improvement over fragmented approach

## Next Steps

1. Implement minimal version in peer.md
2. Test with simple instruction (e.g., create-spec)
3. Verify all phases complete successfully
4. Document lessons learned
5. Plan v2 with optimistic locking if v1 succeeds