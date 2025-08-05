---
description: PEER Pattern Orchestration for Agent OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# PEER Pattern Execution

## Overview

Orchestrate any Agent OS instruction through the PEER (Plan, Execute, Express, Review) pattern for improved task decomposition, execution quality, and output consistency.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
  
  ### Pre-flight Check

<nats_check>
  ACTION: Verify NATS server availability
  COMMAND: nats kv ls
  ERROR_HANDLING:
    IF command fails:
      DISPLAY: "❌ NATS server is not available"
      PROVIDE: "Please ensure NATS server is running before using /peer"
      STOP execution
</nats_check>

<bucket_check>
  ACTION: Verify agent-os-peer-state bucket exists with correct configuration
  
  STEP 1: Check if bucket exists
  USE Bash tool:
    ```bash
    # Check if bucket exists
    if nats kv info agent-os-peer-state > /tmp/bucket_info.txt 2>&1; then
      echo "Bucket exists, checking configuration..."
    else
      echo "Bucket does not exist, creating..."
      # Create bucket with required configuration
      nats kv add agent-os-peer-state --replicas=3 --history=50 --description="PEER pattern state storage for Agent OS"
      if [ $? -eq 0 ]; then
        echo "✅ Successfully created agent-os-peer-state bucket"
      else
        echo "❌ Failed to create bucket"
        exit 1
      fi
    fi
    ```
  
  STEP 2: Verify bucket configuration
  USE Bash tool:
    ```bash
    # If bucket exists, verify configuration
    if [ -f /tmp/bucket_info.txt ]; then
      # Extract replicas and history from info
      replicas=$(grep "Replicas:" /tmp/bucket_info.txt | awk '{print $2}')
      history=$(grep "History:" /tmp/bucket_info.txt | awk '{print $2}')
      
      # Check if configuration matches requirements
      if [ "$replicas" != "3" ] || [ "$history" != "50" ]; then
        echo "⚠️  Warning: Bucket configuration mismatch"
        echo "   Current: replicas=$replicas, history=$history"
        echo "   Required: replicas=3, history=50"
        echo "   Note: Cannot modify existing bucket configuration"
        echo "   To fix: Delete and recreate the bucket (will lose existing data)"
      else
        echo "✅ Bucket configuration verified: replicas=3, history=50"
      fi
    fi
    ```
    
  ERROR_HANDLING:
    IF NATS not available:
      DISPLAY: "❌ Cannot connect to NATS server"
      STOP execution
    IF bucket creation fails:
      DISPLAY: "❌ Failed to create KV bucket. Check NATS server permissions"
      STOP execution
</bucket_check>

<argument_parsing>
  PARSE command arguments:
    - --instruction=<name>: The instruction to execute
    - --continue: Resume from last incomplete phase
    - --spec=<name>: Explicitly specify spec (optional)
  
  VALIDATE:
    IF neither --instruction nor --continue provided:
      ERROR: "Must provide either --instruction or --continue"
    IF both --instruction and --continue provided:
      ERROR: "Cannot use both --instruction and --continue"
</argument_parsing>

</pre_flight_check>

<process_flow>

<step number="1" name="context_determination">

### Step 1: Determine Execution Context

<instruction_classification>
  DEFINE spec-aware instructions: ["execute-tasks", "create-spec"]
  DEFINE non-spec instructions: ["analyze-product", "plan-product"]
  
  DETERMINE if {instruction_name} is spec-aware
</instruction_classification>

<spec_context>
  IF instruction is spec-aware:
    IF --spec provided:
      VALIDATE spec folder exists in .agent-os/specs/
      USE provided spec name
    ELSE IF instruction == "execute-tasks":
      FIND latest spec directory by date prefix
      USE latest spec found
      IF no spec found:
        ERROR: "No spec found. Please create a spec first or specify with --spec"
    ELSE IF instruction == "create-spec":
      IF --spec provided:
        CHECK if spec already exists for resuming
      ELSE:
        PROCEED without spec (will be created during execution)
    
    IF spec determined:
      STORE spec_name
      CONSTRUCT key prefix: peer.spec.<spec-name>
  ELSE:
    # Non-spec instruction
    STORE instruction_name
    CONSTRUCT key prefix: peer.instruction.<instruction-name>
