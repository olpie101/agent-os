---
description: PEER Pattern Process Coordination for Agent OS
globs:
alwaysApply: false
version: 2.0
encoding: UTF-8
---

# PEER Pattern Execution

## Overview

Orchestrate any Agent OS instruction through the PEER (Plan, Execute, Express, Review) pattern for improved task decomposition, execution quality, and output consistency using process-based coordination.

BEFORE BEGINING YOU MUST ECHO THE VERSION NUMBER AT THE TOP OF THE FILE CONCATONATED WITH "-peer-coordinator"

## Unified State Schema

This instruction uses the unified state schema defined in @~/.agent-os/instructions/meta/unified_state_schema.md for all state management. All PEER phases work with a single state object per cycle stored at `[KEY_PREFIX].cycle.[CYCLE_NUMBER]`.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" name="nats_availability_check">

### Step 1: NATS Server Availability Check

Verify NATS server is available before proceeding with PEER pattern execution.

<validation_logic>
  CHECK: NATS server connectivity
  IF server not responding:
    ERROR: "❌ NATS server is not available"
    PROVIDE: "Please ensure NATS server is running before using /peer"
    STOP execution
  ELSE:
    PROCEED to next step
</validation_logic>

<nats_health_command>
  nats kv ls --timeout=5s
</nats_health_command>

<instructions>
  ACTION: Verify NATS server availability
  VALIDATION: Ensure KV operations are accessible
  ERROR_HANDLING: Stop execution if server unavailable
</instructions>

</step>

<step number="2" name="kv_bucket_verification">

### Step 2: KV Bucket Verification

Ensure the agent-os-peer-state bucket exists with correct configuration for PEER state management.

<bucket_check_logic>
  CHECK: Bucket existence and configuration
  IF bucket does not exist:
    ACTION: Create bucket with required configuration
    IF creation fails:
      ERROR: "❌ Failed to create KV bucket. Check NATS server permissions"
      STOP execution
  ELSE IF configuration mismatch:
    WARN: "⚠️ Bucket configuration differs from requirements"
    PROVIDE: "Current config may affect reliability"
    PROCEED with warning
</bucket_check_logic>

<bucket_configuration>
  nats kv add agent-os-peer-state --replicas=3 --history=50 --description="PEER pattern state storage for Agent OS"
</bucket_configuration>

<instructions>
  ACTION: Verify or create NATS KV bucket
  VALIDATE: Bucket exists with proper configuration
  HANDLE: Creation failures and config mismatches
</instructions>

</step>

<step number="3" name="argument_parsing">

### Step 3: Parse and Validate Arguments

Parse command arguments to determine execution mode and validate required parameters.

<argument_validation>
  <required_parameters>
    - --instruction=<name> OR --continue (mutually exclusive)
    - --spec=<name> (optional)
  </required_parameters>
  
  <validation_logic>
    IF neither --instruction nor --continue provided:
      ERROR: "Must provide either --instruction or --continue"
      DISPLAY: "Usage: /peer --instruction=<name> [--spec=<name>]"
      DISPLAY: "   or: /peer --continue"
      STOP execution
    IF both --instruction and --continue provided:
      ERROR: "Cannot use both --instruction and --continue"
      STOP execution
  </validation_logic>
</argument_validation>

<context_variables>
  - PEER_MODE: "new" or "continue"
  - INSTRUCTION_NAME: from --instruction flag
  - SPEC_NAME: from --spec flag (optional)
</context_variables>

<instructions>
  ACTION: Parse command line arguments
  VALIDATE: Ensure valid argument combination
  STORE: Execution mode and parameters for subsequent steps
</instructions>

</step>

<step number="4" name="execution_context_determination">

### Step 4: Determine Execution Context and Spec Name

Classify the instruction, determine spec name if needed, and establish key prefix.

<context_classification>
  <spec_aware_instructions>
    - create-spec
    - execute-tasks
    - analyze-product
    - refine-spec
  </spec_aware_instructions>
  
  <classification_logic>
    IF INSTRUCTION_NAME in spec_aware_instructions:
      SET: SPEC_AWARE = true
      IF SPEC_NAME not provided AND INSTRUCTION_NAME requires spec:
        ERROR: "Spec name required for [INSTRUCTION_NAME]"
        STOP execution
    ELSE:
      SET: SPEC_AWARE = false
  </classification_logic>
</context_classification>

<spec_name_determination>
  IF INSTRUCTION_NAME == "create-spec" AND SPEC_NAME not provided:
    ANALYZE: User requirements from initial input
    EXTRACT: 3-5 meaningful keywords
    REMOVE: Common words (the, a, an, is, are, and, or, for, to, of, in, on, at, by, with)
    FORMAT: Convert to kebab-case
    LIMIT: Maximum 5 words
    DEFAULT: "new-feature" if extraction fails
    SET: SPEC_NAME = determined spec name
  
  IF INSTRUCTION_NAME == "refine-spec":
    EXTRACT: Previous cycle's review recommendations if available
    FIND: Most recent completed cycle for same spec
    READ: Review output from phases.review.output.recommendations
    STORE: Recommendations in context for refine-spec use
