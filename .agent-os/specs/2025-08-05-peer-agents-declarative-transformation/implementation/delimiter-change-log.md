# NATS KV Key Delimiter Change Log

> Created: 2025-08-06
> Task: Phase 1.1-1.9 of peer-agents-declarative-transformation spec

## Overview

Changed all NATS KV key delimiters from `:` (colon) to `.` (dot) to ensure compatibility with NATS KV operations.

## Why This Change

NATS KV requires `.` as the delimiter for valid keys. Using `:` would cause NATS operations to fail or behave unexpectedly.

## Files Modified

### Primary Instruction File
- `/instructions/core/peer.md`
  - Changed KEY_PREFIX patterns from `peer:spec:[SPEC_NAME]` to `peer.spec.[SPEC_NAME]`
  - Changed KEY_PREFIX patterns from `peer:global` to `peer.global`
  - Updated all cycle key patterns from `[KEY_PREFIX]:cycle:*` to `[KEY_PREFIX].cycle.*`
  - Fixed 11 distinct patterns across the file

### Peer Agent Files
- `/claude-code/agents/peer-planner.md`
  - Changed cycle_id format in event messages

## Key Pattern Changes

### Before
```
peer:spec:[SPEC_NAME]
peer:global
[KEY_PREFIX]:cycle:current
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:metadata
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:plan
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:execution
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:express
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:review
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:status
[KEY_PREFIX]:cycle:[CYCLE_NUMBER]:completed_at
```

### After
```
peer.spec.[SPEC_NAME]
peer.global
[KEY_PREFIX].cycle.current
[KEY_PREFIX].cycle.[CYCLE_NUMBER].metadata
[KEY_PREFIX].cycle.[CYCLE_NUMBER].plan
[KEY_PREFIX].cycle.[CYCLE_NUMBER].execution
[KEY_PREFIX].cycle.[CYCLE_NUMBER].express
[KEY_PREFIX].cycle.[CYCLE_NUMBER].review
[KEY_PREFIX].cycle.[CYCLE_NUMBER].status
[KEY_PREFIX].cycle.[CYCLE_NUMBER].completed_at
```

## Verification

Verified no remaining `:` delimiters in critical NATS KV key patterns:
- No occurrences of `peer:spec:` or `peer:global` in instruction files
- No occurrences of `[KEY_PREFIX]:` in main instruction files
- Spec documentation files still contain references but these are for documentation only

## Impact

This change ensures all NATS KV operations will work correctly with the simplified v1 implementation of the PEER pattern unified state model.