</spec_context>

</step>

<step number="2" name="execution_mode">

### Step 2: Determine Execution Mode

<new_execution>
  IF --instruction provided:
    CHECK for existing cycles using Bash tool:
      ```bash
      # Check for existing meta
      if nats kv get agent-os-peer-state "${key_prefix}.meta" --raw > /tmp/existing_meta.json 2>/dev/null; then
        # Meta exists, extract current cycle number
        current_cycle=$(jq -r '.current_cycle' /tmp/existing_meta.json)
        new_cycle=$((current_cycle + 1))
        echo "Found existing meta, starting cycle $new_cycle"
      else
        # No meta exists, start with cycle 1
        new_cycle=1
        echo "No existing meta, starting cycle 1"
      fi
      ```
      
    CREATE or UPDATE meta entry using Bash tool:
      ```bash
      # Create timestamp
      timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      
      # Create/update meta JSON
      if [ -f /tmp/existing_meta.json ]; then
        # Update existing meta
        jq --arg cycle "$new_cycle" --arg inst "${instruction}" --arg ts "$timestamp" '
          .current_cycle = ($cycle | tonumber) |
          .current_phase = "plan" |
          .cycles[$cycle] = {
            "instruction": $inst,
            "status": "running",
            "started_at": $ts
          }
        ' /tmp/existing_meta.json > /tmp/updated_meta.json
      else
        # Create new meta
        cat > /tmp/updated_meta.json << EOF
      {
        "spec_name": "${spec_name}",
        "created_at": "$timestamp",
        "current_cycle": $new_cycle,
        "current_phase": "plan",
        "cycles": {
          "$new_cycle": {
            "instruction": "${instruction}",
            "status": "running",
            "started_at": "$timestamp"
          }
        }
      }
      EOF
      fi
      
      # Store meta
      cat /tmp/updated_meta.json | nats kv put agent-os-peer-state "${key_prefix}.meta"
      ```
      
    CREATE cycle entry using Bash tool:
      ```bash
      # Create cycle JSON
      cat > /tmp/new_cycle.json << EOF
      {
        "cycle_number": $new_cycle,
        "instruction": "${instruction}",
        "started_at": "$timestamp",
        "phases": {},
        "status": {
          "current_phase": "plan",
          "progress_percent": 0,
          "last_update": "$timestamp"
        }
      }
      EOF
      
      # Store cycle
      cat /tmp/new_cycle.json | nats kv put agent-os-peer-state "${key_prefix}.cycle.$new_cycle"
      ```
      
    STORE cycle_number=$new_cycle for use in subsequent phases
    PROCEED to planning_phase
</new_execution>

