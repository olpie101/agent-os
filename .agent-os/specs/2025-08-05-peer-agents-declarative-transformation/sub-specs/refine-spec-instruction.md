# Refine-Spec Instruction Specification

> Spec: refine-spec-instruction
> Created: 2025-08-07
> Parent Spec: peer-agents-declarative-transformation

## Overview

Create a new Agent OS instruction `refine-spec` that enables iterative refinement of existing specifications based on review feedback, user requirements, or implementation discoveries.

## Purpose

While `create-spec` creates new specifications from scratch, `refine-spec` works with existing specifications to:
- Incorporate review phase recommendations
- Address user-requested changes
- Update based on implementation discoveries
- Refine scope or technical approach
- Improve clarity and completeness

## Instruction Design

### File Location
`~/.agent-os/instructions/core/refine-spec.md`

### Core Differences from create-spec

| Aspect | create-spec | refine-spec |
|--------|------------|-------------|
| **Folder Creation** | Creates new dated folder | Works in existing folder |
| **Spec Name** | Determines from requirements | Uses existing spec name |
| **File Handling** | Creates all files fresh | Updates existing files in-place |
| **Context** | Starts from product mission | Starts from existing spec |
| **Date Handling** | Uses current date for folder | Preserves original folder date |
| **Tasks** | Creates new tasks.md | Preserves/updates based on completion |
| **History** | No history tracking | Creates refinement log |
| **Sub-specs** | Creates standard set | Loads all existing sub-specs dynamically |

## Process Flow Structure

### Step 1: Spec Identification

```xml
<step number="1" subagent="context-fetcher" name="identify_spec">

### Step 1: Identify Target Specification

Determine which existing spec to refine based on user input.

<identification_logic>
  IF --spec flag provided:
    SPEC_NAME = provided value
    SEARCH: .agent-os/specs/*-${SPEC_NAME}/
  ELSE IF user mentions spec by name:
    EXTRACT: Spec name from user input
    SEARCH: .agent-os/specs/*-${SPEC_NAME}/
  ELSE IF "refine the last spec" or similar:
    FIND: Most recent spec folder by date
  ELSE:
    ERROR: "Please specify which spec to refine"
    LIST: Available specs with dates
    STOP execution
</identification_logic>

<validation>
  VERIFY: Spec folder exists
  VERIFY: spec.md exists in folder
  CAPTURE: Full folder path as SPEC_FOLDER
  EXTRACT: SPEC_NAME from folder name (after date prefix)
</validation>

</step>
```

### Step 2: Context Loading

```xml
<step number="2" subagent="context-fetcher" name="load_existing_spec">

### Step 2: Load Existing Specification

Read current spec files to understand the existing state.

<files_to_load>
  REQUIRED:
    - ${SPEC_FOLDER}/spec.md
    - ${SPEC_FOLDER}/spec-lite.md
    - ${SPEC_FOLDER}/sub-specs/technical-spec.md
    - ${SPEC_FOLDER}/tasks.md
  
  ADDITIONAL:
    SCAN: ${SPEC_FOLDER}/sub-specs/ directory
    LOAD: All other .md files found in sub-specs/
    REASON: Specs may have custom sub-specifications based on their needs
    EXAMPLES: 
      - database-schema.md
      - api-spec.md
      - peer-coordinator-improvements.md
      - refine-spec-instruction.md
      - Any other domain-specific sub-specs
</files_to_load>

<context_extraction>
  FROM spec.md:
    - Current overview and goals
    - User stories
    - Scope definition
    - Expected deliverables
  
  FROM technical-spec.md:
    - Current technical approach
    - Implementation details
    - Dependencies
    - Performance criteria
  
  FROM tasks.md:
    - Completed tasks (checked items)
    - Pending tasks (unchecked items)
    - Blocked tasks (with ⚠️ emoji)
  
  FROM review feedback (if via PEER):
    - Improvements suggested
    - Recommendations provided
</context_extraction>

</step>
```

### Step 3: Refinement Requirements

```xml
<step number="3" subagent="context-fetcher" name="gather_refinements">

### Step 3: Gather Refinement Requirements

Understand what needs to be refined and why.

<refinement_sources>
  <from_user>
    - Direct change requests
    - Scope modifications  
    - New requirements
    - Clarifications needed
  </from_user>
  
  <from_review if="invoked via PEER">
    - Quality review recommendations
    - Identified gaps
    - Suggested improvements
  </from_review>
  
  <from_implementation>
    - Discovered constraints
    - Technical limitations
    - Better approaches found
  </from_implementation>
</refinement_sources>

<refinement_classification>
  DETERMINE refinement type:
    - SCOPE_CHANGE: Adding/removing features
    - CLARIFICATION: Making requirements clearer
    - TECHNICAL_UPDATE: Changing implementation approach
    - QUALITY_IMPROVEMENT: Addressing review feedback
    - ERROR_CORRECTION: Fixing mistakes or oversights
</refinement_classification>

</step>
```

