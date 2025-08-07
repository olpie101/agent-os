# NATS KV Operations Standardization

> Created: 2025-08-06
> Purpose: Address critical NATS KV operation inconsistencies causing data corruption

## Issue Analysis

### Problem Description

During testing of the create-spec PEER cycle, the peer-review agent and final cycle completion steps corrupted the NATS KV state, resulting in complete data loss. Analysis of `peer.spec.walcommitter-operation-support.cycle.1` reveals:

- **Last valid revision:** 6 (10,685 bytes of valid JSON)
- **First corruption:** Revision 7 (10,819 bytes of malformed JSON)
- **Complete data loss:** Revisions 8-9 (0 bytes)

### Root Cause Analysis

1. **Inconsistent NATS Operations Across Agents**: Each agent uses different approaches for reading/writing NATS KV data
2. **No Standardized JSON Handling**: Different agents use different methods to manipulate JSON
3. **Missing JSON Validation**: No validation before writing corrupted JSON to NATS
4. **Lack of Error Handling**: No detection when NATS operations fail or corrupt data

### Observed Issues

From the NATS KV history:
- Revision 6: Valid complete JSON structure (express phase completed)
- Revision 7: Malformed JSON with missing closing brackets (peer-review attempt)
- Revision 8-9: Empty keys (final completion attempts failed)

## Standardized Solution for v1 (Script-Based)

### Core Requirements for v1

1. **Wrapper Scripts**: All PEER agents and automated processes must use scripts, never call NATS CLI directly
2. **JSON Validation Mandatory**: All JSON must be validated before writing to NATS
3. **Error Propagation**: All errors must be printed and propagated to agents
4. **JSON Logging**: The JSON being written must be logged for debugging
5. **Use `nats kv update`**: For modifications, use update with revision number
6. **Manual Recovery Exception**: Human operators may use NATS CLI directly for recovery operations only

## Wrapper Scripts

### Installation Path

The wrapper scripts must be installed to `~/.agent-os/scripts/peer/` by the setup.sh script during Agent OS installation. All PEER agents must reference scripts at this installed location, NOT local project paths.

### 1. read-state.sh

Script for reading state from NATS KV:

```bash
#!/bin/bash
# read-state.sh - Wrapper for reading NATS KV state
# Usage: ./read-state.sh <STATE_KEY>

STATE_KEY="$1"

if [ -z "$STATE_KEY" ]; then
  echo "ERROR: STATE_KEY is required as first argument" >&2
  exit 1
fi

# Read current state
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw 2>&1)
READ_EXIT=$?

if [ $READ_EXIT -ne 0 ]; then
  echo "ERROR: Failed to read state from NATS KV at key: $STATE_KEY" >&2
  echo "NATS Error: $STATE" >&2
  exit 1
fi

# Validate JSON is readable
echo "$STATE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Invalid JSON in NATS KV state at key: $STATE_KEY" >&2
  echo "Raw data received (first 500 chars): ${STATE:0:500}" >&2
  exit 1
fi

# Output the valid JSON to stdout (for agent to capture)
echo "$STATE"
```

### 2. update-state.sh

Script for updating state in NATS KV:

