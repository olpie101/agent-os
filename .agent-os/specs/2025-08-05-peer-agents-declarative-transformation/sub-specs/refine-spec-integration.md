# Refine-Spec Integration Sub-Specification

> Sub-spec for: PEER Agents Declarative Transformation
> Main Spec: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/spec.md
> Created: 2025-08-08
> Priority: High

## Issue Identification

The `refine-spec` instruction is incompletely integrated into the PEER pattern agents, despite being:
- Listed as a spec-aware instruction in peer.md
- Having its own instruction file at `/instructions/core/refine-spec.md`
- Having special handling in peer.md for extracting review recommendations

## Current State Analysis

### Files Missing Refine-Spec Customization

1. **peer-planner.md**
   - Lines 246-261: Has customizations for create-spec, execute-tasks, analyze-product
   - Missing: refine-spec planning customization

2. **peer-executor.md**
   - Lines 281-329: Has delegation contexts for create-spec, git-commit, execute-tasks
   - Missing: refine-spec delegation context

3. **peer-express.md**
   - Lines 202-206, 248-263: Has presentation templates for create-spec, execute-tasks, analyze-product
   - Missing: refine-spec output formatting

4. **peer-review.md**
   - Lines 188-205: Has review criteria for create-spec, execute-tasks, analyze-product
   - Missing: refine-spec quality assessment

### Files With Existing Support

1. **peer.md**
   - Line 135: Lists refine-spec as spec-aware
   - Lines 159-163: Extracts review recommendations for refine-spec
   - Line 560: Suggests using refine-spec after review

## Required Customizations

### Peer Planner Customization

Add to peer-planner.md after line 261:

```markdown
FOR refine-spec:
  - Include existing spec analysis phase
  - Add review recommendations integration
  - Plan documentation update steps
  - Include task status preservation
```

## CRITICAL FIX: Complex JSON Handling for All Agents

All peer agents must use the file injection pattern (following peer-express.md pattern) when handling complex JSON to prevent escaping declarative boundaries.

### Peer Planner Fix (Step 6 - line 277)

In peer-planner.md Step 6 "update_state_with_plan", replace the current update_operation with:

```markdown
<planning_output_creation>
  # Create temporary directory for this agent
  CREATE_DIR /tmp/peer-planner
  
  # Create the planning output JSON in a temporary file
  CREATE planning_output AS {
    "instruction": "${instruction_name}",
    "type": "${instruction_type}",
    "spec_name": "${spec_name}",
    "estimated_duration": estimated_duration_value,
    "phases": [generated_phases_array],
    "risks": [identified_risks_array],
    "dependencies": [required_dependencies_array],
    "success_criteria": {
      "overall": "overall_success_description",
      "measurable": [measurable_criteria_array]
    }
  }
  WRITE_TOOL /tmp/peer-planner/planning_output_cycle_[CYCLE_NUMBER].json
</planning_output_creation>

<update_operation>
  # Use file created above with deterministic name
  PLAN_FILE="/tmp/peer-planner/planning_output_cycle_[CYCLE_NUMBER].json"
  
  # Define JQ filter for updating state (Phase Ownership Rule: Only modify phases.plan)
  # Note: --slurpfile creates arrays, so use $plan_out[0]
  JQ_FILTER='
    .metadata.status = "EXECUTING" |
    .metadata.updated_at = (now | todate) |
    .phases.plan.status = "completed" |
    .phases.plan.completed_at = (now | todate) |
    .phases.plan.started_at = (.phases.plan.started_at // (now | todate)) |
    .phases.plan.output = $plan_out[0]
  '
  
  # Use wrapper script with file injection
  result=$(~/.agent-os/scripts/peer/update-state.sh "${STATE_KEY}" "${JQ_FILTER}" \
    --json-file "plan_out=${PLAN_FILE}")
  UPDATE_EXIT=$?
  
  # Clean up temporary file
  rm -f "${PLAN_FILE}"
  
  if [ $UPDATE_EXIT -ne 0 ]; then
    echo "ERROR: Failed to update state with planning output" >&2
    exit 1
  fi
</update_operation>
```

