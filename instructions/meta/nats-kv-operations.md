---
description: NATS KV Operations Standards for PEER Pattern
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# NATS KV Operations Standards

## Overview

Mandatory standards for all NATS KV operations in PEER pattern execution. These patterns prevent data corruption and ensure consistency across all agents.

**IMPORTANT**: This standard applies to all PEER agents and automated processes. Manual recovery operations by human operators are exempt from these restrictions.

<pre_flight_check>
  EXECUTE: @.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

## Critical Background

Previous implementations suffered from:
- Inconsistent NATS operations across agents
- Manual JSON construction causing malformed data
- No validation before writing to NATS
- Complete data loss from corrupted writes

This standard enforces wrapper scripts that all agents MUST use.

## Mandatory Wrapper Scripts

### Location

All NATS operations MUST use these wrapper scripts:
- `~/.agent-os/scripts/peer/create-state.sh` - For creating new keys (only if they don't exist)
- `~/.agent-os/scripts/peer/read-state.sh` - For reading state
- `~/.agent-os/scripts/peer/update-state.sh` - For updating existing state

PEER agents and automated processes are PROHIBITED from calling NATS CLI directly.

### Create Operations

<create_pattern>
  # For creating NEW keys (peer.md cycle initialization)
  INITIAL_STATE='{"version": 1, "metadata": {...}, "phases": {...}}'
  
  RESULT=$(~/.agent-os/scripts/peer/create-state.sh "$STATE_KEY" "$INITIAL_STATE")
  if [ $? -ne 0 ]; then
    # Error already printed by script to stderr
    exit 1
  fi
  # Key created successfully
</create_pattern>

### Read Operations

<read_pattern>
  # ALL read operations MUST use this pattern
  STATE=$(~/.agent-os/scripts/peer/read-state.sh "$STATE_KEY")
  if [ $? -ne 0 ]; then
    # Error already printed by script to stderr
    exit 1
  fi
  # STATE now contains valid JSON
</read_pattern>

### Update Operations

<update_pattern>
  # Define JQ filter for modifications
  JQ_FILTER='
    .phases.PHASE_NAME.status = "completed" |
    .phases.PHASE_NAME.completed_at = (now | todate) |
    .metadata.updated_at = (now | todate)
  '
  
  # ALL updates MUST use this pattern
  RESULT=$(~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER")
  if [ $? -ne 0 ]; then
    # Error already printed by script to stderr
    exit 1
  fi
  # Update successful
</update_pattern>

### Hybrid Approach for Complex JSON (--json-file)

For complex JSON objects that are difficult to pass as command arguments, use the --json-file option:

<hybrid_pattern>
  # Create temporary directory for JSON files
  TEMP_DIR="/tmp/peer-${AGENT_NAME}"
  mkdir -p "$TEMP_DIR"
  
  # Write complex JSON to temporary files
  EXPRESS_FILE="${TEMP_DIR}/express_output_$$.json"
  CYCLE_FILE="${TEMP_DIR}/cycle_result_$$.json"
  
  echo "$EXPRESS_OUTPUT_JSON" > "$EXPRESS_FILE"
  echo "$CYCLE_RESULT_JSON" > "$CYCLE_FILE"
  
  # IMPORTANT: --slurpfile creates arrays, so use $var[0] to access the object
  JQ_FILTER='
    .phases.express.output = $express[0] |
    .result = $cycle[0] |
    .metadata.updated_at = (now | todate)
  '
  
  # Use --json-file for complex JSON injection
  RESULT=$(~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER" \
    --json-file "express=${EXPRESS_FILE}" \
    --json-file "cycle=${CYCLE_FILE}")
  UPDATE_EXIT=$?
  
  # Always clean up temporary files
  rm -f "$EXPRESS_FILE" "$CYCLE_FILE"
  
  if [ $UPDATE_EXIT -ne 0 ]; then
    exit 1
  fi
</hybrid_pattern>

#### When to Use --json-file

Use the hybrid approach when:
- JSON objects contain special characters that are difficult to escape
- JSON objects are too large for command line arguments
- Multiple complex JSON objects need to be injected
- JSON is generated dynamically and might contain unpredictable content

#### Important Notes

1. **Array Access**: The `--slurpfile` mechanism used internally creates arrays, so always use `$varname[0]` to access your JSON object
2. **Validation**: Always validate JSON before writing to temp files
3. **Cleanup**: Always remove temporary files after use, even on error
4. **Variable Names**: Must follow jq variable naming rules (start with letter or underscore)
5. **Multiple Files**: You can use multiple --json-file arguments in a single command

#### Example with Validation

<validated_hybrid_example>
  # Validate JSON before writing to temp files
  echo "$COMPLEX_JSON" | jq empty 2>&1 >/dev/null
  if [ $? -ne 0 ]; then
    echo "ERROR: Invalid JSON in COMPLEX_JSON" >&2
    exit 1
  fi
  
  # Write to temp file
  TEMP_FILE="/tmp/peer-express/data_$$.json"
  echo "$COMPLEX_JSON" > "$TEMP_FILE"
  
  # Use in filter with array access
  JQ_FILTER='.phases.express.output = $data[0]'
  
  RESULT=$(~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER" \
    --json-file "data=${TEMP_FILE}")
  
  # Clean up
  rm -f "$TEMP_FILE"
</validated_hybrid_example>

## Phase Ownership Rules

Each agent MUST only modify its designated phase:

<phase_ownership>
  <agent name="peer-planner">
    ALLOWED: .phases.plan, .metadata
    PROHIBITED: .phases.execute, .phases.express, .phases.review
  </agent>
  
  <agent name="peer-executor">
    ALLOWED: .phases.execute, .metadata
    PROHIBITED: .phases.plan, .phases.express, .phases.review
  </agent>
  
  <agent name="peer-express">
    ALLOWED: .phases.express, .metadata
    PROHIBITED: .phases.plan, .phases.execute, .phases.review
  </agent>
  
  <agent name="peer-review">
    ALLOWED: .phases.review, .metadata
    PROHIBITED: .phases.plan, .phases.execute, .phases.express
  </agent>
  
  <agent name="peer.md">
    ALLOWED: .metadata (for cycle management)
    NOTE: Creates initial state, updates final completion
  </agent>
</phase_ownership>

## JQ Filter Requirements

### Mandatory Practices

1. **Use jq for ALL JSON manipulation** - No string concatenation
2. **Include timestamp updates** - Always update metadata.updated_at
3. **Use --arg for variables** - Never embed variables directly
4. **Validate filter syntax** - Test filters before deployment

### Example Filters by Agent

#### peer-planner
```bash
JQ_FILTER='
  .phases.plan.status = "completed" |
  .phases.plan.completed_at = (now | todate) |
  .phases.plan.output = {
    "instruction_type": $type,
    "phases": $phases,
    "success_criteria": $criteria
  } |
  .metadata.updated_at = (now | todate) |
  .metadata.status = "EXECUTING" |
  .metadata.current_phase = "execute"
' \
--arg type "$INSTRUCTION_TYPE" \
--argjson phases "$PHASES_JSON" \
--arg criteria "$SUCCESS_CRITERIA"
```

#### peer-executor
```bash
JQ_FILTER='
  .phases.execute.status = "completed" |
  .phases.execute.completed_at = (now | todate) |
  .phases.execute.output = {
    "files_created": $files,
    "results": $results
  } |
  .metadata.updated_at = (now | todate) |
  .metadata.status = "EXPRESSING"
' \
--argjson files "$FILES_JSON" \
--argjson results "$RESULTS_JSON"
```

## Error Handling

### Script Error Messages

The wrapper scripts provide detailed error messages to stderr:
- Failed reads include the key and NATS error
- Invalid JSON shows preview of corrupted data
- JQ failures include the filter and error details
- Update failures show revision mismatch information

### Agent Responsibilities

Agents MUST:
1. Check exit codes from wrapper scripts
2. Exit immediately on error (errors are already logged)
3. NOT attempt to retry operations
4. NOT suppress or hide error messages

## Validation Chain

<validation_sequence>
  1. Read validates JSON from NATS
  2. JQ filter execution is validated
  3. Modified JSON is validated before write
  4. Update operation is validated with revision check
  5. Success is logged with revision number
</validation_sequence>

## Prohibited Patterns

### NEVER Do These

<prohibited>
  # WRONG - Direct NATS call
  STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw)
  
  # WRONG - Manual JSON construction
  JSON="{\"status\": \"$STATUS\"}"
  
  # WRONG - No validation
  echo "$JSON" | nats kv put agent-os-peer-state "$STATE_KEY"
  
  # WRONG - String concatenation for JSON
  STATE="${STATE%\}}, \"new_field\": \"value\"}"
  
  # WRONG - Modifying wrong phase
  # peer-planner modifying execute phase
  jq '.phases.execute.status = "pending"'
</prohibited>

## Debugging Support

### Logging

The update script logs to stderr:
- Key and revision being updated
- JSON size in bytes
- Full JSON if under 5KB (formatted)
- Preview if over 5KB (first 1000 chars)

### State Inspection

To inspect current state:
```bash
~/.agent-os/scripts/peer/read-state.sh "peer.spec.example.cycle.1" | jq .
```

### History Review

To review state history after corruption:
```bash
nats kv history agent-os-peer-state "peer.spec.example.cycle.1"
```

## Recovery Procedures (Manual Operation Only)

**NOTE**: These recovery procedures are for manual intervention by human operators only. PEER agents must NEVER perform these operations. Direct NATS CLI usage is permitted only for emergency recovery situations by operators.

### Corrupted State Recovery

If state becomes corrupted:

1. Identify last valid revision:
   ```bash
   nats kv history agent-os-peer-state "$STATE_KEY"
   ```

2. Get valid state:
   ```bash
   nats kv get agent-os-peer-state "$STATE_KEY" --revision=$VALID_REV
   ```

3. Restore if needed (manually):
   ```bash
   nats kv get agent-os-peer-state "$STATE_KEY" --revision=$VALID_REV --raw | \
     nats kv put agent-os-peer-state "$STATE_KEY"
   ```

## Implementation Checklist

All PEER agents MUST:
- [ ] Use wrapper scripts for ALL NATS operations
- [ ] Never call NATS CLI directly
- [ ] Only modify their designated phase
- [ ] Use jq for ALL JSON manipulation
- [ ] Check exit codes from scripts
- [ ] Exit on errors (don't retry)
- [ ] Include proper error handling

## Testing Requirements

Before deployment:
1. Test each wrapper script independently
2. Verify error messages are clear
3. Test complete PEER cycle
4. Confirm no data corruption
5. Verify phase ownership is maintained

## Compliance

This standard is MANDATORY. Any deviation requires explicit documentation and approval. Non-compliance risks data corruption and system failure.