```bash
#!/bin/bash
# update-state.sh - Wrapper for updating NATS KV state
# Usage: ./update-state.sh <STATE_KEY> <JQ_FILTER>
# The JQ filter receives the current state and should output the modified state

STATE_KEY="$1"
JQ_FILTER="$2"

if [ -z "$STATE_KEY" ] || [ -z "$JQ_FILTER" ]; then
  echo "ERROR: STATE_KEY and JQ_FILTER are required" >&2
  echo "Usage: ./update-state.sh <STATE_KEY> <JQ_FILTER>" >&2
  exit 1
fi

# Step 1: Read current state
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw 2>&1)
READ_EXIT=$?

if [ $READ_EXIT -ne 0 ]; then
  echo "ERROR: Failed to read state from NATS KV" >&2
  echo "NATS Error: $STATE" >&2
  exit 1
fi

# Step 2: Extract revision number
REVISION=$(nats kv get agent-os-peer-state "$STATE_KEY" 2>/dev/null | grep 'Revision:' | awk '{print $2}')
if [ -z "$REVISION" ]; then
  echo "ERROR: Failed to get revision number for key: $STATE_KEY" >&2
  exit 1
fi

# Step 3: Validate current JSON
echo "$STATE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Current state has invalid JSON at key: $STATE_KEY" >&2
  exit 1
fi

# Step 4: Apply JQ filter (capture both output and errors)
JQ_ERROR=$(mktemp)
MODIFIED_STATE=$(echo "$STATE" | jq "$JQ_FILTER" 2>"$JQ_ERROR")
JQ_EXIT=$?

if [ $JQ_EXIT -ne 0 ]; then
  echo "ERROR: Failed to modify JSON with jq (exit code: $JQ_EXIT)" >&2
  echo "JQ Error: $(cat "$JQ_ERROR")" >&2
  echo "JQ Filter was: $JQ_FILTER" >&2
  rm -f "$JQ_ERROR"
  exit 1
fi
rm -f "$JQ_ERROR"

# Step 5: Validate modified JSON
echo "$MODIFIED_STATE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Modified state resulted in invalid JSON" >&2
  echo "Modified JSON (first 500 chars): ${MODIFIED_STATE:0:500}" >&2
  exit 1
fi

# Step 6: Log the JSON being written (to stderr so it doesn't interfere with stdout)
echo "INFO: Writing JSON to $STATE_KEY at revision $REVISION" >&2
echo "INFO: JSON size: $(echo "$MODIFIED_STATE" | wc -c) bytes" >&2
if [ $(echo "$MODIFIED_STATE" | wc -c) -lt 5000 ]; then
  echo "INFO: Full JSON:" >&2
  echo "$MODIFIED_STATE" | jq . >&2
else
  echo "INFO: JSON preview (first 1000 chars):" >&2
  echo "${MODIFIED_STATE:0:1000}" >&2
fi

# Step 7: Update with revision check
UPDATE_RESULT=$(echo "$MODIFIED_STATE" | nats kv update agent-os-peer-state "$STATE_KEY" "$REVISION" 2>&1)
UPDATE_EXIT=$?

if [ $UPDATE_EXIT -ne 0 ]; then
  echo "ERROR: Failed to update state (likely revision mismatch)" >&2
  echo "Expected revision was: $REVISION" >&2
  echo "NATS Error: $UPDATE_RESULT" >&2
  echo "Another process may have updated the state concurrently" >&2
  exit 1
fi

echo "SUCCESS: Updated state at key $STATE_KEY at revision $REVISION" >&2
# Output success to stdout for agent to confirm
echo "OK"
```

## Agent Pre-Flight Requirements

### Mandatory Pre-Flight Checks

All PEER agents (peer-planner.md, peer-executor.md, peer-express.md, peer-review.md) MUST include the following pre-flight checks at the beginning of their implementation:

```xml
<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
  EXECUTE: @~/.agent-os/instructions/meta/nats-kv-operations.md
</pre_flight_check>
```

This ensures:
1. Agents follow standard processing rules from pre-flight.md
2. Agents understand and comply with NATS KV operation standards
3. Wrapper scripts are used instead of direct NATS CLI calls
4. JSON validation occurs before any writes

### Stream References Removal

All references to NATS streams for events must be removed from agent files. The following pattern should NOT appear:

```xml
<!-- REMOVE ALL INSTANCES LIKE THIS -->
<to_stream>
  stream: agent-os-peer-events
  subject: peer.events.${KEY_PREFIX}.cycle.${CYCLE_NUMBER}
  event: plan_completed
</to_stream>
```

Reasoning: v1 implementation focuses on KV storage only, without event streaming complexity.

## How Agent Files Need to Change

### Current Pattern (PROBLEMATIC)

Agents currently have inline NATS operations like:

```xml
<nats_read>
  STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw)
  # ... direct manipulation
</nats_read>
```

### New Pattern (REQUIRED)

Agents must change to use wrapper scripts:

```xml
<step number="X" name="read_state">
  
### Read Current State

<read_operation>
  # Use the read-state.sh wrapper script from installed location
  STATE=$(~/.agent-os/scripts/peer/read-state.sh "$STATE_KEY")
  if [ $? -ne 0 ]; then
    # Error already printed by script
    exit 1
  fi
  
  # STATE now contains valid JSON
</read_operation>

</step>

<step number="Y" name="update_state">

### Update State

<update_operation>
  # Define the JQ filter for this phase
  # Example for planner:
  JQ_FILTER='
    .phases.plan.status = "completed" |
    .phases.plan.completed_at = (now | todate) |
    .phases.plan.output = {
      "instruction_type": "spec-aware",
      "phases": ["preparation", "execution", "finalization"],
      "success_criteria": "Spec documentation created"
    } |
    .metadata.updated_at = (now | todate) |
    .metadata.current_phase = "execute"
  '
  
  # Use the update-state.sh wrapper script from installed location
  RESULT=$(~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER")
  if [ $? -ne 0 ]; then
    # Error already printed by script
    exit 1
  fi
  
  # Success - continue with next steps
</update_operation>

</step>
```

### Example Changes for Each Agent

#### peer-planner.md

