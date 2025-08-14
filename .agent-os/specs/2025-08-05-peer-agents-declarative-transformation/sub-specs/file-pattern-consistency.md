# File Pattern Consistency Issue

> Created: 2025-08-08
> Updated: 2025-08-08
> Status: Partially Fixed - Needs Correction
> Priority: High

## Issue Description

There is an inconsistency in the temporary file naming patterns across PEER agents after implementing the file injection pattern.

## Current State

### peer-express.md (Original Reference Pattern)
- **Directory**: `./tmp/peer-express/` (relative path from project root)
- **File naming**: Includes `[CYCLE_NUMBER]` placeholder
  - `express_output_cycle_[CYCLE_NUMBER].json`
  - `cycle_result_cycle_[CYCLE_NUMBER].json`
- **Purpose**: Prevents file conflicts between concurrent cycles

### Other Agents (Recently Updated)
- **peer-planner.md**:
  - Directory: `/tmp/peer-planner` (absolute path)
  - File: `plan_output.json` (static name, no cycle number)
  
- **peer-executor.md**:
  - Directory: `/tmp/peer-executor` (absolute path)
  - File: `execution_output.json` (static name, no cycle number)
  
- **peer-review.md**:
  - Directory: `/tmp/peer-review` (absolute path)
  - Files: `review_output.json`, `insights.json` (static names, no cycle numbers)

## Problems Identified

1. **Path Inconsistency**: Mix of relative (`./tmp/`) and absolute (`/tmp/`) paths
2. **Collision Risk**: Static filenames could cause conflicts if multiple PEER cycles run concurrently
3. **Cleanup Risk**: Static names might get overwritten before cleanup occurs
4. **Portability**: Absolute `/tmp/` paths may not work on all systems

## Recommended Solution

Standardize all PEER agents to use the peer-express.md pattern:

1. Use relative path: `./tmp/peer-[agent]/`
2. Include cycle number in filenames: `[output_type]_cycle_[CYCLE_NUMBER].json`
3. Ensure CYCLE_NUMBER is available in agent context
4. Update cleanup to handle cycle-specific files

## Implementation Requirements

### For Each Agent

1. **Directory Creation**:
   ```
   CREATE_DIR ./tmp/peer-[agent]
   ```

2. **File Naming**:
   ```
   WRITE_TOOL ./tmp/peer-[agent]/[output_type]_cycle_[CYCLE_NUMBER].json
   ```

3. **Variable References**:
   ```bash
   FILE_VAR="./tmp/peer-[agent]/[output_type]_cycle_[CYCLE_NUMBER].json"
   ```

4. **Cleanup**:
   ```bash
   rm -f "${FILE_VAR}"
   ```

## Benefits of Standardization

1. **Concurrency Safety**: Multiple cycles can run without file conflicts
2. **Debugging**: Easy to identify which files belong to which cycle
3. **Audit Trail**: Temporary files can be preserved for troubleshooting if cleanup fails
4. **Consistency**: All agents follow the same pattern

## Testing Requirements

After implementation:
1. Test concurrent PEER cycles to ensure no file conflicts
2. Verify CYCLE_NUMBER is properly substituted in all agents
3. Confirm cleanup removes cycle-specific files
4. Test on different operating systems for path compatibility

## Implementation Error Identified

### Issue Found in Task 15.4.7.5 Implementation

The implementation incorrectly added explicit CYCLE_NUMBER extraction:
```bash
# INCORRECT - Added by mistake
CYCLE_NUMBER=$(echo "$current_state" | jq -r '.metadata.cycle_number')
```

### Correct Pattern (from peer-express.md)

The peer-express.md agent demonstrates the correct pattern:
1. **No explicit extraction** - CYCLE_NUMBER should already be in agent context
2. **Use as placeholder** - Write `[CYCLE_NUMBER]` in WRITE_TOOL commands
3. **Direct substitution** - The value should be substituted by the agent runtime

### Why This Matters

- **Context Assumption**: CYCLE_NUMBER is passed by peer.md when invoking agents
- **Redundancy**: Extracting from state when it's already available is unnecessary
- **Consistency**: All agents should follow the same pattern as peer-express.md

### Required Corrections

1. Remove all explicit CYCLE_NUMBER extraction lines
2. Use `[CYCLE_NUMBER]` as a direct placeholder
3. Trust that the value is available in execution context
4. Follow peer-express.md pattern exactly