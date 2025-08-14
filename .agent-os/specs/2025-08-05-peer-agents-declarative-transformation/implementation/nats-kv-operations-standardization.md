# NATS KV Operations Declarative Patterns

> Created: 2025-08-06
> Purpose: XML declarative patterns for PEER agent NATS KV operations
> Status: XML Declarative Approach

## Problem Analysis

### Issue Description

PEER agents require consistent NATS KV operations but script-based approaches create brittleness and maintenance overhead. The solution is declarative XML patterns that define NATS operations requirements.

### Root Cause Analysis

1. **Inconsistent Operation Patterns**: Different agents use different approaches for NATS data access
2. **Script Dependencies**: Script-based solutions are brittle and hard to maintain
3. **Missing Validation Patterns**: No standardized validation before data operations
4. **Error Handling Complexity**: Different error handling approaches across agents

### Observed Requirements

From PEER pattern operation analysis:
- Need consistent state reading patterns across all agents
- Require reliable state update patterns with validation
- Must have clear error handling and recovery patterns
- Should preserve data integrity through structured operations

## Declarative NATS Operation Patterns

### State Reading Pattern

```xml
<nats_operation name="read_cycle_state">
  <operation_type>read</operation_type>
  <target>
    <bucket>agent-os-peer-state</bucket>
    <key source="STATE_KEY">Current cycle state key</key>
  </target>
  
  <validation>
    <require_key_exists>true</require_key_exists>
    <require_valid_json>true</require_valid_json>
    <schema_validation>unified_state_schema.md</schema_validation>
  </validation>
  
  <error_handling>
    <key_not_found>
      <action>log error with key name</action>
      <action>exit with descriptive message</action>
    </key_not_found>
    <invalid_json>
      <action>log first 500 characters of data</action>
      <action>report JSON validation error</action>
      <action>exit with recovery suggestions</action>
    </invalid_json>
    <nats_connection_error>
      <action>report NATS server connectivity issue</action>
      <action>suggest server status check</action>
      <action>exit with connection details</action>
    </nats_connection_error>
  </error_handling>
  
  <output_format>valid_json_to_stdout</output_format>
</nats_operation>
```

### State Update Pattern

```xml
<nats_operation name="update_cycle_state">
  <operation_type>update</operation_type>
  <target>
    <bucket>agent-os-peer-state</bucket>
    <key source="STATE_KEY">Current cycle state key</key>
  </target>
  
  <transformation>
    <method>jq_filter</method>
    <filter source="JQ_FILTER">JSON transformation to apply</filter>
    <additional_data source="file_injection">Optional data injection from files</additional_data>
  </transformation>
  
  <validation>
    <pre_update>
      <rule>current state must be valid JSON</rule>
      <rule>transformation filter must be valid</rule>
      <rule>injected data must be valid JSON</rule>
    </pre_update>
    <post_update>
      <rule>result must be valid JSON</rule>
      <rule>result must match schema requirements</rule>
      <rule>required fields must be preserved</rule>
    </post_update>
  </validation>
  
  <conflict_resolution>
    <use_revision_checking>true</use_revision_checking>
    <retry_on_conflict>3_attempts_max</retry_on_conflict>
    <exponential_backoff>100ms_initial</exponential_backoff>
  </conflict_resolution>
  
  <error_handling>
    <transformation_error>
      <action>log JQ filter and input data</action>
      <action>report specific transformation failure</action>
      <action>preserve original state</action>
    </transformation_error>
    <validation_failure>
      <action>log validation error details</action>
      <action>preserve failed JSON for debugging</action>
      <action>exit without updating NATS</action>
    </validation_failure>
    <update_conflict>
      <action>log current and expected revisions</action>
      <action>retry with fresh state read</action>
      <action>fail after max retries</action>
    </update_conflict>
  </error_handling>
</nats_operation>
```

### File Injection Pattern

```xml
<file_injection_operation name="multi_source_state_update">
  <operation_type>update_with_injection</operation_type>
  <target>
    <bucket>agent-os-peer-state</bucket>
    <key source="STATE_KEY">Target state key</key>
  </target>
  
  <data_sources>
    <file_source variable="expr_out" path="/tmp/express_output.json">
      <validation>verify_json_syntax</validation>
      <access_pattern>slurp_as_array</access_pattern>
      <reference_format>$expr_out[0]</reference_format>
    </file_source>
    <file_source variable="cycle_res" path="/tmp/cycle_result.json">
      <validation>verify_json_syntax</validation>
      <access_pattern>slurp_as_array</access_pattern>
      <reference_format>$cycle_res[0]</reference_format>
    </file_source>
  </data_sources>
  
  <transformation>
    <filter source="JQ_FILTER_WITH_VARIABLES">
      JQ filter that references injected variables
    </filter>
  </transformation>
  
  <file_validation>
    <pre_injection>
      <rule>all files must exist</rule>
      <rule>all files must be readable</rule>
      <rule>all files must contain valid JSON</rule>
      <rule>variable names must be valid identifiers</rule>
    </pre_injection>
  </file_validation>
  
  <cleanup>
    <temporary_files>remove_after_successful_update</temporary_files>
    <on_error>preserve_files_for_debugging</on_error>
  </cleanup>
</file_injection_operation>
```

## Agent Implementation Requirements

### PEER Agent Responsibilities

