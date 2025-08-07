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

### Step 4: Determine Execution Context

Classify the instruction and determine spec context if applicable.

<context_classification>
  <spec_aware_instructions>
    - create-spec
    - execute-tasks
    - analyze-product
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

<nats_key_prefix>
  IF SPEC_AWARE and SPEC_NAME provided:
    KEY_PREFIX: "peer:spec:[SPEC_NAME]"
  ELSE:
    KEY_PREFIX: "peer:global"
</nats_key_prefix>

<instructions>
  ACTION: Determine instruction context
  CLASSIFY: As spec-aware or non-spec
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
      LOAD: Cycle metadata
      RESUME: From last completed phase
    ELSE:
      ERROR: "No incomplete cycle found to continue"
      PROVIDE: "Start a new cycle with --instruction"
      STOP execution
  ELSE:
    CREATE: New cycle with incremented number
    INITIALIZE: Cycle metadata in NATS KV
</cycle_logic>

<cycle_metadata>
  - cycle_number: Sequential identifier
  - instruction: Target instruction name
  - spec: Spec name if applicable
  - status: "initialized"
  - phases_completed: []
  - created_at: Current timestamp
</cycle_metadata>

<cycle_state_examples>
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:current" "[CYCLE_NUMBER]"
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:metadata" "{json_metadata}"
</cycle_state_examples>

<instructions>
  ACTION: Initialize or resume PEER cycle
  DETERMINE: New cycle or continuation
  STORE: Cycle metadata for phase coordination
  OUTPUT: Cycle number and initial status
</instructions>

</step>

<step number="6" name="spec_name_determination">

### Step 6: Spec Name Determination (Conditional)

For create-spec instructions, determine an appropriate spec name from user requirements.

<conditional_execution>
  IF INSTRUCTION_NAME != "create-spec":
    SKIP this entire step
    PROCEED to step 7
</conditional_execution>

<spec_name_logic>
  IF SPEC_NAME already provided via --spec:
    USE: Provided spec name
  ELSE:
    ANALYZE: User requirements from initial input
    EXTRACT: 3-5 meaningful keywords
    REMOVE: Common words (the, a, an, is, are, and, or, for, to, of, in, on, at, by, with)
    FORMAT: Convert to kebab-case
    LIMIT: Maximum 5 words
    DEFAULT: "new-feature" if extraction fails
</spec_name_logic>

<storage>
  STORE: Determined spec name in cycle metadata
  UPDATE: Context variables with spec name
</storage>

<instructions>
  ACTION: Determine spec name for create-spec instruction
  PROCESS: Extract from user requirements or use provided name
  STORE: In cycle metadata for downstream phases
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
  REQUEST: "Create execution plan for instruction: [INSTRUCTION_NAME]
            Cycle: [CYCLE_NUMBER]
            Spec: [SPEC_NAME] (if applicable)
            
            Context:
            - NATS KV Bucket: agent-os-peer-state
            - Key Prefix: [KEY_PREFIX]
            - Execution Mode: [PEER_MODE]
            
            Requirements:
            1. Analyze the target instruction located at:
               @~/.agent-os/instructions/core/[INSTRUCTION_NAME].md
            
            2. Create a comprehensive execution plan that includes:
               - Breakdown of work into logical phases
               - Success criteria for each phase
               - Expected deliverables
               - Dependencies and prerequisites
               - Risk assessment and mitigation strategies
            
            3. Structure the plan as JSON and store in NATS KV at:
               [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
            
            4. Also store a planning summary at:
               [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan_summary"
  WAIT: For planning completion
  PROCESS: Verify plan stored in NATS KV
</instructions>

</step>

<step number="8" subagent="peer-executor" name="execution_phase">

### Step 8: Execution Phase

Use the peer-executor subagent to execute the planned instruction using appropriate Agent OS patterns.

<phase_validation>
  CHECK: Planning phase completed
  IF plan not available in NATS KV:
    ERROR: "Cannot execute without completed planning phase"
    PROVIDE: "Ensure planning phase completed successfully"
    STOP execution
</phase_validation>

<execution_context>
  INSTRUCTION: [INSTRUCTION_NAME]
  SPEC_NAME: [SPEC_NAME] (if applicable)
  CYCLE_NUMBER: [CYCLE_NUMBER]
  KEY_PREFIX: [KEY_PREFIX]
  PLAN_LOCATION: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
</execution_context>

<instructions>
  ACTION: Use peer-executor subagent
  REQUEST: "Execute instruction: [INSTRUCTION_NAME]
            Using plan from: [PLAN_LOCATION]
            Cycle: [CYCLE_NUMBER]
            
            Context:
            - NATS KV Bucket: agent-os-peer-state
            - Plan Location: [PLAN_LOCATION]
            - Spec Name: [SPEC_NAME] (if applicable)
            - Key Prefix: [KEY_PREFIX]
            
            Follow the execution plan and implement the instruction
            according to Agent OS patterns. Capture all outputs,
            user interactions, and results.
            
            Store execution results in NATS KV at:
            [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution"
  WAIT: For execution completion
  PROCESS: Verify execution results stored
</instructions>

</step>

<step number="9" subagent="peer-express" name="express_phase">

### Step 9: Express Phase

Use the peer-express subagent to format and present the execution results professionally.

<phase_validation>
  CHECK: Execution phase completed
  IF execution results not available in NATS KV:
    ERROR: "Cannot express without completed execution phase"
    PROVIDE: "Ensure execution phase completed successfully"
    STOP execution
</phase_validation>

<express_context>
  CYCLE_NUMBER: [CYCLE_NUMBER]
  KEY_PREFIX: [KEY_PREFIX]
  PLAN_LOCATION: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
  EXECUTION_LOCATION: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution
</express_context>

<instructions>
  ACTION: Use peer-express subagent
  REQUEST: "Format execution results for cycle: [CYCLE_NUMBER]
            Plan available at: [PLAN_LOCATION]
            Execution results at: [EXECUTION_LOCATION]
            
            Create a clear, professional presentation of the work
            completed, highlighting key achievements, deliverables,
            and outcomes.
            
            Store express output in NATS KV at:
            [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express"
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
  REQUEST: "Review PEER execution for cycle: [CYCLE_NUMBER]
            Instruction: [INSTRUCTION_NAME]
            
            Access all phase outputs from NATS KV prefix:
            [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:*
            
            Assess execution quality, identify improvements,
            and provide recommendations for future cycles.
            
            Store review insights in NATS KV at:
            [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:review"
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
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:status" "completed"
  nats kv put agent-os-peer-state "[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:completed_at" "[TIMESTAMP]"
</cycle_finalization>

<final_summary>
  ## PEER Cycle [CYCLE_NUMBER] Complete

  **Instruction:** [INSTRUCTION_NAME]
  **Spec:** [SPEC_NAME] (if applicable)
  
  ✅ Planning phase completed
  ✅ Execution phase completed
  ✅ Express phase completed
  ✅ Review phase completed
  
  All outputs stored in NATS KV under: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]
</final_summary>

<instructions>
  ACTION: Finalize PEER cycle
  UPDATE: Cycle status to completed
  PROVIDE: Summary of completed work
  CLEANUP: Any temporary context
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