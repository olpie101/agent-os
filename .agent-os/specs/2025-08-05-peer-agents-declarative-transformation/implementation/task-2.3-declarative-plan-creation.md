# Task 2.3: Implement Declarative Plan Creation Logic

> Subtask of Task 2: Transform peer-planner to Declarative Pattern
> Created: 2025-08-05

## Overview

This document details the transformation from bash-based plan creation to declarative plan generation patterns.

## Previous Bash-Based Plan Creation

### Old Pattern: String Concatenation

```bash
# Complex bash variable substitution and JSON construction
planning_output='{
  "instruction": "'$instruction'",
  "type": "spec-aware",
  "spec_name": "'$determined_spec_name'",
  "phases": [
    {
      "phase": "preparation",
      "steps": [...]
    }
  ]
}'

# Save to temp file
echo "$planning_output" > /tmp/planning_output.json

# Update with jq
jq --slurpfile plan /tmp/planning_output.json '.phases.plan = {
  "status": "complete",
  "output": $plan[0]
}' /tmp/cycle.json > /tmp/updated_cycle.json
```

**Issues:**
- Error-prone string concatenation
- JSON injection vulnerabilities
- Complex escaping requirements
- Temp file dependencies
- Manual JSON manipulation

## New Declarative Plan Creation Pattern

### Step 5: Create Structured Plan

```xml
<step number="5" name="create_structured_plan">

### Step 5: Create Comprehensive Execution Plan

Generate a structured plan based on the instruction analysis.

<plan_structure>
  {
    "instruction": "${current_state.metadata.instruction_name}",
    "type": "${instruction_type}",
    "spec_name": "${current_state.metadata.spec_name || determined_spec_name}",
    "estimated_duration": "Based on instruction complexity",
    "phases": [
      {
        "phase": "preparation",
        "description": "Gather context and validate prerequisites",
        "steps": [/* Generated based on instruction */]
      },
      {
        "phase": "execution",
        "description": "Execute the core instruction logic",
        "steps": [/* Generated based on instruction */]
      },
      {
        "phase": "validation",
        "description": "Verify outputs and completeness",
        "steps": [/* Generated based on instruction */]
      }
    ],
    "risks": [...],
    "dependencies": [...],
    "success_criteria": {...}
  }
</plan_structure>
```

## Declarative Plan Customization

### Instruction-Specific Planning

```xml
<plan_customization>
  FOR create-spec:
    - Include spec documentation structure steps
    - Add user requirement clarification phase
    - Plan review checkpoints
    
  FOR execute-tasks:
    - Include task identification steps
    - Add test execution phases
    - Plan git workflow steps
    
  FOR analyze-product:
    - Include codebase analysis phases
    - Add documentation generation steps
    - Plan Agent OS installation steps
</plan_customization>
```

### Dynamic Phase Generation

Instead of hardcoded bash strings, use dynamic phase generation based on instruction analysis:

```xml
<phase_generation>
  <analyze_instruction>
    INPUT: instruction_content from Step 3
    EXTRACT: <process_flow> sections
    IDENTIFY: <step> elements and their purposes
  </analyze_instruction>
  
  <map_to_phases>
    FOR EACH major workflow section in instruction:
      CREATE phase with:
        - name: Derived from section purpose
        - description: Clear objective statement
        - steps: Actionable items from instruction steps
        - validation: Success criteria from instruction
  </map_to_phases>
</phase_generation>
```

## Plan Creation Logic Patterns

### 1. Conditional Phase Inclusion

```xml
<conditional_phases>
  <if condition="instruction_type == 'spec-aware'">
    <add_phase>
      {
        "phase": "spec_validation",
        "description": "Validate spec exists and is accessible",
        "steps": [
          {
            "action": "Verify spec folder structure",
            "validation": "All required files present"
          }
        ]
      }
    </add_phase>
  </if>
  
  <if condition="current_state.context.peer_mode == 'continue'">
    <add_phase>
      {
        "phase": "resume_context",
        "description": "Restore previous execution context",
        "steps": [
          {
            "action": "Load incomplete work from previous cycle",
            "validation": "Context successfully restored"
          }
        ]
      }
    </add_phase>
  </if>
</conditional_phases>
```

### 2. Risk Assessment Pattern

```xml
<risk_identification>
  <common_risks>
    <risk condition="missing_dependencies">
      {
        "risk": "Required files or tools not available",
        "mitigation": "Validate prerequisites before execution",
        "likelihood": "medium"
      }
    </risk>
    
    <risk condition="unclear_requirements">
      {
        "risk": "User requirements ambiguous",
        "mitigation": "Ask clarifying questions in preparation phase",
        "likelihood": "high"
      }
    </risk>
  </common_risks>
  
  <instruction_specific_risks>
    FOR create-spec:
      - Risk: Spec name conflicts
      - Mitigation: Check existing specs before creation
    
    FOR execute-tasks:
      - Risk: Incomplete previous tasks
      - Mitigation: Validate task dependencies
  </instruction_specific_risks>
</risk_identification>
```

### 3. Success Criteria Generation