```xml
<step number="5" name="update_planning_state">

### Step 5: Update Planning State

<update_logic>
  # Define JQ filter for planning phase
  JQ_FILTER='
    .phases.plan.status = "completed" |
    .phases.plan.completed_at = (now | todate) |
    .phases.plan.output = {
      "instruction_type": $inst_type,
      "phases": $phases,
      "success_criteria": $criteria
    } |
    .metadata.updated_at = (now | todate) |
    .metadata.status = "EXECUTING" |
    .metadata.current_phase = "execute"
  ' \
  --arg inst_type "$INSTRUCTION_TYPE" \
  --argjson phases "$PHASES_JSON" \
  --arg criteria "$SUCCESS_CRITERIA"
  
  # Update using wrapper from installed location
  ~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER"
</update_logic>

</step>
```

#### peer-executor.md

```xml
<step number="6" name="update_execution_state">

### Step 6: Update Execution State

<update_logic>
  # Define JQ filter for execution phase
  JQ_FILTER='
    .phases.execute.status = "completed" |
    .phases.execute.completed_at = (now | todate) |
    .phases.execute.output = {
      "files_created": $files,
      "files_modified": $modified,
      "results": $results
    } |
    .metadata.updated_at = (now | todate) |
    .metadata.status = "EXPRESSING" |
    .metadata.current_phase = "express"
  ' \
  --argjson files "$FILES_CREATED_JSON" \
  --argjson modified "$FILES_MODIFIED_JSON" \
  --argjson results "$EXECUTION_RESULTS_JSON"
  
  # Update using wrapper from installed location
  ~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER"
</update_logic>

</step>
```

#### peer.md (for final completion)

```xml
<cycle_finalization>
  # Read current state using wrapper from installed location
  STATE=$(~/.agent-os/scripts/peer/read-state.sh "$STATE_KEY")
  if [ $? -ne 0 ]; then
    exit 1
  fi
  
  # Define simple update for final status
  JQ_FILTER='
    .metadata.status = "COMPLETED" |
    .metadata.completed_at = (now | todate)
  '
  
  # Update using wrapper from installed location
  ~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER"
</cycle_finalization>
```

## Key Benefits of This Approach

1. **No Direct NATS CLI for Agents**: Automated processes cannot accidentally misuse NATS commands
2. **Error Propagation**: All errors are printed to stderr and propagated via exit codes
3. **JSON Logging**: All JSON writes are logged for debugging
4. **Consistent Patterns**: Every agent uses identical wrapper scripts
5. **Centralized Fixes**: Any fixes to NATS operations only need to be made in the scripts
6. **Recovery Flexibility**: Human operators retain ability to use NATS CLI for emergency recovery

## Script Installation

Scripts must be installed by setup.sh to:
```
~/.agent-os/
└── scripts/
    └── peer/
        ├── create-state.sh
        ├── read-state.sh
        └── update-state.sh
```

The setup.sh script will:
1. Create the directory structure
2. Copy scripts from the repository
3. Make them executable:
```bash
chmod +x ~/.agent-os/scripts/peer/create-state.sh
chmod +x ~/.agent-os/scripts/peer/read-state.sh
chmod +x ~/.agent-os/scripts/peer/update-state.sh
```

## Phase Ownership Enforcement

The wrapper scripts don't enforce phase ownership directly, but agents must still follow these rules:

| Agent | Allowed JQ Filters |
|-------|-------------------|
| peer-planner | Only modify `.phases.plan` and metadata |
| peer-executor | Only modify `.phases.execute` and metadata |
| peer-express | Only modify `.phases.express` and metadata |
| peer-review | Only modify `.phases.review` and metadata |
| peer.md | Can modify `.metadata` for cycle management |

## Testing Requirements

Before deployment:
1. Test each wrapper script independently
2. Test complete PEER cycle with all agents using wrappers
3. Verify error messages are clear and actionable
4. Confirm JSON logging helps with debugging
5. Ensure no data corruption occurs

## Recovery Operations

### Manual Recovery by Operators

When state corruption occurs, human operators may use NATS CLI directly for recovery:

1. **Inspect history** to find last valid revision
2. **Restore state** from a known good revision
3. **Manually repair** corrupted JSON if needed

These manual operations are exempt from the wrapper script requirement as they are:
- Performed by humans, not automated agents
- Used only in emergency situations
- Require flexibility and direct access

### Agent Restrictions

PEER agents and automated processes:
- **MUST** use wrapper scripts for all operations
- **CANNOT** perform recovery operations
- **CANNOT** call NATS CLI directly under any circumstances

## Migration Steps

1. Update setup.sh to install wrapper scripts to `~/.agent-os/scripts/peer/`
2. Update all PEER agents to use wrapper scripts from installed location
3. Remove all direct NATS CLI calls from agents
4. Test complete cycle with installed scripts
5. Document in meta instruction file

This approach ensures consistency, safety, and debuggability while preventing the data corruption issues we encountered, while still allowing human operators the flexibility needed for emergency recovery.