</spec_name_determination>

<nats_key_prefix>
  IF SPEC_AWARE and SPEC_NAME provided:
    KEY_PREFIX: "peer.spec.[SPEC_NAME]"
  ELSE IF INSTRUCTION_NAME == "create-spec" and SPEC_NAME determined:
    KEY_PREFIX: "peer.spec.[SPEC_NAME]"
  ELSE:
    KEY_PREFIX: "peer.global"
</nats_key_prefix>

<instructions>
  ACTION: Determine instruction context
  CLASSIFY: As spec-aware or non-spec
  DETERMINE: Spec name for create-spec if not provided
  ESTABLISH: NATS key prefix for state management
</instructions>

</step>

<step number="5" name="cycle_initialization">

### Step 5: Initialize PEER Cycle

Create or determine the PEER cycle for this execution and set up initial state.

<cycle_logic>
  IF PEER_MODE is "continue":
    FIND: Last incomplete cycle from NATS KV
    IF found:
      LOAD: Unified state from [KEY_PREFIX].cycle.[CYCLE_NUMBER]
      RESUME: From last completed phase
    ELSE:
      ERROR: "No incomplete cycle found to continue"
      PROVIDE: "Start a new cycle with --instruction"
      STOP execution
  ELSE:
    DETERMINE: New cycle number using cycle number determination logic
    CREATE: New cycle with determined number
    INITIALIZE: Unified state object in NATS KV
</cycle_logic>

<cycle_number_determination>
  # Read current cycle from [KEY_PREFIX].cycle.current
  CURRENT_CYCLE_KEY="[KEY_PREFIX].cycle.current"
  CURRENT_CYCLE=$(~/.agent-os/scripts/peer/read-state.sh "$CURRENT_CYCLE_KEY" 2>/dev/null || echo "")
  
  # Handle first cycle (returns null/empty) case
  IF [ -z "$CURRENT_CYCLE" ] || [ "$CURRENT_CYCLE" = "null" ]; then
    NEW_CYCLE_NUMBER=1
  ELSE:
    # Increment cycle number correctly
    NEW_CYCLE_NUMBER=$((CURRENT_CYCLE + 1))
  fi
  
  # Add safety check to prevent duplicate cycle numbers
  TEST_CYCLE_KEY="[KEY_PREFIX].cycle.$NEW_CYCLE_NUMBER"
  EXISTING_STATE=$(~/.agent-os/scripts/peer/read-state.sh "$TEST_CYCLE_KEY" 2>/dev/null || echo "")
  IF [ -n "$EXISTING_STATE" ] && [ "$EXISTING_STATE" != "null" ]; then
    ERROR: "Cycle $NEW_CYCLE_NUMBER already exists. State may be corrupted."
    PROVIDE: "Please check NATS KV state manually"
    STOP execution
  fi
  
  CYCLE_NUMBER=$NEW_CYCLE_NUMBER
  
  # Store new cycle number in [KEY_PREFIX].cycle.current after creating the state
</cycle_number_determination>

