# Task 2.5: Peer-Express Subagent Delegation

## Overview

This document defines the detailed step delegation for the peer-express subagent, ensuring professional presentation of execution results with clear communication of achievements and outcomes.

## Step Definition

```xml
<step number="9" subagent="peer-express" name="express_phase">

### Step 9: Express Phase

Use the peer-express subagent to format and present the execution results professionally.

<phase_validation>
  CHECK: Execution phase completed
  VERIFY: Execution results exist at [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution
  IF execution results not available:
    ERROR: "Cannot express without completed execution phase"
    PROVIDE: "Ensure execution phase completed successfully"
    STOP execution
</phase_validation>

<express_context>
  CYCLE_NUMBER: [CYCLE_NUMBER]
  KEY_PREFIX: [KEY_PREFIX]
  INSTRUCTION: [INSTRUCTION_NAME]
  PLAN_LOCATION: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
  EXECUTION_LOCATION: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution
  DELIVERABLES_LOCATION: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:deliverables
</express_context>

<instructions>
  ACTION: Use peer-express subagent
  REQUEST: "Format and present execution results
            Cycle: [CYCLE_NUMBER]
            Instruction: [INSTRUCTION_NAME]
            
            Context:
            - NATS KV Bucket: agent-os-peer-state
            - Plan at: [PLAN_LOCATION]
            - Execution results at: [EXECUTION_LOCATION]
            - Deliverables at: [DELIVERABLES_LOCATION]
            
            Expression Requirements:
            1. Retrieve all phase outputs from NATS KV:
               - Original plan and objectives
               - Execution results and status
               - Created deliverables
            
            2. Create professional presentation including:
               - Executive summary of work completed
               - Key achievements aligned with plan
               - Deliverables with locations
               - Any issues encountered and resolutions
               - Clear next steps (if applicable)
            
            3. Format based on instruction type:
               
               For create-spec:
               - Highlight spec documentation created
               - List all spec files with brief descriptions
               - Provide spec location and structure
               - Include review/approval status
               
               For execute-tasks:
               - Show tasks completed vs planned
               - Highlight test results
               - Document any code changes
               - Include PR/commit information
               
               For analyze-product:
               - Present key findings and insights
               - Highlight actionable recommendations
               - Show analysis coverage
               - Include strategic implications
            
            4. Structure the presentation:
               # PEER Execution Summary
               
               ## Overview
               [Brief summary of what was accomplished]
               
               ## Objectives vs Achievements
               [Compare planned objectives with actual results]
               
               ## Key Deliverables
               [List with descriptions and locations]
               
               ## Execution Details
               [Relevant details based on instruction type]
               
               ## Issues & Resolutions
               [Any challenges faced and how resolved]
               
               ## Next Steps
               [Clear actionable items if applicable]
            
            5. Include visual elements:
               - ✅ for completed items
               - 📁 for file/directory creation
               - 🔧 for modifications
               - ⚠️ for warnings or partial completion
               - 📊 for metrics or results
            
            6. Create both formatted versions:
               - Full presentation for display
               - Summary version for quick reference
            
            7. Store express outputs in NATS KV:
               - Full presentation: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express
               - Summary: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express_summary
               - Metrics: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express_metrics
            
            8. Ensure presentation is:
               - Clear and professional
               - Accurate to execution results
               - Useful for stakeholders
               - Action-oriented where appropriate"
  
  WAIT: For express phase completion
  
  PROCESS: Display formatted presentation to user
           Store express outputs in NATS KV
           Update cycle metadata
</instructions>

<presentation_quality>
  ENSURE presentation:
    - Tells a complete story
    - Highlights value delivered
    - Is easy to scan and understand
    - Provides useful detail where needed
    - Maintains professional tone
</presentation_quality>

<validation>
  AFTER expression:
    CHECK: Express outputs stored in NATS KV
    VERIFY: Presentation accurately reflects execution
    ENSURE: All deliverables documented
    CONFIRM: User can understand what was done
</validation>

</step>
```

## Context Passing Details

### Input Context

The express agent receives:
1. **Cycle Information**: For retrieving all phase outputs
2. **Instruction Type**: For appropriate formatting
3. **Phase Results**: Plan, execution, deliverables
4. **NATS Locations**: For accessing stored data

### Output Expectations

The express agent should produce:
1. **Full Presentation**: Complete formatted output
2. **Executive Summary**: Quick overview
3. **Metrics**: Quantifiable results
4. **Visual Formatting**: Professional appearance

### State Management

```
NATS KV Keys:
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express         → Full presentation
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express_summary → Executive summary
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express_metrics → Quantifiable metrics
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:phases_completed → Updated to include "express"
```

## Formatting Guidelines

### Visual Hierarchy
```
# Main Title
## Section Headers
### Subsections
- Bullet points for lists
  - Nested items with indentation
**Bold** for emphasis
`code` for technical terms
```

### Visual Indicators
- ✅ Completed successfully
- ⚠️ Completed with warnings
- ❌ Failed or blocked
- 📁 Created new file/directory
- 🔧 Modified existing file
- 📊 Metrics or measurements
- 🚀 Deployed or launched
- 📝 Documentation created

### Instruction-Specific Templates

#### create-spec Template
```
## Spec Created: [SPEC_NAME]

### Documentation Generated
✅ Spec requirements document
✅ Technical specifications
✅ Task breakdown
✅ Database schema (if applicable)

### Location
📁 `.agent-os/specs/[DATE]-[SPEC_NAME]/`
```

#### execute-tasks Template
```
## Tasks Completed: [X] of [Y]

### Implementation Summary
✅ Task 1: [Description] - [Status]
✅ Task 2: [Description] - [Status]

### Test Results
📊 Tests passed: [X]/[Y]
```

## Quality Criteria

A successful express phase:
1. Accurately summarizes work done
2. Highlights key achievements
3. Documents all deliverables
4. Uses clear, professional language
5. Provides actionable information
6. Is visually well-organized

## Integration Considerations

### 1. Data Retrieval
The express agent must:
- Access multiple NATS KV keys
- Parse JSON execution data
- Correlate plan with results

### 2. Adaptive Formatting
Based on:
- Instruction type
- Execution success level
- Deliverable types
- User needs

### 3. Clarity Focus
Prioritize:
- What was accomplished
- Where to find results
- What happens next
- Any important notes

## Summary

This delegation pattern ensures the peer-express:
- Retrieves comprehensive execution data
- Creates professional presentations
- Adapts to instruction types
- Highlights value delivered
- Stores formatted outputs
- Serves stakeholder needs

The detailed REQUEST ensures consistent, high-quality presentation of PEER execution results.