<continue_execution>
  IF --continue provided:
    DETECT and VALIDATE state using Bash tool:
      ```bash
      # Get meta data and validate state
      if nats kv get agent-os-peer-state "${key_prefix}.meta" --raw > /tmp/continue_meta.json 2>/dev/null; then
        # Extract current cycle and phase
        current_cycle=$(jq -r '.current_cycle' /tmp/continue_meta.json)
        current_phase=$(jq -r '.current_phase' /tmp/continue_meta.json)
        
        # Validate extracted values
        if [ -z "$current_cycle" ] || [ "$current_cycle" == "null" ]; then
          echo "❌ Invalid meta data: missing current_cycle"
          exit 1
        fi
        
        if [ -z "$current_phase" ] || [ "$current_phase" == "null" ]; then
          echo "❌ Invalid meta data: missing current_phase"
          exit 1
        fi
        
        echo "✅ Found valid state - Cycle: $current_cycle, Phase: $current_phase"
      else
        echo "❌ No previous execution found for this context"
        echo "   Use --instruction to start a new execution"
        exit 1
      fi
      ```
      
    RETRIEVE cycle data and validate using Bash tool:
      ```bash
      # Get current cycle data
      if nats kv get agent-os-peer-state "${key_prefix}.cycle.$current_cycle" --raw > /tmp/continue_cycle.json 2>/dev/null; then
        # Extract instruction and validate cycle integrity
        instruction=$(jq -r '.instruction' /tmp/continue_cycle.json)
        cycle_status=$(jq -r '.status.current_phase' /tmp/continue_cycle.json)
        
        # Validate instruction
        if [ -z "$instruction" ] || [ "$instruction" == "null" ]; then
          echo "❌ Invalid cycle data: missing instruction"
          exit 1
        fi
        
        # Check for phase mismatch
        if [ "$cycle_status" != "$current_phase" ] && [ "$current_phase" != "complete" ]; then
          echo "⚠️  Warning: Phase mismatch detected"
          echo "   Meta phase: $current_phase"
          echo "   Cycle phase: $cycle_status"
          echo "   Using meta phase for continuation"
        fi
        
        echo "✅ Resuming instruction: $instruction"
        
        # Extract any existing phase outputs for context
        if [ "$current_phase" != "plan" ]; then
          echo "📋 Previous phase outputs available:"
          jq -r 'keys(.phases) | @csv' /tmp/continue_cycle.json | tr ',' '\n' | sed 's/"//g' | while read phase; do
            if [ -n "$phase" ]; then
              echo "   - $phase: completed"
            fi
          done
        fi
      else
        echo "❌ Cycle data not found for cycle $current_cycle"
        echo "   State may be corrupted - cannot continue"
        exit 1
      fi
      ```
      
    DETERMINE next phase with validation:
      ```bash
      # Determine and validate next phase
      case "$current_phase" in
        "plan")
          next_phase="execution_phase"
          echo "➡️  Next: Execute phase"
          ;;
        "execute")
          next_phase="express_phase"
          echo "➡️  Next: Express phase"
          ;;
        "express")
          next_phase="review_phase"
          echo "➡️  Next: Review phase"
          ;;
        "complete")
          echo "❌ This cycle is already complete"
          echo "   Use --instruction to start a new cycle"
          exit 1
          ;;
        "error")
          # Extract error details
          error_phase=$(jq -r '.status.error_phase // "unknown"' /tmp/continue_cycle.json)
          error_message=$(jq -r '.status.error_message // "No details available"' /tmp/continue_cycle.json)
          echo "❌ Previous phase failed, cannot continue"
          echo "   Failed phase: $error_phase"
          echo "   Error: $error_message"
          echo "   Fix the issue and retry or start a new cycle"
          exit 1
          ;;
        *)
          echo "❌ Unknown phase: $current_phase"
          echo "   Valid phases: plan, execute, express, review, complete"
          exit 1
          ;;
      esac
      ```
      
    STORE continuation context for use in phases:
      - is_continuation=true
      - continuation_phase=$next_phase
      - previous_outputs_available=true
      
    CHECK for partial phase completion using Bash tool:
      ```bash
      # Check if current phase has partial output
      partial_output=$(jq -r ".phases.${current_phase}.output // empty" /tmp/continue_cycle.json)
      partial_status=$(jq -r ".phases.${current_phase}.status // empty" /tmp/continue_cycle.json)
      
      if [ -n "$partial_output" ] && [ "$partial_output" != "null" ] && [ "$partial_status" != "complete" ]; then
        echo "⚠️  Detected partial completion in $current_phase phase"
        echo "   Status: $partial_status"
        echo "   The phase will need to handle existing partial work"
        
        # Save partial info for phase to use
        echo "$partial_output" > /tmp/partial_${current_phase}_output.json
      fi
      ```
</continue_execution>

</step>

<step number="3" subagent="peer-planner" name="planning_phase">

### Step 3: Planning Phase

<phase_check>
  IF continuing AND current_phase != "plan":
    SKIP to next phase
  ELSE IF continuing AND current_phase == "plan":
    # Plan phase is complete, need to resume from execute
    LOAD previous plan output from cycle data:
      ```bash
      # Extract plan output for continuation context
      jq -r '.phases.plan.output' /tmp/continue_cycle.json > /tmp/plan_output.json
      if [ -s /tmp/plan_output.json ] && [ "$(cat /tmp/plan_output.json)" != "null" ]; then
        echo "✅ Previous plan output loaded for continuation"
      else
        echo "⚠️  Warning: No plan output found, executor will run without plan context"
      fi
      ```
    PROCEED directly to execution_phase
