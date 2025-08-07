---
description: Unified State Schema for PEER Pattern v1
globs:
alwaysApply: false
version: 1
encoding: UTF-8
---

# Unified State Schema for PEER Pattern

> Version: 1 (Simplified, no locking)
> Created: 2025-08-06
> Purpose: Define unified state structure for PEER cycles

## Overview

This document defines the single source of truth for the unified state structure used in PEER pattern execution. All PEER components (peer.md and peer agents) must reference and follow this schema.

## Schema Version Information

- **Version:** 1
- **Type:** Simplified (no optimistic locking)
- **Storage:** Single NATS KV entry per cycle
- **Key Pattern:** `[KEY_PREFIX].cycle.[CYCLE_NUMBER]`

## Field Definitions

### Root Fields

```yaml
version: integer
  Description: Schema version number
  Required: Yes
  Value: 1
  Purpose: Enables future schema evolution

cycle_id: string
  Description: Unique identifier matching the KV key
  Required: Yes
  Format: "[KEY_PREFIX].cycle.[CYCLE_NUMBER]"
  Example: "peer.spec.user-auth.cycle.1"

metadata: object
  Description: Core cycle information
  Required: Yes
  Purpose: Track cycle lifecycle and identification

context: object
  Description: Execution context from initial request
  Required: Yes
  Purpose: Preserve original user input and configuration

phases: object
  Description: Phase-specific data for plan, execute, express, review
  Required: Yes
  Purpose: Store phase outputs and status
```

### Metadata Object

```yaml
instruction_name: string
  Description: Name of Agent OS instruction being executed
  Required: Yes
  Example: "create-spec"

spec_name: string
  Description: Spec name for spec-aware instructions
  Required: No (only for spec-aware instructions)
  Example: "user-authentication"

key_prefix: string
  Description: NATS KV key prefix for this cycle
  Required: Yes
  Format: "peer.spec.[SPEC_NAME]" or "peer.global"
  Example: "peer.spec.user-auth"

cycle_number: integer
  Description: Sequential cycle number
  Required: Yes
  Example: 1

created_at: string
  Description: ISO 8601 timestamp of cycle creation
  Required: Yes
  Format: "YYYY-MM-DDTHH:mm:ssZ"
  Example: "2025-08-06T10:00:00Z"

updated_at: string
  Description: ISO 8601 timestamp of last update
  Required: Yes
  Format: "YYYY-MM-DDTHH:mm:ssZ"
  Example: "2025-08-06T10:15:00Z"

status: string
  Description: Current cycle status
  Required: Yes
  Values: INITIALIZED | PLANNING | EXECUTING | EXPRESSING | REVIEWING | COMPLETED | FAILED
  Example: "EXECUTING"

current_phase: string
  Description: Currently active phase
  Required: Yes
  Values: plan | execute | express | review
  Example: "execute"
```

### Context Object

```yaml
peer_mode: string
  Description: Execution mode
  Required: Yes
  Values: new | continue
  Example: "new"

spec_aware: boolean
  Description: Whether instruction is spec-aware
  Required: Yes
  Example: true

user_requirements: string
  Description: Original user input/requirements
  Required: Yes
  Example: "Create a spec for user authentication with OAuth2"
```

### Phases Object

Each phase (plan, execute, express, review) contains:

```yaml
status: string
  Description: Phase completion status
  Required: Yes
  Values: pending | in_progress | completed | failed
  Example: "completed"

started_at: string
  Description: ISO 8601 timestamp when phase started
  Required: No (only when status != pending)
  Format: "YYYY-MM-DDTHH:mm:ssZ"
  Example: "2025-08-06T10:00:00Z"

completed_at: string
  Description: ISO 8601 timestamp when phase completed
  Required: No (only when status == completed)
  Format: "YYYY-MM-DDTHH:mm:ssZ"
  Example: "2025-08-06T10:05:00Z"

output: object
  Description: Phase-specific output data
  Required: No (only after phase executes)
  Structure: Varies by phase
  Example: See phase-specific examples below

error: string
  Description: Error message if phase failed
  Required: No (only when status == failed)
  Example: "Failed to access instruction file"
```

## Complete JSON Example

