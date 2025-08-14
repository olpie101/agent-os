# Unified State Schema Design for PEER Agents

> Task 1: Design Unified State Schema
> Created: 2025-08-05

## Task 1.1: Current State Usage Analysis

### Current State Management Patterns

#### 1. Temporary File Dependencies
All PEER agents currently rely on temporary files for context passing:
- `/tmp/peer_args.txt` - Contains instruction, continue_mode, spec_name
- `/tmp/peer_context.txt` - Contains is_spec_aware, final_spec_name, key_prefix  
- `/tmp/peer_cycle.txt` - Contains current_cycle, key_prefix
- `/tmp/determined_spec_name.txt` - Used by peer-planner for create-spec

**Issues:**
- Files can be deleted or corrupted
- No atomic operations
- Race conditions possible
- Difficult to debug state issues

#### 2. NATS KV Key Patterns
Current key structure:
```
peer.spec.${spec_name}.cycle.${cycle_number}     # Cycle data
peer.spec.${spec_name}.meta                      # Metadata
${key_prefix}.cycle.${current_cycle}             # Alternative pattern
```

**Issues:**
- Multiple keys per cycle (fragmented state)
- No atomic updates across keys
- No sequence-based locking
- Direct `nats kv put` without conflict detection

#### 3. State Update Patterns
Current bash-based updates:
```bash
# Read
nats kv get agent-os-peer-state "key" --raw > /tmp/file.json

# Modify with jq
jq '.field = "value"' /tmp/file.json > /tmp/updated.json

# Write (no sequence check)
cat /tmp/updated.json | nats kv put agent-os-peer-state "key"
```

**Issues:**
- No optimistic locking
- Lost update problem
- Manual JSON manipulation error-prone

## Task 1.2: Unified JSON Schema Design

### Single State Object Per Cycle

```json
{
  "version": 2,
  "cycle_id": "peer:spec:feature-name:cycle:1",
  "sequence": 42,
  "metadata": {
    "instruction": "create-spec",
    "spec_name": "feature-name",
    "key_prefix": "peer:spec:feature-name",
    "cycle_number": 1,
    "created_at": "2025-08-05T10:00:00Z",
    "updated_at": "2025-08-05T10:15:00Z",
    "status": "in_progress",
    "current_phase": "execute"
  },
  "context": {
    "peer_mode": "new",
    "spec_aware": true,
    "instruction_args": "--spec=feature-name",
    "user_requirements": "Original user input for spec creation"
  },
  "phases": {
    "plan": {
      "status": "completed",
      "started_at": "2025-08-05T10:00:00Z",
      "completed_at": "2025-08-05T10:05:00Z",
      "sequence_at_start": 10,
      "sequence_at_complete": 15,
      "output": {
        "instruction_type": "spec-aware",
        "phases": [
          {
            "phase": "preparation",
            "steps": ["gather_context", "validate_prerequisites"]
          },
          {
            "phase": "execution",
            "steps": ["create_spec_structure", "generate_documentation"]
          }
        ],
        "success_criteria": {
          "overall": "Complete spec documentation created",
          "measurable": ["All files created", "User approval received"]
        },
        "risks": [
          {
            "risk": "Unclear requirements",
            "mitigation": "Ask clarifying questions",
            "likelihood": "medium"
          }
        ]
      },
      "errors": []
    },
    "execute": {
      "status": "in_progress",
      "started_at": "2025-08-05T10:05:00Z",
      "sequence_at_start": 16,
      "output": {
        "progress": "Creating spec files",
        "files_created": [
          ".agent-os/specs/2025-08-05-feature-name/spec.md"
        ],
        "user_interactions": []
      },
      "errors": []
    },
    "express": {
      "status": "pending"
    },
    "review": {
      "status": "pending"
    }
  },
  "history": [
    {
      "timestamp": "2025-08-05T10:00:00Z",
      "phase": "plan",
      "event": "started",
      "sequence": 10
    },
    {
      "timestamp": "2025-08-05T10:05:00Z",
      "phase": "plan",
      "event": "completed",
      "sequence": 15
    },
    {
      "timestamp": "2025-08-05T10:05:00Z",
      "phase": "execute",
      "event": "started",
      "sequence": 16
    }
  ]
}
```

### Key Design Decisions

1. **Single KV Entry**: All cycle data in one entry prevents partial updates
2. **Sequence Number**: Top-level sequence for optimistic locking
3. **Phase Sequences**: Track sequence at phase start/complete for debugging
4. **History Array**: Audit trail of all phase transitions
5. **Errors Array**: Per-phase error tracking
6. **Version Field**: Schema versioning for future migrations

## Task 1.3: Optimistic Locking Pattern

### Read-Process-Write Pattern