### Peer Review Fix (Modify Steps 8-9 - lines 384-510)

In peer-review.md, the complex JSON is created in Step 8 and used in Step 9. Need to modify Step 8 to write to file and Step 9 to use file injection:

#### Step 8 Modification - Add File Writing

At the end of Step 8 "create_review_output", after the `output_creation` section, add:

```markdown
<write_review_files>
  <prepare_environment>
    CREATE_DIR /tmp/peer-review
  </prepare_environment>
  
  <write_review_output>
    # Write the review_output to file for next step
    WRITE_TOOL /tmp/peer-review/review_output_cycle_[CYCLE_NUMBER].json WITH review_output
  </write_review_output>
  
  <write_insights>
    # Write the insights to file for next step
    WRITE_TOOL /tmp/peer-review/insights_cycle_[CYCLE_NUMBER].json WITH insights
  </write_insights>
</write_review_files>
```

#### Step 9 Modification - Use File Injection

Replace the current Step 9 "update_state_with_review" state_finalization section with:

```markdown
<state_finalization>
  # Use files created in Step 8 with deterministic names
  REVIEW_FILE="/tmp/peer-review/review_output_cycle_[CYCLE_NUMBER].json"
  INSIGHTS_FILE="/tmp/peer-review/insights_cycle_[CYCLE_NUMBER].json"
  
  # Define JQ filter for final update (Phase Ownership Rule: Only modify phases.review)
  # Note: --slurpfile creates arrays, so use $review_out[0] and $insights_data[0]
  JQ_FILTER='
    .metadata.status = "COMPLETE" |
    .metadata.completed_at = (now | todate) |
    .metadata.updated_at = (now | todate) |
    .phases.review.status = "completed" |
    .phases.review.completed_at = (now | todate) |
    .phases.review.output = $review_out[0] |
    .insights = $insights_data[0]
  '
  
  # Use wrapper script with file injection
  result=$(~/.agent-os/scripts/peer/update-state.sh "${STATE_KEY}" "${JQ_FILTER}" \
    --json-file "review_out=${REVIEW_FILE}" \
    --json-file "insights_data=${INSIGHTS_FILE}")
  UPDATE_EXIT=$?
  
  # Clean up temporary files
  rm -f "${REVIEW_FILE}" "${INSIGHTS_FILE}"
  
  if [ $UPDATE_EXIT -ne 0 ]; then
    echo "ERROR: Failed to update state with review results" >&2
    exit 1
  fi
</state_finalization>
```

### Peer Executor Fix (Modify Steps 7-8 - lines 366-436)

In peer-executor.md, Step 7 creates execution_output and Step 8 uses it. Need to modify:

#### Step 7 Modification - Add File Writing

At the end of Step 7 "capture_execution_results", after the `result_processing` section, add:

```markdown
<write_execution_files>
  <prepare_environment>
    CREATE_DIR /tmp/peer-executor
  </prepare_environment>
  
  <write_execution_output>
    # Write the execution_output to file for next step
    WRITE_TOOL /tmp/peer-executor/execution_output_cycle_[CYCLE_NUMBER].json WITH execution_output
  </write_execution_output>
</write_execution_files>
```

#### Step 8 Modification - Use File Injection

Replace the current Step 8 "update_state_with_results" state_finalization section with:

