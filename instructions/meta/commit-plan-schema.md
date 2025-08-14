---
description: Commit Plan Schema for Git Operations v1
globs:
alwaysApply: false
version: 1
encoding: UTF-8
---

# Commit Plan Schema for Git Operations

> Version: 1.0 (Initial)
> Created: 2025-08-13
> Purpose: Define standardized structure for git commit planning files

## Cross-References

This schema documentation is referenced by:
- **Main Spec:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/spec.md
- **Technical Specification:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/sub-specs/technical-spec.md
- **Implementation Tasks:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/tasks.md
- **Best Practices:** @.agent-os/product/dev-best-practices.md (XML declarative instruction patterns)

## Overview

This document defines the schema for commit plan files used in Agent OS git operations. Commit plans provide structured guidance for complex git workflows involving user decision points and branching strategies.

## Schema Version Information

- **Version:** 1.0
- **Type:** Initial schema definition
- **Storage:** JSON files in temporary directories
- **Usage:** Pre-commit planning and user guidance

## Field Definitions

### Root Fields

```yaml
version: integer
  Description: Schema version number
  Required: Yes
  Value: 1
  Purpose: Enables future schema evolution

plan_id: string
  Description: Unique identifier for this plan
  Required: Yes
  Format: "{instruction}-{timestamp}"
  Example: "git-commit-20250813T100000Z"

metadata: object
  Description: Plan metadata and context
  Required: Yes
  Purpose: Track plan creation and context

repository: object
  Description: Repository state information
  Required: Yes
  Purpose: Document current git repository state

decisions: array[object]
  Description: User decision points requiring input
  Required: Yes
  Purpose: Guide user through complex workflows

execution_plan: object
  Description: Planned git operations sequence
  Required: Yes
  Purpose: Define step-by-step execution workflow

outcomes: object
  Description: Possible outcomes and consequences
  Required: Yes
  Purpose: Help users understand implications
```

### Metadata Object

```yaml
created_at: string
  Description: ISO 8601 timestamp of plan creation
  Required: Yes
  Format: "YYYY-MM-DDTHH:mm:ssZ"
  Example: "2025-08-13T10:00:00Z"

instruction: string
  Description: Agent OS instruction that created this plan
  Required: Yes
  Example: "git-commit"

spec_context: string
  Description: Associated spec name if applicable
  Required: No
  Example: "user-authentication"

user_intent: string
  Description: Original user requirements or intent
  Required: Yes
  Example: "Commit changes for user auth feature"
```

### Repository Object

```yaml
current_branch: string
  Description: Current git branch name
  Required: Yes
  Example: "feature/user-auth"

main_branch: string
  Description: Main/default branch name
  Required: Yes
  Example: "main"

staged_files: array[string]
  Description: Files currently staged for commit
  Required: Yes
  Example: ["src/auth.go", "tests/auth_test.go"]

unstaged_files: array[string]
  Description: Modified but unstaged files
  Required: Yes
  Example: ["README.md"]

untracked_files: array[string]
  Description: New files not tracked by git
  Required: Yes
  Example: ["config/auth.yaml"]

has_unpushed_commits: boolean
  Description: Whether local branch has commits not pushed
  Required: Yes
  Example: true

ahead_behind: object
  Description: Relationship to remote branch
  Required: Yes
  Structure:
    ahead: integer (commits ahead of remote)
    behind: integer (commits behind remote)
```

### Decision Object

```yaml
decision_id: string
  Description: Unique identifier for this decision
  Required: Yes
  Format: "decision_{sequential_number}"
  Example: "decision_1"

title: string
  Description: Brief title for the decision
  Required: Yes
  Example: "Choose branching strategy"

description: string
  Description: Detailed explanation of what needs to be decided
  Required: Yes
  Example: "You have unpushed commits. Choose how to proceed with the new commit."

options: array[object]
  Description: Available choices for this decision
  Required: Yes
  MinItems: 2
  Structure: See Option Object below

visual_guide: string
  Description: ASCII diagram showing the decision visually
  Required: No
  Example: See visual examples below

consequences: object
  Description: Detailed consequences for each option
  Required: Yes
  Structure: See Consequences Object below
```

### Option Object

```yaml
option_id: string
  Description: Unique identifier for this option
  Required: Yes
  Format: "{action}_{variant}"
  Example: "merge_fast_forward"

label: string
  Description: Human-readable option label
  Required: Yes
  Example: "Merge with fast-forward"

description: string
  Description: What this option does
  Required: Yes
  Example: "Merge your branch directly into main without creating a merge commit"

recommended: boolean
  Description: Whether this is the recommended choice
  Required: Yes
  Example: false

risk_level: string
  Description: Risk assessment for this option
  Required: Yes
  Values: low | medium | high | critical
  Example: "medium"
```

### Consequences Object

```yaml
immediate: array[string]
  Description: What happens immediately after choosing this option
  Required: Yes
  Example: ["Creates merge commit", "All changes become part of main branch"]

future: array[string]
  Description: Future implications of this choice
  Required: Yes
  Example: ["Branch history preserved", "Easy to revert entire feature"]

risks: array[string]
  Description: Potential problems or downsides
  Required: Yes
  Example: ["May create conflicts with other developers", "Harder to isolate bugs"]

benefits: array[string]
  Description: Advantages of this choice
  Required: Yes
  Example: ["Clean linear history", "Simple to understand"]
```

## Complete JSON Example

