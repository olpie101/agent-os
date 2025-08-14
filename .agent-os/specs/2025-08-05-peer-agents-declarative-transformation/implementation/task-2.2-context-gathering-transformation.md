# Task 2.2: Replace Temp File Usage with Structured Context Gathering

> Subtask of Task 2: Transform peer-planner to Declarative Pattern
> Created: 2025-08-05

## Overview

This document details how temp file dependencies were replaced with structured context gathering from the unified NATS KV state.

## Temp File Elimination Mapping

### Previous Temp File Dependencies

The original peer-planner relied on these temp files:

1. **`/tmp/peer_args.txt`**
   - Contents: `instruction`, `continue_mode`, `spec_name`
   - Replaced by: `current_state.metadata.instruction_name`, `current_state.context.peer_mode`, `current_state.metadata.spec_name`

2. **`/tmp/peer_context.txt`**
   - Contents: `is_spec_aware`, `final_spec_name`, `key_prefix`
   - Replaced by: `current_state.context.spec_aware`, `current_state.metadata.spec_name`, `current_state.metadata.key_prefix`

3. **`/tmp/peer_cycle.txt`**
   - Contents: `current_cycle`, `key_prefix`
   - Replaced by: `current_state.metadata.cycle_number`, `current_state.metadata.key_prefix`

4. **`/tmp/determined_spec_name.txt`**
   - Contents: Spec name determined from user requirements
   - Replaced by: In-memory variable `determined_spec_name` within process flow

5. **`/tmp/planning_output.json`**
   - Contents: Generated planning JSON
   - Replaced by: Direct state update in Step 6

6. **`/tmp/cycle.json`, `/tmp/updated_cycle.json`**
   - Contents: Temporary cycle state for updates
   - Replaced by: In-memory state manipulation with optimistic locking

## Structured Context Gathering Pattern

### Input Contract

```xml
<input_contract>
  <from_nats>
    bucket: agent-os-peer-state
    key: ${STATE_KEY}  <!-- Single unified state location -->
    required_fields:
      - metadata.instruction_name    <!-- Replaces /tmp/peer_args.txt -->
      - metadata.spec_name           <!-- Replaces /tmp/peer_context.txt -->
      - metadata.cycle_number        <!-- Replaces /tmp/peer_cycle.txt -->
      - metadata.key_prefix          <!-- Replaces /tmp/peer_context.txt -->
      - context.peer_mode            <!-- Replaces /tmp/peer_args.txt -->
      - context.spec_aware           <!-- Replaces /tmp/peer_context.txt -->
      - sequence                     <!-- New: For optimistic locking -->
  </from_nats>
</input_contract>
```

### Context Gathering Process

#### Step 1: Single State Read

```xml
<nats_operation type="kv_read_with_sequence">
  <bucket>agent-os-peer-state</bucket>
  <key>${STATE_KEY}</key>
  <capture_sequence>true</capture_sequence>
  <output_to>current_state</output_to>
</nats_operation>
```

This single read operation replaces:
- Multiple `cat /tmp/*.txt` operations
- Multiple `source /tmp/*.txt` bash commands
- Multiple `nats kv get` operations for different keys

#### Step 2: Direct Field Access

Instead of bash variable sourcing:
```bash
# OLD
source /tmp/peer_args.txt
echo "instruction=$instruction"
```

Now use direct field access:
```xml
<!-- NEW -->
${current_state.metadata.instruction_name}
${current_state.context.peer_mode}
```

## Benefits of Structured Context Gathering

### 1. Atomicity
- **Before**: Multiple files could be in inconsistent states
- **After**: Single atomic read ensures consistency

### 2. Error Handling
- **Before**: Missing temp files caused bash script failures
- **After**: Structured validation with clear error messages

### 3. Debugging
- **Before**: Temp files could be deleted or corrupted
- **After**: State persisted in NATS KV with history

### 4. Concurrency
- **Before**: Race conditions with temp file access
- **After**: Optimistic locking prevents conflicts

### 5. Testability
- **Before**: Required filesystem setup for testing
- **After**: Can mock NATS KV operations cleanly

## Context Validation Pattern

```xml
<validation>
  <check field="current_state" not_null="true">
    <on_failure>
      <error>Cannot read cycle state from NATS KV</error>
      <stop>true</stop>
    </on_failure>
  </check>
  <check field="current_state.metadata.instruction_name" not_empty="true">
    <on_failure>
      <error>Instruction name not found in state</error>
      <stop>true</stop>
    </on_failure>
  </check>
</validation>
```

## Migration Path

### Backward Compatibility

During transition, the declarative planner can support both patterns:

```xml
<context_source>
  <primary>
    <!-- Try unified state first -->
    <from_nats key="${STATE_KEY}"/>
  </primary>
  <fallback>
    <!-- Fall back to temp files if state not found -->
    <from_files>
      <file path="/tmp/peer_args.txt"/>
      <file path="/tmp/peer_context.txt"/>
      <file path="/tmp/peer_cycle.txt"/>
    </from_files>
  </fallback>
</context_source>
```

### Complete Migration

Once all PEER agents are transformed:
1. Remove fallback logic
2. Delete temp file creation from peer.md
3. Rely solely on unified state

## Implementation Notes

### Key Design Decisions

1. **STATE_KEY as Variable**: The state key is provided as a variable to the agent, eliminating the need to construct it from multiple sources.

2. **All Context in State**: Every piece of context needed is available in the unified state, eliminating file system dependencies.

3. **Structured Access**: Using dot notation (`current_state.metadata.instruction_name`) provides clear, type-safe access to nested fields.

4. **Validation First**: Context validation happens immediately after reading, catching issues early.

## Testing Verification

To verify temp file elimination:

1. **No Bash File Operations**: The declarative planner has no `cat`, `source`, or file write operations
2. **Single NATS Read**: Only one KV read operation for all context
3. **No Temp Directory Access**: No references to `/tmp/` in the declarative version
4. **Clean Error Messages**: Validation failures provide clear context about missing fields

## Summary

The transformation from temp file usage to structured context gathering provides:
- **Reliability**: No file system dependencies
- **Consistency**: Single source of truth
- **Performance**: One read operation instead of multiple file accesses
- **Maintainability**: Clear structure and validation
- **Debuggability**: State inspection through NATS tools

This completes the replacement of temp file usage with structured context gathering for the peer-planner agent.