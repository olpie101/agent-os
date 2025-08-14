# CYCLE_NUMBER Context Passing

> Created: 2025-08-08
> Status: Investigation Required
> Priority: High

## Issue Description

The PEER agents need access to CYCLE_NUMBER for creating unique temporary files, but the mechanism for passing this value from peer.md to the agents needs clarification.

## Current Understanding

### peer-express.md Pattern (Reference Implementation)

1. **Line 11**: States files are stored at `[KEY_PREFIX].cycle.[CYCLE_NUMBER]`
2. **Line 36**: Lists `metadata.cycle_number` as a required input field
3. **File operations**: Uses `[CYCLE_NUMBER]` as a placeholder token
4. **No extraction**: Does NOT extract CYCLE_NUMBER from state

### Implied Contract

- CYCLE_NUMBER should be available in agent execution context
- It's passed by peer.md when invoking the agent
- Agents should use it as a pre-existing variable/placeholder

## Investigation Required

### How peer.md Should Pass CYCLE_NUMBER

Need to verify how peer.md makes CYCLE_NUMBER available to agents:

1. **Environment Variable**: `export CYCLE_NUMBER=...` before agent invocation?
2. **Agent Parameter**: Passed as part of the agent invocation request?
3. **Placeholder Substitution**: Runtime replacement of `[CYCLE_NUMBER]` tokens?
4. **Context Object**: Part of a larger context structure?

### Current peer.md Implementation

Check peer.md Steps 7-10 where agents are invoked:
- How is STATE_KEY passed?
- Is CYCLE_NUMBER passed similarly?
- What's the mechanism for making context available?

## Correct Implementation Pattern

Based on peer-express.md, the pattern should be:

```bash
# In agent files - use as placeholder
WRITE_TOOL ./tmp/peer-agent/output_cycle_[CYCLE_NUMBER].json

# In bash variables - use as variable
FILE_PATH="./tmp/peer-agent/output_cycle_${CYCLE_NUMBER}.json"
# OR
FILE_PATH="./tmp/peer-agent/output_cycle_[CYCLE_NUMBER].json"

# NO extraction needed
# NOT: CYCLE_NUMBER=$(echo "$current_state" | jq -r '.metadata.cycle_number')
```

## Required Actions

1. **Investigate**: How peer.md passes context to agents
2. **Document**: The exact mechanism for CYCLE_NUMBER availability
3. **Standardize**: Ensure all agents follow the same pattern
4. **Test**: Verify placeholders are replaced at runtime

## Impact

Without proper CYCLE_NUMBER passing:
- File naming might fail
- Concurrent cycles could conflict
- Debugging would be difficult

## Notes

- The incorrect extraction added in task 15.4.7.5 might actually work as a workaround
- But it's not the intended pattern and adds unnecessary complexity
- The correct solution requires understanding how peer.md provides context