```xml
<nats_operation_requirements>
  <reading_specifications>
    <requirement>parse XML NATS operation patterns</requirement>
    <requirement>identify operation type and parameters</requirement>
    <requirement>understand validation requirements</requirement>
    <requirement>extract error handling rules</requirement>
  </reading_specifications>
  
  <operation_execution>
    <requirement>use wrapper scripts for all NATS operations</requirement>
    <requirement>validate data before and after operations</requirement>
    <requirement>handle errors according to declared patterns</requirement>
    <requirement>log operations for debugging purposes</requirement>
  </operation_execution>
  
  <data_integrity>
    <requirement>ensure JSON validity before NATS updates</requirement>
    <requirement>preserve existing data during transformations</requirement>
    <requirement>validate schema compliance</requirement>
    <requirement>handle concurrent access appropriately</requirement>
  </data_integrity>
</nats_operation_requirements>
```

### Wrapper Script Usage Pattern

```xml
<wrapper_script_integration>
  <script_location>~/.agent-os/scripts/peer/</script_location>
  <usage_pattern>
    <read_operation>
      <script>read-state.sh</script>
      <parameters>
        <parameter name="STATE_KEY" source="cycle_context">NATS KV key to read</parameter>
      </parameters>
      <output>valid JSON to stdout</output>
      <error_handling>exit codes and stderr messages</error_handling>
    </read_operation>
    
    <update_operation>
      <script>update-state.sh</script>
      <parameters>
        <parameter name="STATE_KEY" source="cycle_context">NATS KV key to update</parameter>
        <parameter name="JQ_FILTER" source="transformation_spec">JSON transformation filter</parameter>
        <parameter name="file_injections" optional="true">Additional data files</parameter>
      </parameters>
      <output>success confirmation or error details</output>
      <error_handling>preserve state on failure</error_handling>
    </update_operation>
  </usage_pattern>
</wrapper_script_integration>
```

### Error Recovery Patterns

```xml
<error_recovery_strategies>
  <nats_connectivity>
    <detection_pattern>connection timeout or authentication failure</detection_pattern>
    <recovery_actions>
      <action>verify NATS server status</action>
      <action>check network connectivity</action>
      <action>validate credentials if applicable</action>
      <action>suggest manual NATS server restart</action>
    </recovery_actions>
  </nats_connectivity>
  
  <data_corruption>
    <detection_pattern>invalid JSON in NATS KV</detection_pattern>
    <recovery_actions>
      <action>log corrupted data for analysis</action>
      <action>prevent further corruption</action>
      <action>suggest manual recovery from backup</action>
      <action>document corruption circumstances</action>
    </recovery_actions>
  </data_corruption>
  
  <concurrent_updates>
    <detection_pattern>revision mismatch during update</detection_pattern>
    <recovery_actions>
      <action>re-read current state</action>
      <action>re-apply transformation</action>
      <action>retry update with new revision</action>
      <action>fail after maximum retries</action>
    </recovery_actions>
  </concurrent_updates>
</error_recovery_strategies>
```

## Implementation Guidelines

### Installation Requirements

```xml
<installation_pattern>
  <script_deployment>
    <source>Agent OS setup process</source>
    <destination>~/.agent-os/scripts/peer/</destination>
    <permissions>executable by user</permissions>
    <validation>verify scripts work with local NATS</validation>
  </script_deployment>
  
  <agent_configuration>
    <requirement>agents reference installed script location</requirement>
    <requirement>no local script copies or modifications</requirement>
    <requirement>consistent script usage across all agents</requirement>
  </agent_configuration>
</installation_pattern>
```

### Validation Standards

```xml
<validation_standards>
  <json_requirements>
    <rule>all JSON must parse without errors</rule>
    <rule>JSON must conform to unified state schema</rule>
    <rule>required fields must be present</rule>
    <rule>data types must match specifications</rule>
  </json_requirements>
  
  <operation_requirements>
    <rule>validate inputs before NATS operations</rule>
    <rule>validate outputs after transformations</rule>
    <rule>preserve data integrity during updates</rule>
    <rule>handle errors gracefully with clear messages</rule>
  </operation_requirements>
</validation_standards>
```

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

## Key Principles

### Declarative Operations Focus

```xml
<operational_principles>
  <consistency>
    <principle>all agents use identical NATS operation patterns</principle>
    <principle>wrapper scripts provide uniform interface</principle>
    <principle>error handling follows consistent patterns</principle>
  </consistency>
  
  <reliability>
    <principle>validation occurs before all operations</principle>
    <principle>data integrity preserved through structured approaches</principle>
    <principle>clear error messages enable effective debugging</principle>
  </reliability>
  
  <maintainability>
    <principle>XML patterns easier to understand than script logic</principle>
    <principle>declarative specifications reduce implementation brittleness</principle>
    <principle>centralized wrapper scripts minimize duplication</principle>
  </maintainability>
</operational_principles>
```

### Migration Success Criteria

```xml
<migration_outcomes>
  <functionality>
    <outcome>all PEER agents perform NATS operations consistently</outcome>
    <outcome>data integrity maintained through validation patterns</outcome>
    <outcome>error handling provides clear debugging information</outcome>
  </functionality>
  
  <reliability>
    <outcome>reduced script dependencies in agent implementations</outcome>
    <outcome>consistent operation patterns across all PEER phases</outcome>
    <outcome>improved error recovery through structured approaches</outcome>
  </reliability>
  
  <maintainability>
    <outcome>XML specifications easier to modify than script code</outcome>
    <outcome>declarative patterns reduce maintenance overhead</outcome>
    <outcome>centralized wrapper scripts simplify updates</outcome>
  </maintainability>
</migration_outcomes>
```