```json
{
  "version": 1,
  "plan_id": "git-commit-20250813T100000Z",
  "metadata": {
    "created_at": "2025-08-13T10:00:00Z",
    "instruction": "git-commit",
    "spec_context": "user-authentication",
    "user_intent": "Commit user authentication implementation"
  },
  "repository": {
    "current_branch": "feature/user-auth",
    "main_branch": "main",
    "staged_files": ["src/auth.go", "tests/auth_test.go"],
    "unstaged_files": ["README.md"],
    "untracked_files": [],
    "has_unpushed_commits": true,
    "ahead_behind": {
      "ahead": 3,
      "behind": 0
    }
  },
  "decisions": [
    {
      "decision_id": "decision_1",
      "title": "Handle unpushed commits",
      "description": "Your branch has 3 unpushed commits. Choose how to add the new commit.",
      "visual_guide": "Current state:\n  main     ──●──●\n                \\\n  feature       ●──●──●  (unpushed)\n                        \\\n                         ●  (new changes)",
      "options": [
        {
          "option_id": "add_to_branch",
          "label": "Add to current branch",
          "description": "Add new commit to existing branch",
          "recommended": true,
          "risk_level": "low"
        },
        {
          "option_id": "new_branch",
          "label": "Create new branch",
          "description": "Create new branch from current state",
          "recommended": false,
          "risk_level": "medium"
        }
      ],
      "consequences": {
        "add_to_branch": {
          "immediate": ["Commit added to current branch", "Total commits becomes 4"],
          "future": ["All commits pushed together", "Single feature branch"],
          "risks": ["Larger changeset to review"],
          "benefits": ["Simpler workflow", "Related changes grouped"]
        },
        "new_branch": {
          "immediate": ["New branch created", "Current changes isolated"],
          "future": ["Two separate pull requests", "More complex merge process"],
          "risks": ["Potential conflicts between branches", "More complex workflow"],
          "benefits": ["Smaller, focused commits", "Easier to review separately"]
        }
      }
    }
  ],
  "execution_plan": {
    "phases": [
      {
        "phase": "preparation",
        "steps": ["Validate repository state", "Check for conflicts"]
      },
      {
        "phase": "user_interaction",
        "steps": ["Present decisions", "Collect user choices", "Validate selections"]
      },
      {
        "phase": "execution",
        "steps": ["Execute git operations", "Verify results", "Report success"]
      }
    ],
    "estimated_duration": "2-5 minutes"
  },
  "outcomes": {
    "success_criteria": ["All changes committed successfully", "No conflicts introduced", "Repository in clean state"],
    "failure_scenarios": ["Merge conflicts require resolution", "User cancels operation", "Git operation fails"],
    "rollback_available": true
  }
}
```

## Visual Guide Examples

### Branch Visualization

For complex branching decisions, include ASCII diagrams:

```
Option 1: Merge into main
  main     ──●──●──●  (after merge)
              /
  feature  ●──●  (merged)

Option 2: Create new branch
  main     ──●──●
              \
  feature    ●──●  (existing)
              \
  new-branch   ●  (new commit)
```

### Decision Flow Diagrams

For workflow decisions:

```
Current Situation:
┌─────────────────┐
│ Unpushed Commits│
│     Exist       │
└─────────────────┘
         │
         ▼
    ┌─────────┐
    │ Commit  │
    │Options? │
    └─────────┘
     /        \
    ▼          ▼
Add to      Create new
existing       branch
branch          │
   │            ▼
   ▼       More complex
Simple     but isolated
workflow     changes
```

## Usage Examples

### Creating a Plan

```bash
# Generate commit plan
PLAN_ID="git-commit-$(date -u +%Y%m%dT%H%M%SZ)"
PLAN_FILE="/tmp/commit-plan-${PLAN_ID}.json"

# Create plan structure
jq -n --arg plan_id "$PLAN_ID" '{
  version: 1,
  plan_id: $plan_id,
  metadata: {
    created_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    instruction: "git-commit"
  }
}' > "$PLAN_FILE"
```

### Reading Plan Data

```bash
# Read plan from file
PLAN=$(cat "$PLAN_FILE")

# Extract specific decision
DECISION=$(echo "$PLAN" | jq '.decisions[] | select(.decision_id == "decision_1")')

# Get user options
OPTIONS=$(echo "$DECISION" | jq -r '.options[].label')
```

## Schema Requirements

Schema documentation specifies:
1. Schema version field must equal 1
2. All required fields must be present in plan structure
3. Decision IDs must be unique within plan
4. Option IDs must be unique within decision
5. Risk levels must use defined values (low | medium | high | critical)
6. Timestamps must use valid ISO 8601 format
7. Arrays must meet minimum required item counts

## Size Constraints

- **Maximum plan size:** 50KB (no optimization needed)
- **Maximum decisions:** 10 per plan
- **Maximum options:** 5 per decision
- **Visual guides:** Keep under 1000 characters

## File Naming Convention

Commit plan files should follow this pattern:
- **Format:** `commit-plan-{timestamp}.json`
- **Location:** `/tmp/` or similar temporary directory
- **Example:** `/tmp/commit-plan-20250813T100000Z.json`

## Migration Notes

### From No Schema (v0 to v1)

- Add version field to existing plans
- Ensure all required fields are present
- Validate decision and option structures
- Add visual guides where helpful

### Future v2 Considerations

Potential additions:
- Rollback procedures (currently deferred)
- Performance optimizations (not needed for <50KB)
- Enhanced conflict resolution guidance
- Integration with external tools

## Notes

- Plans are temporary files, typically cleaned up after use
- Visual guides enhance user understanding but are optional
- All decision consequences should be clearly explained
- Risk levels help users make informed choices
- Plans under 50KB require no special optimization