```xml
<success_criteria_pattern>
  <overall_success>
    DERIVE FROM: instruction's expected deliverables
    FORMAT AS: Single clear statement of completion
  </overall_success>
  
  <measurable_outcomes>
    FOR EACH deliverable in instruction:
      CREATE measurable criterion:
        - Specific output exists
        - Validation passes
        - User approval received
        - Tests succeed
  </measurable_outcomes>
  
  <quality_metrics>
    - Code adheres to standards
    - Documentation is complete
    - No blocking issues remain
    - Performance meets requirements
  </quality_metrics>
</success_criteria_pattern>
```

## Plan Validation Logic

### Pre-Storage Validation

```xml
<plan_validation>
  <structural_checks>
    - Has at least one phase
    - Each phase has at least one step
    - All required fields present
    - JSON structure valid
  </structural_checks>
  
  <semantic_checks>
    - Phases logically ordered
    - Dependencies achievable
    - Success criteria measurable
    - Risks have mitigations
  </semantic_checks>
  
  <completeness_checks>
    - Covers all instruction requirements
    - Includes error handling steps
    - Has clear completion criteria
  </completeness_checks>
</plan_validation>
```

## Key Improvements

### 1. Type Safety
- **Before**: String concatenation with bash variables
- **After**: Structured templates with field references

### 2. Flexibility
- **Before**: Hardcoded JSON strings
- **After**: Dynamic generation based on instruction analysis

### 3. Validation
- **Before**: No validation before storage
- **After**: Multi-level validation before state update

### 4. Reusability
- **Before**: Duplicate plan structures in bash
- **After**: Reusable patterns and templates

### 5. Maintainability
- **Before**: Bash string manipulation
- **After**: Clear declarative structures

## Example: Create-Spec Plan Generation

### Input Context
```json
{
  "metadata": {
    "instruction_name": "create-spec",
    "spec_name": null
  },
  "context": {
    "user_requirements": "Build a password reset feature"
  }
}
```

### Generated Plan Structure
```json
{
  "instruction": "create-spec",
  "type": "spec-aware",
  "spec_name": "password-reset-feature",
  "estimated_duration": "45 minutes",
  "phases": [
    {
      "phase": "preparation",
      "description": "Gather context and validate prerequisites",
      "steps": [
        {
          "step": 1,
          "action": "Read product mission and roadmap",
          "purpose": "Ensure alignment with product goals",
          "success_criteria": "Clear understanding of product context"
        },
        {
          "step": 2,
          "action": "Analyze user requirements",
          "purpose": "Extract spec details and scope",
          "success_criteria": "Requirements fully understood"
        }
      ]
    },
    {
      "phase": "execution",
      "description": "Create spec documentation structure",
      "steps": [
        {
          "step": 3,
          "action": "Create spec folder: .agent-os/specs/2025-08-05-password-reset-feature/",
          "purpose": "Organize spec documentation",
          "success_criteria": "Folder structure created"
        },
        {
          "step": 4,
          "action": "Generate spec.md with requirements",
          "purpose": "Document feature requirements",
          "success_criteria": "Complete spec document created"
        },
        {
          "step": 5,
          "action": "Create technical-spec.md",
          "purpose": "Define technical implementation",
          "success_criteria": "Technical details documented"
        },
        {
          "step": 6,
          "action": "Generate tasks.md",
          "purpose": "Break down implementation tasks",
          "success_criteria": "Actionable task list created"
        }
      ]
    },
    {
      "phase": "validation",
      "description": "Verify spec completeness and get approval",
      "steps": [
        {
          "step": 7,
          "action": "Review all generated documentation",
          "purpose": "Ensure completeness and consistency",
          "success_criteria": "All required sections present"
        },
        {
          "step": 8,
          "action": "Request user review and approval",
          "purpose": "Validate spec meets requirements",
          "success_criteria": "User approval received"
        }
      ]
    }
  ],
  "risks": [
    {
      "risk": "Unclear requirements",
      "mitigation": "Ask clarifying questions before spec creation",
      "likelihood": "medium"
    },
    {
      "risk": "Spec name conflicts",
      "mitigation": "Check existing specs for naming conflicts",
      "likelihood": "low"
    }
  ],
  "dependencies": [
    "Product mission.md exists",
    "Write access to .agent-os directory",
    "User available for clarifications"
  ],
  "success_criteria": {
    "overall": "Complete spec documentation created and approved",
    "measurable": [
      "Spec folder created with date prefix",
      "All required markdown files generated",
      "User review completed and approved",
      "Tasks broken down into executable items"
    ]
  }
}
```

## Testing the Declarative Logic

### Verification Points

1. **No Bash Dependencies**: Plan creation uses no bash scripts or commands
2. **No String Concatenation**: JSON built through structured templates
3. **Dynamic Generation**: Plans adapt based on instruction type
4. **Validation Coverage**: All plans validated before storage
5. **Error Handling**: Clear errors for invalid plan structures

## Summary

The declarative plan creation logic transformation provides:
- **Safety**: No JSON injection or escaping issues
- **Flexibility**: Dynamic plan generation based on instruction
- **Validation**: Multi-level checks before storage
- **Maintainability**: Clear, readable plan structures
- **Testability**: Isolated logic without bash dependencies

This completes the implementation of declarative plan creation logic for the peer-planner agent.