</phase_check>

<invoke_planner>
  USE Task tool to invoke peer-planner with:
    - context_type: {spec-aware ? "spec" : "instruction"}
    - context_value: {spec_name OR instruction_name}
    - cycle_number: {current_cycle}
    - instruction: {instruction_name}
    - kv_bucket: agent-os-peer-state
    - meta_key: {key_prefix}.meta
    - cycle_key: {key_prefix}.cycle.{cycle_number}
    - is_continuation: {is_continuation // false}
</invoke_planner>

<update_phase>
  UPDATE meta current_phase to "execute" using Bash tool:
    ```bash
    # Get current meta
    nats kv get agent-os-peer-state "${key_prefix}.meta" --raw > /tmp/phase_meta.json
    
    # Update phase
    jq '.current_phase = "execute"' /tmp/phase_meta.json > /tmp/phase_meta_updated.json
    
    # Store updated meta
    cat /tmp/phase_meta_updated.json | nats kv put agent-os-peer-state "${key_prefix}.meta"
    echo "✅ Updated phase to: execute"
    ```
</update_phase>

</step>

<step number="4" subagent="peer-executor" name="execution_phase">

### Step 4: Execution Phase

<phase_check>
  IF continuing AND current_phase not in ["plan", "execute"]:
    SKIP to next phase
  ELSE IF continuing AND current_phase == "execute":
    # Execute phase needs to resume
    LOAD previous outputs for context:
      ```bash
      # Extract all previous phase outputs
      jq -r '.phases.plan.output // empty' /tmp/continue_cycle.json > /tmp/plan_output.json
      jq -r '.phases.execute.output // empty' /tmp/continue_cycle.json > /tmp/partial_execution.json
      
      # Check what's available
      if [ -s /tmp/plan_output.json ] && [ "$(cat /tmp/plan_output.json)" != "null" ]; then
        echo "✅ Plan output available for executor"
      fi
      
      if [ -s /tmp/partial_execution.json ] && [ "$(cat /tmp/partial_execution.json)" != "null" ]; then
        echo "⚠️  Partial execution found - executor should check for incomplete tasks"
      fi
      ```
    CONTINUE with execution (executor will handle partial state)
</phase_check>

<invoke_executor>
  USE Task tool to invoke peer-executor with:
    - spec_context: {spec_name}
    - cycle_number: {current_cycle}
    - instruction: {instruction_name}
    - kv_bucket: agent-os-peer-state
    - meta_key: {key_prefix}.meta
    - cycle_key: {key_prefix}.cycle.{cycle_number}
    - plan_output: {from /tmp/plan_output.json if continuing, otherwise from planning phase}
    - is_continuation: {is_continuation // false}
    - partial_execution: {from /tmp/partial_execution.json if exists}
</invoke_executor>

<update_phase>
  UPDATE meta current_phase to "express" using Bash tool:
    ```bash
    # Get current meta
    nats kv get agent-os-peer-state "${key_prefix}.meta" --raw > /tmp/phase_meta.json
    
    # Update phase
    jq '.current_phase = "express"' /tmp/phase_meta.json > /tmp/phase_meta_updated.json
    
    # Store updated meta
    cat /tmp/phase_meta_updated.json | nats kv put agent-os-peer-state "${key_prefix}.meta"
    echo "✅ Updated phase to: express"
    ```
</update_phase>

</step>

<step number="5" subagent="peer-express" name="express_phase">

### Step 5: Express Phase

<phase_check>
  IF continuing AND current_phase not in ["plan", "execute", "express"]:
    SKIP to next phase
  ELSE IF continuing AND current_phase == "express":
    # Express phase needs outputs from previous phases
    LOAD all previous outputs:
      ```bash
      # Extract all completed phase outputs
      jq -r '.phases.plan.output // empty' /tmp/continue_cycle.json > /tmp/plan_output.json
      jq -r '.phases.execute.output // empty' /tmp/continue_cycle.json > /tmp/execution_output.json
      
      # Validate required outputs exist
      if [ ! -s /tmp/execution_output.json ] || [ "$(cat /tmp/execution_output.json)" == "null" ]; then
        echo "❌ Cannot express without execution output"
        echo "   The execution phase must be completed first"
        exit 1
      fi
      
      echo "✅ Previous outputs loaded for express phase"
      ```
    CONTINUE with express phase
</phase_check>

<invoke_express>
  USE Task tool to invoke peer-express with:
    - spec_context: {spec_name}
    - cycle_number: {current_cycle}
    - kv_bucket: agent-os-peer-state
    - meta_key: {key_prefix}.meta
    - cycle_key: {key_prefix}.cycle.{cycle_number}
    - plan_output: {from /tmp/plan_output.json if continuing}
    - execution_output: {from /tmp/execution_output.json if continuing, otherwise from execution phase}
    - is_continuation: {is_continuation // false}
</invoke_express>

<update_phase>
  UPDATE meta current_phase to "review" using Bash tool:
    ```bash
    # Get current meta
    nats kv get agent-os-peer-state "${key_prefix}.meta" --raw > /tmp/phase_meta.json
    
    # Update phase
    jq '.current_phase = "review"' /tmp/phase_meta.json > /tmp/phase_meta_updated.json
    
    # Store updated meta
    cat /tmp/phase_meta_updated.json | nats kv put agent-os-peer-state "${key_prefix}.meta"
    echo "✅ Updated phase to: review"
    ```
</update_phase>

</step>

<step number="6" subagent="peer-review" name="review_phase">

### Step 6: Review Phase

<phase_check>
  IF continuing AND current_phase == "complete":
    ERROR: "This cycle is already complete"
  ELSE IF continuing AND current_phase == "review":
    # Review phase needs all outputs
    LOAD all phase outputs:
      ```bash
      # Extract all phase outputs for review
      jq -r '.phases.plan.output // empty' /tmp/continue_cycle.json > /tmp/plan_output.json
      jq -r '.phases.execute.output // empty' /tmp/continue_cycle.json > /tmp/execution_output.json
      jq -r '.phases.express.output // empty' /tmp/continue_cycle.json > /tmp/express_output.json
      
      # Validate all required outputs
      missing_phases=""
      if [ ! -s /tmp/plan_output.json ] || [ "$(cat /tmp/plan_output.json)" == "null" ]; then
        missing_phases="${missing_phases}plan "
      fi
      if [ ! -s /tmp/execution_output.json ] || [ "$(cat /tmp/execution_output.json)" == "null" ]; then
        missing_phases="${missing_phases}execute "
      fi
      if [ ! -s /tmp/express_output.json ] || [ "$(cat /tmp/express_output.json)" == "null" ]; then
        missing_phases="${missing_phases}express "
      fi
      
      if [ -n "$missing_phases" ]; then
        echo "❌ Cannot review - missing outputs from: $missing_phases"
        echo "   All phases must complete before review"
        exit 1
      fi
      
      echo "✅ All phase outputs loaded for review"
      ```
    CONTINUE with review phase
</phase_check>

<invoke_review>
  USE Task tool to invoke peer-review with:
    - spec_context: {spec_name}
    - cycle_number: {current_cycle}
    - kv_bucket: agent-os-peer-state
    - meta_key: {key_prefix}.meta
    - cycle_key: {key_prefix}.cycle.{cycle_number}
    - plan_output: {from /tmp/plan_output.json if continuing}
    - execution_output: {from /tmp/execution_output.json if continuing}
    - express_output: {from /tmp/express_output.json if continuing}
    - is_continuation: {is_continuation // false}
</invoke_review>

<finalize_cycle>
  UPDATE meta and cycle to complete using Bash tool:
    ```bash
    # Get current meta
    nats kv get agent-os-peer-state "${key_prefix}.meta" --raw > /tmp/final_meta.json
    
    # Update meta with completion
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg cycle "$current_cycle" --arg ts "$timestamp" '
      .current_phase = "complete" |
      .cycles[$cycle].status = "complete" |
      .cycles[$cycle].completed_at = $ts
    ' /tmp/final_meta.json > /tmp/final_meta_updated.json
    
    # Store updated meta
    cat /tmp/final_meta_updated.json | nats kv put agent-os-peer-state "${key_prefix}.meta"
    
    # Update cycle with completion
    nats kv get agent-os-peer-state "${key_prefix}.cycle.$current_cycle" --raw > /tmp/final_cycle.json
    
    jq --arg ts "$timestamp" '
      .completed_at = $ts |
      .status.current_phase = "complete" |
      .status.progress_percent = 100
    ' /tmp/final_cycle.json > /tmp/final_cycle_updated.json
    
    # Store updated cycle
    cat /tmp/final_cycle_updated.json | nats kv put agent-os-peer-state "${key_prefix}.cycle.$current_cycle"
    
    echo "✅ PEER cycle $current_cycle completed successfully"
    ```
</finalize_cycle>

</step>

<step number="7" name="completion_summary">

### Step 7: Completion Summary

<display_summary>
  ✨ PEER Cycle Complete!
  - Context: {spec_name OR instruction_name}
  - Instruction: {instruction_name}
  - Cycle: {cycle_number}
  - Quality Score: {from review phase}
  
  To view full results:
  nats kv get agent-os-peer-state {key_prefix}.cycle.{cycle_number} --raw | jq
</display_summary>

</step>

</process_flow>

## Error Handling

<error_patterns>
  <nats_errors>
    - Connection refused: NATS server not running
    - Bucket not found: Create bucket with setup command
    - Key not found: Normal for first execution
  </nats_errors>
  
  <phase_errors>
    - Agent invocation fails: Store error in cycle, mark phase failed
    - JSON parsing fails: Use fallback or request user assistance
    - State corruption: Provide recovery instructions
  </phase_errors>
</error_patterns>

## Helper Functions

<json_helpers>
  DEFINE helper functions for JSON operations using Bash tool:
  
  ### Create timestamp helper
  ```bash
  # Helper function to create ISO 8601 timestamp
  create_timestamp() {
    date -u +%Y-%m-%dT%H:%M:%SZ
  }
  ```
  
  ### Safe JSON string escape helper
  ```bash
  # Helper to escape strings for JSON
  escape_json_string() {
    local string="$1"
    # Escape backslashes, quotes, newlines, tabs
    echo "$string" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\t/\\t/g'
  }
  ```
  
  ### JSON merge helper
  ```bash
  # Helper to merge JSON objects
  merge_json() {
    local base_file="$1"
    local updates_file="$2"
    jq -s '.[0] * .[1]' "$base_file" "$updates_file"
  }
  ```
  
  ### Extract nested value helper
  ```bash
  # Helper to safely extract nested JSON values
  get_json_value() {
    local file="$1"
    local path="$2"
    local default="${3:-}"
    
    value=$(jq -r "$path // empty" "$file" 2>/dev/null)
    echo "${value:-$default}"
  }
  ```
  
  ### Create JSON from template helper
  ```bash
  # Helper to create JSON from template with variable substitution
  create_json_from_template() {
    local template="$1"
    # Use envsubst or sed for variable substitution
    echo "$template" | envsubst
  }
  ```
</json_helpers>

## JSON Templates

<meta_template>
{
  "spec_name": "${spec_name}",
  "created_at": "${timestamp}",
  "current_cycle": ${cycle_number},
  "current_phase": "${phase}",
  "cycles": {
    "${cycle_number}": {
      "instruction": "${instruction}",
      "status": "${status}",
      "started_at": "${timestamp}"
    }
  }
}
</meta_template>

<cycle_template>
{
  "cycle_number": ${cycle_number},
  "instruction": "${instruction}",
  "started_at": "${timestamp}",
  "phases": {},
  "status": {
    "current_phase": "${phase}",
    "progress_percent": ${percent}
  }
}
</cycle_template>

## Usage Examples

<new_execution>
# Instructions that don't use spec context
/peer --instruction=analyze-product
/peer --instruction=plan-product

# Instructions that use spec context
/peer --instruction=execute-tasks
/peer --instruction=execute-tasks --spec=user-auth

# create-spec can work both ways
/peer --instruction=create-spec
/peer --instruction=create-spec --spec=existing-spec-name
</new_execution>

<continue_execution>
# Continue any instruction
/peer --continue

# For spec-aware instructions, can specify which spec
/peer --continue --spec=user-auth
</continue_execution>

## Testing State Persistence

<test_commands>
  ### Test bucket creation and configuration
  USE Bash tool:
    ```bash
    # Test bucket info
    echo "=== Testing NATS KV Bucket ==="
    nats kv info agent-os-peer-state
    
    # List all keys in bucket
    echo -e "\n=== Current Keys in Bucket ==="
    nats kv ls agent-os-peer-state
    ```
  
  ### Test meta key operations
  USE Bash tool:
    ```bash
    # Create test meta
    test_spec="test-spec-$(date +%s)"
    test_meta='{
      "spec_name": "'$test_spec'",
      "created_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "current_cycle": 1,
      "current_phase": "plan",
      "cycles": {
        "1": {
          "instruction": "test-instruction",
          "status": "running",
          "started_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }
      }
    }'
    
    # Store test meta
    echo "$test_meta" | nats kv put agent-os-peer-state "peer.spec.$test_spec.meta"
    
    # Retrieve and verify
    echo -e "\n=== Retrieving Test Meta ==="
    nats kv get agent-os-peer-state "peer.spec.$test_spec.meta" --raw | jq '.'
    
    # Clean up test data
    echo -e "\n=== Cleaning Up Test Data ==="
    nats kv del agent-os-peer-state "peer.spec.$test_spec.meta"
    ```
  
  ### Test cycle operations
  USE Bash tool:
    ```bash
    # Create test cycle
    test_cycle='{
      "cycle_number": 1,
      "instruction": "test-instruction",
      "started_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "phases": {
        "plan": {
          "status": "complete",
          "output": {
            "steps": ["Step 1", "Step 2"],
            "estimated_duration": "30 minutes"
          }
        }
      },
      "status": {
        "current_phase": "execute",
        "progress_percent": 25
      }
    }'
    
    # Store test cycle
    echo "$test_cycle" | nats kv put agent-os-peer-state "peer.spec.$test_spec.cycle.1"
    
    # Retrieve and verify
    echo -e "\n=== Retrieving Test Cycle ==="
    nats kv get agent-os-peer-state "peer.spec.$test_spec.cycle.1" --raw | jq '.'
    
    # Update cycle with new phase
    echo -e "\n=== Updating Cycle Phase ==="
    nats kv get agent-os-peer-state "peer.spec.$test_spec.cycle.1" --raw > /tmp/test_cycle.json
    
    jq '.phases.execute = {
      "status": "complete",
      "output": {
        "files_created": ["file1.md", "file2.md"],
        "execution_time": "15 minutes"
      }
    } | .status.current_phase = "express" | .status.progress_percent = 50' /tmp/test_cycle.json > /tmp/test_cycle_updated.json
    
    cat /tmp/test_cycle_updated.json | nats kv put agent-os-peer-state "peer.spec.$test_spec.cycle.1"
    
    # Verify update
    echo -e "\n=== Verifying Update ==="
    nats kv get agent-os-peer-state "peer.spec.$test_spec.cycle.1" --raw | jq '.phases'
    
    # Clean up
    nats kv del agent-os-peer-state "peer.spec.$test_spec.cycle.1"
    echo "✅ Test completed successfully"
    ```
  
  ### Test error handling
  USE Bash tool:
    ```bash
    # Test non-existent key
    echo "=== Testing Error Handling ==="
    if nats kv get agent-os-peer-state "peer.spec.non-existent.meta" --raw 2>/dev/null; then
      echo "❌ Should have failed for non-existent key"
    else
      echo "✅ Correctly handled non-existent key"
    fi
    
    # Test invalid JSON
    echo -e "\n=== Testing Invalid JSON Handling ==="
    echo "invalid json" | nats kv put agent-os-peer-state "peer.spec.test-invalid.meta" 2>/dev/null || true
    
    if nats kv get agent-os-peer-state "peer.spec.test-invalid.meta" --raw 2>/dev/null | jq '.' 2>/dev/null; then
      echo "❌ Should have failed to parse invalid JSON"
    else
      echo "✅ Correctly handled invalid JSON"
    fi
    
    # Clean up
    nats kv del agent-os-peer-state "peer.spec.test-invalid.meta" 2>/dev/null || true
    ```
</test_commands>