```markdown
<state_finalization>
  # Use file created in Step 7 with deterministic name
  EXEC_FILE="/tmp/peer-executor/execution_output_cycle_[CYCLE_NUMBER].json"
  
  # Define JQ filter for final update (Phase Ownership Rule: Only modify phases.execute)
  # Note: --slurpfile creates arrays, so use $exec_output[0]
  JQ_FILTER='
    .metadata.status = "EXPRESSING" |
    .metadata.current_phase = "express" |
    .metadata.updated_at = (now | todate) |
    .phases.execute.status = "completed" |
    .phases.execute.completed_at = (now | todate) |
    .phases.execute.output = $exec_output[0]
  '
  
  # Use wrapper script with file injection
  result=$(~/.agent-os/scripts/peer/update-state.sh "${STATE_KEY}" "${JQ_FILTER}" \
    --json-file "exec_output=${EXEC_FILE}")
  UPDATE_EXIT=$?
  
  # Clean up temporary file
  rm -f "${EXEC_FILE}"
  
  if [ $UPDATE_EXIT -ne 0 ]; then
    echo "ERROR: Failed to update state with execution results" >&2
    exit 1
  fi
</state_finalization>
```


### Key Pattern Elements (from peer-express.md)

All agents MUST follow these patterns:

1. **Directory Creation**: Each agent gets its own temp directory (`/tmp/peer-[agent]/`)
2. **File Creation**: Use WRITE_TOOL to create JSON files (agent action, not bash)
3. **Deterministic Names**: Use `[output_type]_cycle_[CYCLE_NUMBER].json` pattern
4. **Array Access**: Remember `--slurpfile` creates arrays, use `$var[0]` syntax
5. **Cleanup**: Always remove temporary files after use
6. **Error Handling**: Check UPDATE_EXIT and handle failures

### Peer Executor Customization

Add to peer-executor.md after line 329:

```markdown
<for_refine_spec if="instruction_name == 'refine-spec'">
  SET delegation_prompt = |
    Execute the refine-spec instruction with these parameters:
    - Arguments: ${instruction_args}
    - Spec: ${spec_name}
    
    REVIEW RECOMMENDATIONS:
    ${review_recommendations ? review_recommendations : "No previous review recommendations available"}
    
    IMPORTANT: Preserve existing task completion status while refining documentation.
    
    Follow the instruction guidelines in @~/.agent-os/instructions/core/refine-spec.md
</for_refine_spec>
```

### Peer Express Customization

Add to peer-express.md after line 206:

```markdown
ELIF instruction_name == "refine-spec":
  SET next_steps = "Review refined spec and continue with implementation"
```

Add to peer-express.md after line 263:

```markdown
<for_refine_spec if="instruction_name == 'refine-spec'">
  FORMAT: |
    ## 📝 Spec Refinement Complete
    
    **Spec:** ${spec_name}
    **Files Updated:** ${list_updated_files()}
    
    ### 🔄 Key Changes
    ${list_key_changes()}
    
    ### ✅ Refinements Applied
    ${list_refinements()}
    
    ### 📊 Task Status
    - Preserved: ${count_preserved_tasks()}
    - Modified: ${count_modified_tasks()}
    - Added: ${count_new_tasks()}
</for_refine_spec>
```

### Peer Review Customization

Add to peer-review.md after line 205:

```markdown
<for_refine_spec if="instruction_name == 'refine-spec'">
  SET review_focus = {
    "focus_areas": ["requirement_alignment", "documentation_consistency", "task_preservation"],
    "quality_metrics": ["changes_completeness", "technical_feasibility", "clarity_improvement"],
    "success_indicators": ["requirements_addressed", "tasks_properly_preserved", "consistency_maintained"]
  }
</for_refine_spec>
```

## Integration Testing Requirements

After implementing customizations:

1. Test refine-spec with previous review recommendations
2. Test refine-spec without previous recommendations
3. Verify task status preservation
4. Validate output formatting
5. Confirm review quality assessment

## Expected Outcomes

- Complete refine-spec integration across all PEER agents
- Consistent handling of spec refinement workflows
- Proper utilization of review recommendations
- Preserved task completion status during refinements

## Dependencies

- No changes needed to refine-spec.md instruction itself
- No changes needed to peer.md coordinator
- Only peer agent customization files require updates

## Risk Assessment

- **Low Risk**: Additions follow existing patterns
- **No Breaking Changes**: Default handling remains as fallback
- **Testing Required**: Minimal, follows established patterns