### Step 4: Update spec.md (Conditional)

```xml
<step number="4" subagent="file-creator" name="update_spec_md">

### Step 4: Update Main Specification (Conditional)

Refine spec.md if changes affect the main specification.

<conditional_execution>
  IF refinement affects:
    - Overview or goals
    - User stories
    - Scope definition
    - Expected deliverables
  THEN:
    UPDATE spec.md
  ELSE:
    SKIP this step
</conditional_execution>

<update_actions>
  - UPDATE: Overview if goals changed
  - REFINE: User stories for clarity
  - MODIFY: Scope based on changes
  - ADJUST: Expected deliverables
  - PRESERVE: Original creation date
  - ADD: "Last Refined: [DATE]" header at top
</update_actions>

</step>
```

### Step 5: Update spec-lite.md (Conditional)

```xml
<step number="5" subagent="file-creator" name="update_spec_lite">

### Step 5: Update Condensed Specification (Conditional)

Regenerate spec-lite.md if spec.md was updated.

<conditional_execution>
  IF spec.md was updated in Step 4:
    REGENERATE spec-lite.md
  ELSE:
    SKIP this step
</conditional_execution>

<update_actions>
  - REGENERATE: Based on updated spec.md content
  - MAINTAIN: Concise 1-3 sentence format
  - REFLECT: Key changes from refinement
</update_actions>

</step>
```

### Step 6: Update technical-spec.md

```xml
<step number="6" subagent="file-creator" name="update_technical_spec">

### Step 6: Update Technical Specification

Update technical-spec.md based on refinement requirements.

<conditional_execution>
  IF refinement affects:
    - Technical approach
    - Implementation details
    - Dependencies
    - Performance criteria
  THEN:
    UPDATE technical-spec.md
  ELSE:
    SKIP this step
</conditional_execution>

<update_actions>
  - UPDATE: Technical approach if changed
  - REFINE: Implementation details
  - ADJUST: Dependencies if needed
  - MAINTAIN: Document structure
</update_actions>

</step>
```

### Step 7: Update other sub-specs

```xml
<step number="7" subagent="file-creator" name="update_other_sub_specs">

### Step 7: Update Other Sub-Specifications

Update any additional sub-spec files that exist and need refinement.

<conditional_updates>
  FOR EACH file in sub-specs/ (except technical-spec.md):
    IF refinement affects this sub-spec:
      - UPDATE: Relevant sections based on refinement requirements
      - MAINTAIN: Document structure and format
      - PRESERVE: Unaffected sections
    ELSE:
      - SKIP: No changes needed
</conditional_updates>

</step>
```

### Step 8: Update tasks.md

```xml
<step number="8" subagent="file-creator" name="update_tasks">

### Step 8: Update Task List

Refine tasks.md based on scope changes and completion status.

<task_update_rules>
  IF any tasks marked as completed (checked [x]):
    - PRESERVE: All completed task checkmarks
    - ONLY modify descriptions if critical error found
    - ADD: ~~strikethrough~~ to obsolete completed tasks
    - KEEP: Record of what was done
  ELSE (no completed tasks):
    - FREELY modify task descriptions
    - ADD/REMOVE tasks as needed
    - REORGANIZE task structure if beneficial
    - No strikethrough needed (nothing was implemented yet)
  
  FOR all cases:
    - ADD: New tasks for expanded scope
    - ANNOTATE: Significant changes with [REFINED] marker
    - UPDATE: Task numbers if tasks added/removed
</task_update_rules>

</step>
```

### Step 9: Create Refinement Summary

```xml
<step number="9" subagent="file-creator" name="document_refinement">

### Step 9: Create Refinement Summary

Document what was refined in a summary file for traceability.

<summary_creation>
  CREATE OR APPEND to: ${SPEC_FOLDER}/refinement-log.md
  
  ## Refinement - ${CURRENT_DATE}
  
  ### Reason for Refinement
  ${REFINEMENT_REASON}
  
  ### Changes Made
  - ${LIST_OF_SIGNIFICANT_CHANGES}
  
  ### Source
  ${REFINEMENT_SOURCE} (user request/review feedback/implementation discovery)
  
  ### Files Modified
  - ${LIST_OF_MODIFIED_FILES}
</summary_creation>

</step>
```

### Step 10: User Review

