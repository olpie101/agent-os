# Task 2.3: Peer-Planner Subagent Delegation

## Overview

This document defines the detailed step delegation for the peer-planner subagent, ensuring proper instruction format and context passing according to Agent OS patterns.

## Step Definition

```xml
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
            
            3. Consider instruction-specific requirements:
               - For create-spec: Include spec name '[SPEC_NAME]' in planning
               - For execute-tasks: Plan task execution strategy
               - For analyze-product: Plan analysis approach
            
            4. Structure the plan as JSON with schema:
               {
                 'instruction': string,
                 'spec': string (optional),
                 'phases': [
                   {
                     'name': string,
                     'description': string,
                     'success_criteria': string[],
                     'deliverables': string[],
                     'estimated_effort': string
                   }
                 ],
                 'dependencies': string[],
                 'risks': [
                   {
                     'description': string,
                     'mitigation': string
                   }
                 ]
               }
            
            5. Store the complete plan in NATS KV at:
               [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
            
            6. Also store a planning summary at:
               [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan_summary"
  
  WAIT: For planning phase completion
  
  PROCESS: Verify plan stored successfully in NATS KV
           Extract key planning decisions for executor phase
           Update cycle metadata with planning completion
</instructions>

<validation>
  AFTER planning completion:
    CHECK: Plan exists at expected NATS KV location
    VERIFY: Plan contains all required sections
    ENSURE: Plan is specific to the instruction type
    IF validation fails:
      ERROR: "Planning phase produced invalid output"
      PROVIDE: Details of what's missing
      STOP execution
</validation>

<planning_examples>
  <create_spec_plan>
    For create-spec with spec name "user-authentication":
    - Phase 1: Requirements gathering and clarification
    - Phase 2: Create spec directory and core documentation
    - Phase 3: Define technical specifications
    - Phase 4: Create task breakdown
    - Phase 5: User review and approval
  </create_spec_plan>
  
  <execute_tasks_plan>
    For execute-tasks on existing spec:
    - Phase 1: Context analysis and task identification
    - Phase 2: Development environment setup
    - Phase 3: Task execution with TDD approach
    - Phase 4: Testing and validation
    - Phase 5: Git workflow and documentation
  </execute_tasks_plan>
</planning_examples>

</step>
```

## Context Passing Details

### Input Context

The planner receives:
1. **Instruction Name**: The target instruction to plan for
2. **Spec Name**: If applicable (for spec-aware instructions)
3. **Cycle Number**: For tracking and state management
4. **Key Prefix**: For NATS KV operations
5. **Execution Mode**: New or continue

### Output Expectations

The planner should produce:
1. **Structured Plan**: JSON format with phases, criteria, deliverables
2. **Plan Summary**: Human-readable summary for quick reference
3. **Metadata Updates**: Mark planning phase as complete

### State Management

```
NATS KV Keys:
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan          → Full execution plan (JSON)
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan_summary  → Summary for display
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:phases_completed → Updated to include "planning"
```

## Integration Considerations

### 1. Instruction Analysis
The planner must be able to:
- Read and understand Agent OS instruction files
- Identify key requirements and patterns
- Create instruction-specific plans

### 2. Spec Awareness
For spec-aware instructions:
- Include spec context in planning
- Consider spec location and structure
- Plan for spec-specific deliverables

### 3. Error Handling
The planner should:
- Validate instruction exists and is readable
- Handle missing or invalid specs gracefully
- Provide clear error messages

### 4. Flexibility
The plan should:
- Adapt to different instruction types
- Allow for variations in complexity
- Support both new and continuation modes

## Quality Criteria

A successful planning phase:
1. Produces a clear, actionable plan
2. Identifies all major work phases
3. Sets measurable success criteria
4. Considers risks and dependencies
5. Stores results reliably in NATS KV
6. Provides useful summary for users

## Summary

This delegation pattern ensures the peer-planner:
- Receives complete context for planning
- Produces structured, useful output
- Integrates smoothly with PEER flow
- Maintains state in NATS KV
- Follows Agent OS subagent patterns

The detailed REQUEST format provides all necessary information while maintaining flexibility for different instruction types.