# Task 2.4: Peer-Executor Subagent Delegation

## Overview

This document defines the detailed step delegation for the peer-executor subagent, ensuring proper execution of the planned instruction with full state tracking and output capture.

## Step Definition

```xml
<step number="8" subagent="peer-executor" name="execution_phase">

### Step 8: Execution Phase

Use the peer-executor subagent to execute the planned instruction using appropriate Agent OS patterns.

<phase_validation>
  CHECK: Planning phase completed
  VERIFY: Plan exists at [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
  IF plan not available:
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
            Cycle: [CYCLE_NUMBER]
            
            Context:
            - NATS KV Bucket: agent-os-peer-state
            - Plan Location: [PLAN_LOCATION]
            - Spec Name: [SPEC_NAME] (if applicable)
            - Key Prefix: [KEY_PREFIX]
            
            Execution Requirements:
            1. Retrieve and review the execution plan from NATS KV
            
            2. Execute the target instruction by:
               - Loading @~/.agent-os/instructions/core/[INSTRUCTION_NAME].md
               - Following the instruction's process flow
               - Implementing each planned phase
            
            3. For spec-aware instructions:
               - Use spec name: [SPEC_NAME]
               - Create/modify files in appropriate spec directory
               - Follow spec-specific patterns
            
            4. Capture during execution:
               - All file operations (creates, updates, deletes)
               - User interactions and responses
               - Subagent delegations and results
               - Any errors or warnings encountered
               - Decision points and choices made
            
            5. Special handling by instruction type:
               - create-spec: Pass spec name '[SPEC_NAME]' to instruction
                 Store spec location for express phase
               - execute-tasks: Track task completion status
                 Capture test results and any issues
               - analyze-product: Document findings and insights
                 Track files analyzed
            
            6. Create execution summary with structure:
               {
                 'instruction': string,
                 'spec': string (optional),
                 'phases_executed': [
                   {
                     'name': string,
                     'status': 'completed' | 'partial' | 'failed',
                     'outputs': string[],
                     'issues': string[]
                   }
                 ],
                 'files_created': string[],
                 'files_modified': string[],
                 'user_interactions': [
                   {
                     'prompt': string,
                     'response': string
                   }
                 ],
                 'deliverables': {
                   'description': string,
                   'location': string
                 }[]
               }
            
            7. Store execution results in NATS KV:
               - Full results at: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution
               - Summary at: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution_summary
               - Deliverables list at: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:deliverables
            
            8. If execution cannot complete:
               - Document what was completed
               - Clearly identify blockers
               - Store partial results
               - Enable continuation later"
  
  WAIT: For execution phase completion
  
  PROCESS: Verify execution results stored in NATS KV
           Extract deliverables for express phase
           Update cycle metadata with execution status
</instructions>

<execution_tracking>
  DURING execution:
    MONITOR: Progress through planned phases
    CAPTURE: All significant actions and decisions
    MAINTAIN: Execution state in NATS KV
    HANDLE: Errors gracefully with documentation
</execution_tracking>

<validation>
  AFTER execution:
    CHECK: Execution results exist in NATS KV
    VERIFY: All planned phases addressed
    ENSURE: Deliverables documented
    ASSESS: Success vs partial completion
    IF critical failure:
      DOCUMENT: Failure details and recovery options
      MARK: Execution as failed with reasons
</validation>

</step>
```

## Context Passing Details

### Input Context

The executor receives:
1. **Instruction Name**: The instruction to execute
2. **Execution Plan**: Retrieved from NATS KV
3. **Spec Name**: For spec-aware instructions
4. **Cycle Context**: For state tracking
5. **Previous Phase Results**: Planning outputs

### Output Expectations

The executor should produce:
1. **Execution Results**: Complete record of actions taken
2. **Deliverables List**: What was created/modified
3. **User Interactions**: Prompts and responses
4. **Status Summary**: Success, partial, or failure

### State Management

```
NATS KV Keys:
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution         → Full execution record (JSON)
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution_summary → Human-readable summary
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:deliverables      → List of created artifacts
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:phases_completed  → Updated to include "execution"
```

## Special Instruction Handling

### create-spec Execution
- Pass determined spec name to create-spec instruction
- Track all spec files created
- Capture user review interactions
- Document final spec location

### execute-tasks Execution
- Identify tasks to execute
- Track completion status for each
- Capture test results
- Document any blocking issues

### analyze-product Execution
- Track files analyzed
- Document findings and insights
- Capture recommendations
- Store analysis artifacts

## Error Handling

### Partial Completion
When execution cannot fully complete:
1. Document what was accomplished
2. Identify specific blockers
3. Store partial results
4. Enable continuation from this point

### Critical Failures
For unrecoverable errors:
1. Capture full error context
2. Suggest recovery approaches
3. Preserve any partial work
4. Mark execution as failed

## Integration Considerations

### 1. Instruction Loading
The executor must:
- Load and parse instruction files
- Follow their process flows
- Respect instruction-specific patterns

### 2. State Persistence
Throughout execution:
- Regularly update NATS KV
- Maintain execution context
- Enable interruption recovery

### 3. Output Capture
Comprehensive tracking of:
- All file operations
- User interactions
- Subagent delegations
- Decision points

## Quality Criteria

A successful execution phase:
1. Completes all planned work
2. Produces expected deliverables
3. Captures comprehensive audit trail
4. Handles errors gracefully
5. Stores results reliably
6. Enables express phase

## Summary

This delegation pattern ensures the peer-executor:
- Receives complete context from planning
- Executes instructions properly
- Captures all relevant information
- Maintains state throughout
- Produces structured output
- Handles various instruction types

The detailed REQUEST provides clear expectations while maintaining flexibility for different execution scenarios.