```xml
<step number="10" name="user_review">

### Step 10: Present Refinements for Review

Show the user what was refined and request confirmation.

<review_presentation>
  ## Specification Refined: ${SPEC_NAME}
  
  ### Refinement Summary
  - Type: ${REFINEMENT_TYPE}
  - Files Updated: ${COUNT} files
  - Refinement logged: ${SPEC_FOLDER}/refinement-log.md
  
  ### Key Changes
  ${SUMMARY_OF_CHANGES}
  
  ### Next Steps
  - Review refined specification files
  - To revert: Use git to restore previous version
  - To proceed: Continue with implementation or further refinement
  
  The specification has been refined while preserving any completion history.
</review_presentation>

</step>
```

## Integration with PEER Pattern

When invoked via `/peer --instruction=refine-spec`:

1. **Planning Phase**: Analyze existing spec and plan refinements
2. **Execution Phase**: Apply refinements to spec files
3. **Express Phase**: Present refined spec professionally
4. **Review Phase**: Assess refinement quality and completeness

The refine-spec instruction should:
- Accept review recommendations from previous PEER cycles
- Use the same spec name throughout refinement cycles
- Maintain refinement log for audit trail

## PEER Coordinator (peer.md) Changes Required

### Enhancement: Refinement Context Passing

Add the following to peer.md Step 4 (execution_context_determination) after the spec_name_determination section:

```xml
<refinement_context_enhancement>
  IF INSTRUCTION_NAME == "refine-spec":
    # refine-spec should be in spec_aware_instructions list
    SET: SPEC_AWARE = true
    
    # Check for previous cycles to get review recommendations
    IF CYCLE_NUMBER > 1:
      PREVIOUS_CYCLE=$((CYCLE_NUMBER - 1))
      PREVIOUS_STATE=$(nats kv get agent-os-peer-state "[KEY_PREFIX].cycle.${PREVIOUS_CYCLE}" --raw 2>/dev/null)
      
      IF [ ! -z "$PREVIOUS_STATE" ]:
        # Extract review recommendations if available
        REVIEW_RECOMMENDATIONS=$(echo "$PREVIOUS_STATE" | jq -r '.phases.review.output.recommendations[]' 2>/dev/null)
        IF [ ! -z "$REVIEW_RECOMMENDATIONS" ]:
          # Store in context for refine-spec to use
          ADD to unified state context:
            "previous_review_recommendations": "${REVIEW_RECOMMENDATIONS}"
            "previous_cycle_number": ${PREVIOUS_CYCLE}
</refinement_context_enhancement>
```

Additionally, update the spec_aware_instructions list in Step 4:

```xml
<spec_aware_instructions>
  - create-spec
  - execute-tasks
  - analyze-product
  - refine-spec    <!-- Add this line -->
</spec_aware_instructions>
```

Additionally, ensure that the instruction contains the expected preflight section present in the peer instruction.

This enhancement allows refine-spec to:
1. Be properly classified as spec-aware
2. Access previous cycle's review recommendations automatically
3. Know which cycle it's refining from

## Key Design Principles

### 1. Preservation
- Never lose completed work
- Maintain task completion status
- Keep refinement log

### 2. Traceability  
- Document all refinements in log
- Record refinement reasons
- Track source of changes (user/review/implementation)

### 3. Version Control
- Rely on git for versioning
- User controls when to commit
- Standard git workflows for rollback

### 4. Continuity
- Same spec folder throughout lifecycle
- Consistent naming conventions
- Clear evolution path

## Error Handling

### Common Scenarios

1. **Spec Not Found**
   - List available specs
   - Suggest similar names
   - Guide to create-spec if needed

2. **Corrupted Spec Files**
   - Report specific issues found
   - Suggest git recovery if available
   - Offer manual intervention guidance

3. **Conflicting Changes**
   - Highlight conflicts
   - Request user decision
   - Document resolution

## Success Criteria

A successful refine-spec implementation will:

1. ✅ Seamlessly update existing specs without disruption
2. ✅ Preserve all completion history and progress
3. ✅ Document all refinements in a log file
4. ✅ Integrate smoothly with PEER pattern workflow
5. ✅ Handle edge cases gracefully
6. ✅ Maintain Agent OS standards throughout
7. ✅ Properly handle both specs with and without completed tasks

## Testing Requirements

### Functional Tests
1. Refine spec with completed tasks (preserves checkmarks)
2. Refine spec with no completed tasks (allows free modification)
3. Refine spec multiple times (appends to log)
4. Refine based on review feedback
5. Handle missing spec gracefully
6. Load all sub-spec files dynamically

### Integration Tests
1. PEER pattern invocation
2. Transition from create-spec to refine-spec
3. Multiple refinement cycles
4. Cross-instruction compatibility

## Implementation Priority

**High Priority**:
- Core refinement logic
- Task preservation rules (completed vs uncompleted)
- Dynamic sub-spec file loading

**Medium Priority**:
- Refinement log generation
- PEER integration enhancements
- Review feedback incorporation

**Low Priority**:
- Advanced conflict resolution
- Refinement analytics
- Cross-spec dependency tracking