<unified_state_initialization>
  CREATE unified state object (see @~/.agent-os/instructions/meta/unified_state_schema.md):
  {
    "version": 1,
    "cycle_id": "[KEY_PREFIX].cycle.[CYCLE_NUMBER]",
    "metadata": {
      "instruction_name": "[INSTRUCTION_NAME]",
      "spec_name": "[SPEC_NAME]",  // if applicable
      "key_prefix": "[KEY_PREFIX]",
      "cycle_number": [CYCLE_NUMBER],
      "created_at": "[ISO_TIMESTAMP]",
      "updated_at": "[ISO_TIMESTAMP]",
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
  
  STORE using: ~/.agent-os/scripts/peer/create-state.sh "[KEY_PREFIX].cycle.[CYCLE_NUMBER]" "{unified_state}"
  
  # Store new cycle number in [KEY_PREFIX].cycle.current
  ~/.agent-os/scripts/peer/create-state.sh "[KEY_PREFIX].cycle.current" "$CYCLE_NUMBER"
</unified_state_initialization>

<instructions>
  ACTION: Initialize or resume PEER cycle
  DETERMINE: New cycle or continuation
  STORE: Cycle metadata for phase coordination
  OUTPUT: Cycle number and initial status
</instructions>

</step>

<step number="6" name="spec_name_storage">

### Step 6: Store Spec Name in Metadata (Conditional)

For create-spec instructions, store the determined spec name in cycle metadata.

<conditional_execution>
  IF INSTRUCTION_NAME != "create-spec":
    SKIP this entire step
    PROCEED to step 7
</conditional_execution>

<storage_logic>
  # Spec name was already determined in Step 4
  # This step just ensures it's properly stored in the cycle metadata
  IF SPEC_NAME exists (from Step 4 determination or --spec flag):
    ENSURE: Spec name is included in unified state metadata
    UPDATE: Cycle context with spec name for downstream phases
</storage_logic>

<instructions>
  ACTION: Verify spec name is stored in cycle metadata
  ENSURE: Spec name available for all PEER phases
  PROCEED: To planning phase
</instructions>

</step>

<step number="7" subagent="peer-planner" name="planning_phase">

### Step 7: Planning Phase

Use the peer-planner subagent to decompose the instruction into manageable phases and create an execution plan.

<planning_context>
  INSTRUCTION: [INSTRUCTION_NAME]
  SPEC_NAME: [SPEC_NAME] (if applicable)
  CYCLE_NUMBER: [CYCLE_NUMBER]
  KEY_PREFIX: [KEY_PREFIX]
</planning_context>

<instructions>
  ACTION: Use peer-planner subagent
  REQUEST: "Execute planning phase
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            Read the unified state from NATS KV at STATE_KEY which contains:
            - All context and metadata
            - Instruction name, spec name, cycle number
            - User requirements and execution mode
            
            After planning:
            1. Read the current state from STATE_KEY
            2. Update phases.plan with your planning data:
               - Set status to 'completed'
               - Add output with plan details
               - Set completed_at timestamp
            3. Update metadata.status to 'PLANNING' when starting, 'EXECUTING' when done
            4. Update metadata.current_phase appropriately
            5. Write the updated state back to STATE_KEY
            
            The unified state follows the schema at @~/.agent-os/instructions/meta/unified_state_schema.md"
  WAIT: For planning completion
  VERIFY: State updated successfully with phases.plan.status = "completed"
</instructions>

</step>

<step number="8" subagent="peer-executor" name="execution_phase">

### Step 8: Execution Phase

Use the peer-executor subagent to execute the planned instruction using appropriate Agent OS patterns.

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
            
            The unified state at STATE_KEY contains:
            - The plan at phases.plan.output
            - All context and metadata
            
            Execute the instruction according to the plan, then:
            1. Read the current state from STATE_KEY
            2. Update phases.execute with your progress and results:
               - Set status to 'in_progress' when starting
               - Update output with progress, files created, etc.
               - Set status to 'completed' when done
               - Add completed_at timestamp
            3. Update metadata.status to 'EXECUTING'
            4. Update metadata.current_phase to 'execute'
            5. Write the updated state back to STATE_KEY
            
            The unified state follows the schema at @~/.agent-os/instructions/meta/unified_state_schema.md"
  WAIT: For execution completion
  VERIFY: phases.execute.status == "completed"
</instructions>

</step>

<step number="9" subagent="peer-express" name="express_phase">

### Step 9: Express Phase

Use the peer-express subagent to format and present the execution results professionally.

<phase_validation>
  READ: Unified state from [KEY_PREFIX].cycle.[CYCLE_NUMBER]
  CHECK: phases.execute.status == "completed"
  IF not completed:
    ERROR: "Cannot express without completed execution phase"
    STOP execution
</phase_validation>

<instructions>
  ACTION: Use peer-express subagent
  REQUEST: "Format execution results
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            The unified state at STATE_KEY contains:
            - Plan output at phases.plan.output
            - Execution results at phases.execute.output
            
            Create professional presentation, then:
            1. Read the current state from STATE_KEY
            2. Update phases.express with formatted output:
               - Set status to 'completed'
               - Add output with summary, achievements, deliverables
               - Add completed_at timestamp
            3. Update metadata.status to 'EXPRESSING'
            4. Update metadata.current_phase to 'express'
            5. Write the updated state back to STATE_KEY
            
            The unified state follows the schema at @~/.agent-os/instructions/meta/unified_state_schema.md"
  WAIT: For express completion
  PROCESS: Display formatted results to user
</instructions>

</step>

<step number="10" subagent="peer-review" name="review_phase">

### Step 10: Review Phase

Use the peer-review subagent to assess execution quality and provide improvement recommendations.

<review_context>
  CYCLE_NUMBER: [CYCLE_NUMBER]
  KEY_PREFIX: [KEY_PREFIX]
  INSTRUCTION: [INSTRUCTION_NAME]
  ALL_PHASES: Available in NATS KV under cycle prefix
</review_context>

<review_considerations>
  FOR create-spec: Focus on spec completeness and clarity
  FOR execute-tasks: Assess task completion and code quality
  FOR analyze-product: Evaluate analysis depth and insights
  DEFAULT: General quality and completeness review
</review_considerations>

<instructions>
  ACTION: Use peer-review subagent
  REQUEST: "Review PEER execution
            
            STATE_KEY: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
            
            The unified state at STATE_KEY contains all phase outputs:
            - Plan at phases.plan.output
            - Execution at phases.execute.output
            - Expression at phases.express.output
            
            Assess quality and provide recommendations, then:
            1. Read the current state from STATE_KEY
            2. Update phases.review with insights:
               - Set status to 'completed'
               - Add output with quality score, strengths, improvements
               - Add completed_at timestamp
            3. Update metadata.status to 'REVIEWING' then 'COMPLETED'
            4. Update metadata.current_phase to 'review'
            5. Write the updated state back to STATE_KEY
            
            The unified state follows the schema at @~/.agent-os/instructions/meta/unified_state_schema.md"
  WAIT: For review completion
  PROCESS: Share insights for continuous improvement
</instructions>

</step>

<step number="11" name="cycle_completion">

### Step 11: Finalize PEER Cycle

Complete the PEER cycle by updating final state and providing summary.

<completion_tasks>
  UPDATE: Cycle status to "completed"
  RECORD: Completion timestamp
  SUMMARIZE: Key outcomes from all phases
</completion_tasks>

<cycle_finalization>
  # Read current state using wrapper script
  STATE=$(~/.agent-os/scripts/peer/read-state.sh "[KEY_PREFIX].cycle.[CYCLE_NUMBER]")
  
  # Update state using wrapper script with JQ filter
  JQ_FILTER='
    .metadata.status = "COMPLETED" |
    .metadata.completed_at = (now | todate)
  '
  
  # Write updated state back using wrapper script
  ~/.agent-os/scripts/peer/update-state.sh "[KEY_PREFIX].cycle.[CYCLE_NUMBER]" "$JQ_FILTER"
</cycle_finalization>

<final_summary>
  ## PEER Cycle [CYCLE_NUMBER] Complete

  **Instruction:** [INSTRUCTION_NAME]
  **Spec:** [SPEC_NAME] (if applicable)
  
  ✅ Planning phase completed
  ✅ Execution phase completed
  ✅ Express phase completed
  ✅ Review phase completed
  
  All outputs stored in NATS KV under: [KEY_PREFIX].cycle.[CYCLE_NUMBER]
</final_summary>

<instructions>
  ACTION: Finalize PEER cycle
  UPDATE: Cycle status to completed
  PROVIDE: Summary of completed work
  CLEANUP: Any temporary context
</instructions>

</step>

<step number="12" name="review_results_display">

### Step 12: Display Review Results

Extract and display review results to the user for transparency and continuous improvement.

<review_extraction>
  # Read the unified state to extract review output
  STATE=$(~/.agent-os/scripts/peer/read-state.sh "[KEY_PREFIX].cycle.[CYCLE_NUMBER]")
  REVIEW_OUTPUT=$(echo "$STATE" | jq -r '.phases.review.output // empty')
  
  IF [ -z "$REVIEW_OUTPUT" ] || [ "$REVIEW_OUTPUT" = "null" ]; then
    DISPLAY: "Review phase completed but no detailed output available."
    PROCEED: To process flow end
  ELSE:
    FORMAT: Review results for user display
  fi
</review_extraction>

<review_display_format>
  ## 📋 PEER Review Results

  **Quality Score:** [EXTRACT from review.output.quality_score]/100
  
  ### ✅ Strengths
  [LIST from review.output.strengths]
  
  ### 🔄 Improvements
  [LIST from review.output.improvements]
  
  ### 💡 Recommendations
  [LIST from review.output.recommendations]
  
  ### 📝 Additional Insights
  [DISPLAY review.output.insights if available]
  
  ---
  💡 **Tip:** Use `/peer --instruction=refine-spec` to incorporate these recommendations into your spec.
</review_display_format>

<instructions>
  ACTION: Extract review output from unified state
  FORMAT: Quality scores and category breakdowns for user
  DISPLAY: Strengths, improvements, and recommendations clearly
  PROVIDE: Helpful note about using refine-spec for improvements
</instructions>

</step>

</process_flow>

## Execution Standards

- All logic expressed through process flow
- No external script dependencies
- State managed through NATS KV
- Clear error messages and recovery paths
- Comprehensive phase validation
- Professional output formatting
- Continuous improvement through review

## Error Handling

<error_principles>
  - Stop execution on critical errors
  - Provide clear error messages
  - Include recovery instructions
  - Document partial completions
  - Enable continuation when possible
</error_principles>

## Final Checklist

<verify>
  - [ ] NATS server available
  - [ ] KV bucket configured
  - [ ] Arguments validated
  - [ ] Context determined
  - [ ] Cycle initialized
  - [ ] All phases executed
  - [ ] Results presented
  - [ ] Review completed
  - [ ] Cycle finalized
</verify>