```json
{
  "version": 1,
  "cycle_id": "peer.spec.user-auth.cycle.1",
  "metadata": {
    "instruction_name": "create-spec",
    "spec_name": "user-auth",
    "key_prefix": "peer.spec.user-auth",
    "cycle_number": 1,
    "created_at": "2025-08-06T10:00:00Z",
    "updated_at": "2025-08-06T10:15:00Z",
    "status": "EXECUTING",
    "current_phase": "execute"
  },
  "context": {
    "peer_mode": "new",
    "spec_aware": true,
    "user_requirements": "Create a spec for user authentication with OAuth2 support"
  },
  "phases": {
    "plan": {
      "status": "completed",
      "started_at": "2025-08-06T10:00:00Z",
      "completed_at": "2025-08-06T10:05:00Z",
      "output": {
        "instruction_type": "spec-aware",
        "phases": ["preparation", "execution", "finalization"],
        "success_criteria": "Spec documentation created and validated",
        "estimated_duration": 300000
      }
    },
    "execute": {
      "status": "in_progress",
      "started_at": "2025-08-06T10:05:00Z",
      "output": {
        "progress": "Creating spec files",
        "files_created": [".agent-os/specs/2025-08-06-user-auth/spec.md"],
        "current_step": 3,
        "total_steps": 7
      }
    },
    "express": {
      "status": "pending"
    },
    "review": {
      "status": "pending"
    }
  }
}
```

## Usage Examples

### Reading State

```bash
# Read the unified state from NATS KV
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw)

# Parse specific fields with jq
CURRENT_PHASE=$(echo "$STATE" | jq -r '.metadata.current_phase')
PLAN_STATUS=$(echo "$STATE" | jq -r '.phases.plan.status')
```

### Writing State (Simple Pattern for v1)

```bash
# 1. Read current state
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw)

# 2. Modify only your phase (example for planner)
UPDATED_STATE=$(echo "$STATE" | jq '
  .phases.plan.status = "completed" |
  .phases.plan.completed_at = (now | todate) |
  .phases.plan.output = {
    "instruction_type": "spec-aware",
    "success_criteria": "Spec created"
  } |
  .metadata.updated_at = (now | todate)
')

# 3. Write back full state (no sequence check in v1)
echo "$UPDATED_STATE" | nats kv put agent-os-peer-state "$STATE_KEY"
```

## Phase Ownership Rules

**CRITICAL:** Each agent must ONLY modify its designated phase section:

- **peer-planner:** Only updates `phases.plan`
- **peer-executor:** Only updates `phases.execute`
- **peer-express:** Only updates `phases.express`
- **peer-review:** Only updates `phases.review`
- **peer.md:** Updates `metadata` fields and creates initial state

Agents must:
1. Read the complete state object
2. Modify only their phase section
3. Preserve all other fields unchanged
4. Write back the complete state

## Field Constraints

### Required Fields for New Cycle

When creating a new cycle, peer.md must initialize:
- All root fields (version, cycle_id, metadata, context, phases)
- All metadata fields except spec_name (if not spec-aware)
- All context fields
- All phase objects with `status: "pending"`

### Phase Output Structure

Each phase defines its own output structure:

**Plan Output:**
```json
{
  "instruction_type": "string",
  "phases": ["array", "of", "phases"],
  "success_criteria": "string",
  "estimated_duration": "number (ms)",
  "risks": ["optional", "array"]
}
```

**Execute Output:**
```json
{
  "progress": "string description",
  "files_created": ["array", "of", "paths"],
  "files_modified": ["array", "of", "paths"],
  "current_step": "number",
  "total_steps": "number",
  "results": "object (instruction-specific)"
}
```

**Express Output:**
```json
{
  "summary": "string",
  "key_achievements": ["array", "of", "strings"],
  "deliverables": ["array", "of", "strings"],
  "formatted_output": "string (markdown)"
}
```

**Review Output:**
```json
{
  "quality_score": "number (0-100)",
  "strengths": ["array", "of", "strings"],
  "improvements": ["array", "of", "strings"],
  "recommendations": ["array", "of", "strings"],
  "insights": "string"
}
```

## Important Exclusions for v1

The following fields are **NOT** included in v1:
- ❌ `sequence` - No optimistic locking
- ❌ `sequence_at_start` - No locking verification
- ❌ `sequence_at_complete` - No locking tracking
- ❌ `history` - No change history array
- ❌ `retry_count` - No retry tracking
- ❌ `lock_holder` - No locking mechanism

## Migration to v2

Future v2 additions may include:
- Sequence numbers for optimistic locking
- History array for change tracking
- Retry mechanisms with backoff
- Performance metrics
- Enhanced error handling

## Validation

Agents should validate:
1. Schema version equals 1
2. Required fields are present
3. Field types match specification
4. Status values are valid
5. Timestamps are valid ISO 8601
6. Key prefix uses `.` delimiter (not `:`)

## Notes

- All timestamps must be ISO 8601 format with timezone
- All keys must use `.` delimiter for NATS compatibility
- State size should be monitored (NATS KV typical limit ~1MB)
- For large outputs, consider storing references instead of full data