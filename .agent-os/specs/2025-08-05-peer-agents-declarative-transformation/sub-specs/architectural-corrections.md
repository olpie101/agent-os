# Architectural Corrections

> Created: 2025-08-08
> Status: Design Complete
> Priority: High

## Overview

This document details two critical architectural issues discovered in the PEER pattern implementation and their correction strategy. Since backwards compatibility is not a concern, we can implement clean architectural fixes.

## Issue 1: Express Phase Ownership Violation

### Problem Description

The Express phase (peer-express.md) violates the phase ownership principle by writing to the root level of the unified state:

```bash
# Line 439 in peer-express.md
JQ_FILTER='
  .metadata.status = "REVIEWING" |
  .metadata.current_phase = "review" |
  .metadata.updated_at = (now | todate) |
  .phases.express.status = "completed" |
  .phases.express.completed_at = (now | todate) |
  .phases.express.output = $express_out[0] |
  .result = $cycle_result[0]  # VIOLATION: Writing to root level
'
```

### Architectural Impact

- **Violation**: Breaks the principle that each phase only modifies `phases.<phase_name>.*`
- **Duplication**: The same information exists in `phases.express.output`
- **Precedent**: Sets bad example for other phases
- **Technical Debt**: Creates confusion about authoritative data location

### Solution: Replace with cycle_summary

Remove the `result` field entirely and introduce a proper `cycle_summary` field owned by the Review phase:

1. **Remove from Express**: Delete line adding `.result = $cycle_result[0]`
2. **Update Schema**: Replace `result` with `cycle_summary` in unified state schema
3. **Assign to Review**: Have Review phase create the cycle summary from all phase outputs

## Issue 2: Hidden Insights Problem

### Problem Description

The Review phase generates valuable insights that are never displayed to users. From actual cycle data:

```json
"insights": {
  "questions_for_user": [
    "Would you prefer more detailed code examples in technical specifications?",
    "Should future spec refinements include alternative solution approaches?"
  ],
  "recommendations": {
    "process": ["Include code example requirements in refine-spec planning"],
    "technical": ["Develop pattern for exposing configuration parameters"],
    "efficiency": ["Build library of common technical limitation patterns"]
  },
  "learnings": ["Template configuration limitations are common issues"]
}
```

### User Impact

- **Broken Feedback Loop**: Questions requiring answers are never shown
- **Missed Improvements**: Valuable recommendations remain hidden
- **Lost Learning**: Patterns and insights not surfaced for future cycles

### Solution: Enhanced Display in peer.md

Update peer.md Step 12 to display both review output AND insights:

```markdown
## 📋 PEER Review Results

### Quality Assessment
[existing review.output display]

### ❓ Questions Requiring Your Input
**[HIGH VISIBILITY]**
- Question 1
- Question 2

### 💡 Recommendations
**Process Improvements:**
- Item 1

**Technical Suggestions:**
- Item 1

### 📚 Learnings from This Cycle
- Pattern 1
```

## Schema Evolution

### Current State (v1 with violation)

```yaml
root:
  result: string  # VIOLATION - added by Express phase
  version: 1
  cycle_id: string
  metadata: object
  context: object
  phases: object
  insights: object  # Created by Review but never shown
```

### Target State (v1.1 corrected)

```yaml
root:
  cycle_summary: object  # NEW - owned by Review phase
    success: boolean
    instruction: string
    summary: string
    highlights: array[string]
    completion: number
    next_action: string
  version: 1
  cycle_id: string
  metadata: object
  context: object
  phases: object
  insights: object  # Will be displayed to users
```

## Implementation Strategy

### Phase 1: Fix Express Violation

1. Remove `.result = $cycle_result[0]` from peer-express.md Step 8
2. Ensure all cycle result data is in `phases.express.output`

### Phase 2: Add cycle_summary to Review

1. Update peer-review.md to create `cycle_summary` from all phase outputs
2. Include key information from express, execute, and review phases
3. Ensure cycle_summary provides complete cycle overview

### Phase 3: Update Schema

1. Update unified_state_schema.md to remove `result` field
2. Add `cycle_summary` field with proper structure
3. Document ownership by Review phase

### Phase 4: Display Insights

1. Update peer.md Step 12 to display insights
2. Give special prominence to `questions_for_user`
3. Format recommendations and learnings clearly

## User Preferences from Cycle 3 Feedback

Based on answers to previously hidden questions:

1. **Code Examples**: Include minimum required to convey requirements
2. **Alternative Solutions**: Present alternatives with recommended choice and rationale
3. **Template Issues**: Address in specific project context, not generically

## Success Criteria

- [ ] Express phase only writes to `phases.express.*`
- [ ] Review phase creates proper `cycle_summary`
- [ ] Schema updated to reflect correct structure
- [ ] Insights displayed prominently to users
- [ ] Questions for user highlighted for response
- [ ] No root-level fields modified by non-coordinator components

## Notes

- Since backwards compatibility is not a concern, we can make clean corrections
- The `cycle_summary` provides better structure than the simple `result` string
- Displaying insights closes the feedback loop and improves continuous improvement
- Alternative solution approaches should be presented at cycle end for user review