```xml
<state_update_pattern>
  <step name="read_with_sequence">
    <nats_operation type="kv_read">
      <bucket>agent-os-peer-state</bucket>
      <key>peer:spec:${spec_name}:cycle:${cycle_number}</key>
      <capture_sequence>true</capture_sequence>
      <output_to>current_state</output_to>
    </nats_operation>
  </step>
  
  <step name="process_update">
    <instructions>
      ACTION: Modify state for current operation
      INCREMENT: sequence number locally
      UPDATE: phase data and timestamps
      APPEND: history entry
    </instructions>
  </step>
  
  <step name="atomic_write">
    <nats_operation type="kv_update">
      <bucket>agent-os-peer-state</bucket>
      <key>peer:spec:${spec_name}:cycle:${cycle_number}</key>
      <data>${updated_state}</data>
      <expected_sequence>${current_state.sequence}</expected_sequence>
      <on_conflict>
        <retry_count>3</retry_count>
        <backoff>exponential</backoff>
      </on_conflict>
    </nats_operation>
  </step>
</state_update_pattern>
```

### Conflict Resolution

When sequence mismatch occurs:
1. Re-read current state
2. Check if our changes are still valid
3. Merge if possible, retry if safe
4. Fail with clear error if unresolvable

## Task 1.4: State Validation Rules

### Schema Validation

```xml
<validation_rules>
  <rule name="required_fields">
    <check>version exists and equals 2</check>
    <check>cycle_id matches expected pattern</check>
    <check>sequence is positive integer</check>
    <check>metadata.status in [initialized, in_progress, completed, failed]</check>
  </rule>
  
  <rule name="phase_transitions">
    <check>plan must complete before execute starts</check>
    <check>execute must complete before express starts</check>
    <check>express must complete before review starts</check>
    <check>only one phase in_progress at a time</check>
  </rule>
  
  <rule name="sequence_consistency">
    <check>sequence increases monotonically</check>
    <check>phase sequences align with history</check>
    <check>no sequence gaps in history</check>
  </rule>
</validation_rules>
```

### Error Handling

```xml
<error_handling>
  <error type="schema_validation_failed">
    <action>Log detailed validation errors</action>
    <action>Prevent state update</action>
    <action>Return clear error to user</action>
  </error>
  
  <error type="sequence_conflict">
    <action>Retry with fresh read (max 3)</action>
    <action>Log conflict details</action>
    <action>Fail if unresolvable</action>
  </error>
  
  <error type="corrupted_state">
    <action>Attempt recovery from history</action>
    <action>Create recovery snapshot</action>
    <action>Alert user to corruption</action>
  </error>
</error_handling>
```

## Task 1.5: Phase Transition Support

### Transition Matrix

| From Phase | To Phase | Validation Required |
|------------|----------|-------------------|
| (none) | plan | Cycle initialized |
| plan | execute | Plan status = completed |
| execute | express | Execute status = completed |
| express | review | Express status = completed |
| review | (complete) | Review status = completed |
| any | (failed) | Error occurred |

### State Transition Operations

```xml
<phase_transitions>
  <transition from="plan" to="execute">
    <validate>
      - plan.status == "completed"
      - plan.output exists and is valid
      - execute.status == "pending"
    </validate>
    <update>
      - execute.status = "in_progress"
      - execute.started_at = current_timestamp
      - execute.sequence_at_start = current_sequence
      - metadata.current_phase = "execute"
      - history.append(transition_event)
    </update>
  </transition>
</phase_transitions>
```

## Changes Required for peer.md

### Minimal Changes Needed

1. **State Key Pattern** (Line ~187-189):
   ```diff
   - nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:current" "[CYCLE_NUMBER]"
   - nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:metadata" "{json_metadata}"
   + nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]" "{unified_state_json}"
   ```

2. **Subagent Context Passing** (Lines ~252-280):
   - Instead of referencing temp files, pass state location
   - Subagents read directly from NATS KV using the unified key

3. **Phase Validation** (Lines ~290-296, ~336-342):
   - Check unified state object for phase status
   - Use sequence for safe updates

### Backward Compatibility

To maintain compatibility during transition:
1. Support reading old multi-key format
2. Migrate to unified format on first update
3. Version field allows schema evolution

## Implementation Priority

1. **First**: Define and validate unified schema (Task 1.2-1.4)
2. **Second**: Update peer-planner to use unified state (Task 2)
3. **Third**: Update peer-executor with optimistic locking (Task 3)
4. **Fourth**: Update peer-express and peer-review (Tasks 4-5)
5. **Finally**: Update peer.md to reference unified state (Task 6)

## Benefits of Unified State

1. **Atomicity**: Single KV entry prevents partial updates
2. **Consistency**: Optimistic locking prevents lost updates
3. **Debuggability**: Complete state in one place with history
4. **Reliability**: No temp file dependencies
5. **Performance**: Fewer NATS operations needed
6. **Maintainability**: Clear schema with validation