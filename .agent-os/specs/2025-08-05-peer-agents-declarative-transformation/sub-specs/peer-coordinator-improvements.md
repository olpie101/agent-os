# PEER Coordinator Improvements Specification

> Spec: peer-coordinator-improvements
> Created: 2025-08-07
> Parent Spec: peer-agents-declarative-transformation

## Overview

Enhance the PEER pattern coordinator (peer.md) with improved cycle management and review results visibility based on production testing insights.

## Technical Requirements

### 1. Cycle Number Management (Step 5 Enhancement)

**Current Issue**: The cycle initialization step states "CREATE: New cycle with incremented number" but lacks implementation details for determining the next cycle number.

**Solution**: Implement proper cycle number determination logic in Step 5.

#### Implementation Details

```xml
<cycle_number_determination>
  # Read current cycle number from NATS KV
  CURRENT_CYCLE_CMD="nats kv get agent-os-peer-state '[KEY_PREFIX].cycle.current' --raw"
  CURRENT_CYCLE=$(eval $CURRENT_CYCLE_CMD 2>/dev/null)
  
  # Determine next cycle number
  IF [ -z "$CURRENT_CYCLE" ] OR [ "$CURRENT_CYCLE" = "null" ]:
    CYCLE_NUMBER=1
    LOG: "Starting with cycle 1 (no previous cycles found)"
  ELSE:
    CYCLE_NUMBER=$((CURRENT_CYCLE + 1))
    LOG: "Incrementing to cycle $CYCLE_NUMBER (previous: $CURRENT_CYCLE)"
  
  # Validate cycle doesn't already exist (safety check)
  EXISTING_CHECK=$(nats kv get agent-os-peer-state "[KEY_PREFIX].cycle.$CYCLE_NUMBER" 2>/dev/null)
  IF [ ! -z "$EXISTING_CHECK" ]:
    ERROR: "Cycle $CYCLE_NUMBER already exists - state corruption detected"
    STOP execution
</cycle_number_determination>
```

#### Update Storage

The cycle number must be stored in two places:
1. In the unified state at `[KEY_PREFIX].cycle.[CYCLE_NUMBER]`
2. As current cycle reference at `[KEY_PREFIX].cycle.current`

### 2. Review Results Display (New Step 12)

**Current Issue**: Review phase completes but results are not displayed to the user, limiting actionability of insights.

**Solution**: Add new Step 12 to display review results after cycle finalization.

#### Step 12: Display Review Results

```xml
<step number="12" name="display_review_results">

### Step 12: Display Review Results

Present the review phase insights and recommendations to the user for actionable feedback.

<review_extraction>
  # Read the review output from unified state
  REVIEW_OUTPUT=$(~/.agent-os/scripts/peer/read-state.sh "[KEY_PREFIX].cycle.[CYCLE_NUMBER]" | jq -r '.phases.review.output')
  
  IF [ -z "$REVIEW_OUTPUT" ] OR [ "$REVIEW_OUTPUT" = "null" ]:
    LOG: "No review output available to display"
    PROCEED to step 12
</review_extraction>

<review_presentation>
  ## 📊 Quality Review Results
  
  **Overall Quality Score:** $(echo "$REVIEW_OUTPUT" | jq -r '.quality_score')/100
  
  ### Category Scores
  - Completeness: $(echo "$REVIEW_OUTPUT" | jq -r '.scores.completeness')/100
  - Accuracy: $(echo "$REVIEW_OUTPUT" | jq -r '.scores.accuracy')/100  
  - Clarity: $(echo "$REVIEW_OUTPUT" | jq -r '.scores.clarity')/100
  - Compliance: $(echo "$REVIEW_OUTPUT" | jq -r '.scores.compliance')/100
  - Usability: $(echo "$REVIEW_OUTPUT" | jq -r '.scores.usability')/100
  
  ### ✅ Strengths Identified
  $(echo "$REVIEW_OUTPUT" | jq -r '.strengths[]' | sed 's/^/- /')
  
  ### 📈 Areas for Improvement  
  $(echo "$REVIEW_OUTPUT" | jq -r '.improvements[]' | sed 's/^/- /')
  
  ### 💡 Actionable Recommendations
  $(echo "$REVIEW_OUTPUT" | jq -r '.recommendations[]' | sed 's/^/- /')
  
  ---
  *Review insights help improve future iterations. Consider using `/peer --instruction=refine-spec` to address recommendations.*
</review_presentation>

<instructions>
  ACTION: Extract and display review results
  FORMAT: User-friendly presentation with scores and insights
  PROVIDE: Clear next steps based on recommendations
</instructions>

</step>
```

#### Step 11: Finalize PEER Cycle (Unchanged)

Current Step 11 remains as Step 11 with no changes.

Note: By placing the review display as Step 12 (after finalization), the cycle completion is properly recorded before presenting results, and the review output becomes the final user-facing element of the PEER execution.

## Benefits

### Cycle Management Benefits
- Prevents cycle number conflicts
- Provides clear audit trail of cycle progression
- Enables proper cycle history tracking
- Handles edge cases (empty state, corrupted state)

### Review Display Benefits  
- Users receive immediate actionable feedback as the final output
- Quality scores provide quantitative assessment
- Specific improvements guide refinement
- Recommendations enable continuous improvement
- Clear path to refinement via refine-spec instruction

## Testing Requirements

### Cycle Number Tests
1. First cycle creation (should be 1)
2. Sequential cycle creation (should increment)
3. Cycle creation after NATS restart
4. Handling of corrupted current cycle value
5. Prevention of duplicate cycle numbers

### Review Display Tests
1. Display with complete review data
2. Handling of missing review output
3. Formatting of multi-line recommendations
4. Score display with various ranges (0-100)
5. Empty arrays in strengths/improvements

## Migration Considerations

These changes are backward compatible:
- Existing cycles remain unaffected
- New cycles will use improved numbering
- Review display is additive (no breaking changes)

## Dependencies

- Wrapper scripts must properly handle error cases
- NATS KV must be available and responsive
- JQ must be installed for JSON parsing
- Review phase must complete successfully for display