# Storage Mechanism Specification for PEER Process Flow

## Overview

This document specifies how the `STORE` directives in the PEER process flow should be implemented, defining explicit storage locations and mechanisms for all data management needs.

## Storage Types

### 1. NATS KV Storage (Persistent, Cross-Step)

For data that needs to persist across steps and be accessible by subagents.

**Key Format**: Use dots (`.`) as separators instead of colons
- Pattern: `peer.{context}.cycle.{number}.{category}.{field}`
- Example: `peer.spec.user-auth.cycle.42.context.peer_mode`

**Usage**:
```xml
STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.peer_mode = "new"
STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.instruction_name = "create-spec"
STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.spec_name = "user-auth"
```

### 2. Process Variables (Transient, Within-Step)

For temporary data used only within the current step.

**Usage**:
```xml
SET process variable: PEER_MODE = "new"
SET process variable: INSTRUCTION_NAME = "create-spec"
SET process variable: SPEC_NAME = "user-auth"
```

## Key Namespace Structure

### Global Context Keys
```
peer.global.cycle.{number}.context.{field}
peer.global.cycle.{number}.metadata
peer.global.cycle.{number}.status
peer.global.cycle.current
```

### Spec-Aware Context Keys
```
peer.spec.{spec-name}.cycle.{number}.context.{field}
peer.spec.{spec-name}.cycle.{number}.metadata
peer.spec.{spec-name}.cycle.{number}.status
peer.spec.{spec-name}.cycle.current
```

### Phase Output Keys
```
[KEY_PREFIX].cycle.{number}.plan
[KEY_PREFIX].cycle.{number}.plan_summary
[KEY_PREFIX].cycle.{number}.execution
[KEY_PREFIX].cycle.{number}.deliverables
[KEY_PREFIX].cycle.{number}.express
[KEY_PREFIX].cycle.{number}.express_summary
[KEY_PREFIX].cycle.{number}.review
[KEY_PREFIX].cycle.{number}.review_summary
[KEY_PREFIX].cycle.{number}.improvements
```

## Storage Examples by Step

### Step 3: Argument Parsing
```xml
<context_storage>
  STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.peer_mode = "new"
  STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.instruction_name = "create-spec"
  STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.spec_name = "user-auth"
</context_storage>
```

Expanded example:
```
STORE in NATS KV: peer.spec.user-auth.cycle.42.context.peer_mode = "new"
STORE in NATS KV: peer.spec.user-auth.cycle.42.context.instruction_name = "create-spec"
STORE in NATS KV: peer.spec.user-auth.cycle.42.context.spec_name = "user-auth"
```

### Step 5: Cycle Initialization
```xml
<cycle_metadata_storage>
  STORE in NATS KV: [KEY_PREFIX].cycle.current = "42"
  STORE in NATS KV: [KEY_PREFIX].cycle.42.metadata = {
    "cycle_number": 42,
    "instruction": "create-spec",
    "spec": "user-auth",
    "status": "initialized",
    "phases_completed": [],
    "created_at": "2025-08-05T10:30:00Z"
  }
</cycle_metadata_storage>
```

### Step 6: Spec Name Determination
```xml
<spec_name_storage>
  STORE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].context.determined_spec_name = "password-reset-flow"
  UPDATE in NATS KV: [KEY_PREFIX].cycle.[CYCLE_NUMBER].metadata.spec = "password-reset-flow"
</spec_name_storage>
```

## Subagent Data Passing

### Pattern 1: Output Key Parameter (Recommended by Expert)
```xml
PASS to subagent: --output-key=[KEY_PREFIX].cycle.[CYCLE_NUMBER].plan
```

Example:
```
peer-planner --instruction=create-spec --output-key=peer.spec.user-auth.cycle.42.plan
```

### Pattern 2: Context Location Parameter
```xml
PASS to subagent: --context-key=[KEY_PREFIX].cycle.[CYCLE_NUMBER].context
```

## NATS Commands Reference

### Store Value
```bash
nats kv put agent-os-peer-state "peer.global.cycle.42.context.peer_mode" "new"
```

### Retrieve Value
```bash
nats kv get agent-os-peer-state "peer.global.cycle.42.context.peer_mode"
```

### Update JSON Metadata
```bash
nats kv put agent-os-peer-state "peer.global.cycle.42.metadata" '{"cycle_number":42,"status":"planning"}'
```

### List Keys for Cycle
```bash
nats kv ls agent-os-peer-state --prefix "peer.global.cycle.42"
```

## Storage Guidelines

### When to Use NATS KV
- Data needed across steps
- Data needed by subagents
- Cycle metadata and status
- Phase outputs and results
- Anything that needs persistence

### When to Use Process Variables
- Temporary calculations within a step
- Loop counters
- Intermediate transformations
- Data that doesn't cross step boundaries

### Key Naming Conventions
1. Use dots (`.`) as separators
2. Use lowercase with hyphens for multi-word fields
3. Keep hierarchy consistent: namespace.context.cycle.number.category.field
4. Avoid special characters except dots and hyphens

## Implementation Notes

1. **Atomicity**: Consider implementing subagent-led persistence as recommended by expert analysis
2. **Cleanup**: Include key deletion patterns for cycle completion
3. **Validation**: Check key existence before retrieval to handle missing data gracefully
4. **Performance**: Use key prefixes for efficient listing and bulk operations

## Future Considerations

- Key expiration/TTL for automatic cleanup
- Key versioning for concurrent access
- Backup/restore patterns for cycle state
- Migration patterns if key structure changes

This specification provides a foundation for explicit storage management in the PEER process flow, eliminating ambiguity and ensuring consistent implementation.