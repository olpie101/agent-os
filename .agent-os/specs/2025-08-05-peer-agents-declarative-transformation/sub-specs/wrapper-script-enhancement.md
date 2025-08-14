# Wrapper Script Enhancement Specification

> Parent Spec: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/spec.md
> Created: 2025-08-07
> Purpose: Fix peer-express JSON handling issues through hybrid approach with file injection
> Status: Design Phase (Updated with Expert Consensus)

## Problem Statement

The peer-express agent experiences failures when updating NATS KV state due to:

1. **Complex JSON Escaping**: Multi-line formatted markdown with special characters causes shell escaping issues
2. **Wrapper Limitations**: Current `update-state.sh` only accepts two positional arguments (KEY, JQ_FILTER)
3. **Workaround Fragility**: Agent bypasses wrapper to use `jq --argjson` directly, losing safety features
4. **Output Truncation**: Agent arbitrarily limits arrays to 3 items when it should preserve all content

## Solution Design: Standardized File-Injection Approach

### Enhanced update-state.sh Wrapper

The wrapper will use a single, standardized approach for JSON handling via file injection:

#### Standard Command Syntax

```bash
# Standard usage with optional file injection
update-state.sh <KEY> <JQ_FILTER> [--json-file <var_name>=<file_path> ...]
```

The wrapper accepts:
- `KEY`: NATS KV key to update (required)
- `JQ_FILTER`: JQ transformation to apply (required)
- `--json-file`: Optional flags for injecting complex JSON from files

#### Standardized Features

1. **File-Based Variable Injection**: 
   ```bash
   # The JQ_FILTER references variables, --json-file provides them
   update-state.sh "$STATE_KEY" \
     '.phases.express.output = $expr_out | .result = $cycle_res' \
     --json-file "expr_out=/tmp/peer-express/express_output.json" \
     --json-file "cycle_res=/tmp/peer-express/cycle_result.json"
   ```

2. **Validation Before Injection**:
   - Verify file exists before attempting to load
   - Validate JSON syntax in file
   - Report clear errors for missing or invalid files

3. **Uses JQ's Native --slurpfile**:
   - Leverages jq's built-in capability for safe JSON loading
   - No manual escaping or JSON parsing in bash
   - Variables become arrays (use `$var[0]` in filter if single object expected)

4. **Clear Separation of Concerns**:
   - Caller provides transformation logic (JQ filter)
   - Wrapper provides file loading context
   - JQ handles all JSON transformation

### Implementation Approach

#### 1. Wrapper Script Enhancement

```bash
#!/bin/bash
# update-state.sh - Enhanced wrapper for updating NATS KV state

STATE_KEY="$1"
JQ_FILTER="$2"
shift 2

if [ -z "$STATE_KEY" ] || [ -z "$JQ_FILTER" ]; then
    echo "ERROR: STATE_KEY and JQ_FILTER are required" >&2
    echo "Usage: ./update-state.sh <STATE_KEY> <JQ_FILTER> [--json-file var=file ...]" >&2
    exit 1
fi

# Parse optional --json-file arguments
JQ_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json-file)
            if [ -z "$2" ]; then
                echo "ERROR: --json-file requires var_name=file_path argument" >&2
                exit 1
            fi
            
            # Split var_name=file_path
            VAR_NAME="${2%%=*}"
            FILE_PATH="${2#*=}"
            
            # Validate var name (alphanumeric and underscore only)
            if ! [[ "$VAR_NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                echo "ERROR: Invalid variable name: $VAR_NAME" >&2
                echo "Variable names must start with letter/underscore and contain only alphanumeric/underscore" >&2
                exit 1
            fi
            
            # Validate file exists
            if [ ! -f "$FILE_PATH" ]; then
                echo "ERROR: File not found: $FILE_PATH" >&2
                exit 1
            fi
            
            # Validate JSON syntax
            if ! jq empty < "$FILE_PATH" 2>/dev/null; then
                echo "ERROR: Invalid JSON in file: $FILE_PATH" >&2
                exit 1
            fi
            
            # Add to jq arguments using --slurpfile
            JQ_ARGS+=(--slurpfile "$VAR_NAME" "$FILE_PATH")
            shift 2
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            echo "Usage: ./update-state.sh <STATE_KEY> <JQ_FILTER> [--json-file var=file ...]" >&2
            exit 1
            ;;
    esac
done

# Rest of the script remains the same...
# Read state, apply filter with slurped files, update with revision check
# The main jq command will be:
# echo "$STATE" | jq "${JQ_ARGS[@]}" "$JQ_FILTER"
```

#### 2. peer-express.md Updates

The agent MUST use this standardized approach:

```bash
# Standardized file-injection approach
# Step 1: Prepare output files
mkdir -p /tmp/peer-express
echo "$EXPRESS_OUTPUT" > /tmp/peer-express/express_output.json
echo "$CYCLE_RESULT" > /tmp/peer-express/cycle_result.json

# Step 2: Validate JSON files
jq empty < /tmp/peer-express/express_output.json || exit 1
jq empty < /tmp/peer-express/cycle_result.json || exit 1

# Step 3: Use standardized update with file injection
# Note: --slurpfile creates arrays, so use $var[0] to access single object
~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" \
  '.metadata.status = "EXPRESSING" |
   .metadata.current_phase = "express" |
   .metadata.updated_at = (now | todate) |
   .phases.express.status = "completed" |
   .phases.express.completed_at = (now | todate) |
   .phases.express.output = $expr_out[0] |
   .result = $cycle_res[0]' \
  --json-file "expr_out=/tmp/peer-express/express_output.json" \
  --json-file "cycle_res=/tmp/peer-express/cycle_result.json"

# Step 4: Cleanup
rm -rf /tmp/peer-express
```

### Output Structure Requirements

#### No Truncation Policy

The peer-express agent MUST:
1. Include ALL items in arrays (no limiting to 3)
2. Preserve complete information from execution phase
3. Match the count of items between similar fields (e.g., `key_points` and `highlights`)

#### Structured Data Only

The `phases.express.output` should contain:
```json
{
  "summary": "string",
  "key_points": ["array", "of", "all", "points"],
  "deliverables": {
    "files_modified": "number",
    "tasks_enhanced": "number",
    "other_metrics": "number"
  },
  "completion_percentage": 100,
  "instruction_type": "string"
}
```

NO pre-formatted markdown in state. Display formatting happens when reading state, not storing it.

### Testing Strategy

1. **Unit Tests for Wrapper**:
   - Test standard mode with no --json-file flags (basic usage)
   - Test --json-file with valid files
   - Test --json-file with missing files (error handling)
   - Test --json-file with malformed JSON (validation)
   - Test invalid variable names (validation)
   - Test multiple --json-file arguments
   - Test --slurpfile array access with $var[0]

2. **Integration Tests**:
   - Run peer-express with hybrid commands
   - Verify no truncation in output arrays
   - Verify state updates correctly with file injection
   - Verify revision checking still works
   - Test other agents continue working unchanged

3. **Error Scenarios**:
   - Corrupted JSON in file
   - Missing temporary files
   - Invalid variable names
   - Concurrent updates
   - Large JSON files (>1MB)
   - Empty JSON files

### Migration Plan

1. **Phase 1**: Implement wrapper enhancement with --json-file support
2. **Phase 2**: Test with direct KV test entries (both legacy and hybrid modes)
3. **Phase 3**: Update peer-express.md to use hybrid approach
4. **Phase 4**: Test full PEER cycle with complex JSON
5. **Phase 5**: Document hybrid pattern usage

### Success Criteria

- [ ] peer-express completes without errors
- [ ] No more shell escaping issues with complex JSON
- [ ] All output arrays contain full content (no truncation)
- [ ] Legacy mode works unchanged for other agents
- [ ] File validation prevents bad data injection
- [ ] Temporary files are properly cleaned up
- [ ] Clear error messages for missing/invalid files

### Risk Mitigation

1. **Backward Compatibility**: Legacy mode (positional args only) remains default
2. **File Validation**: Check existence and JSON syntax before injection
3. **Variable Name Validation**: Enforce valid jq variable naming rules
4. **Large Files**: Validate file size and warn if >1MB
5. **Concurrent Access**: Use unique subdirectories per cycle in /tmp
6. **Array Access**: Document that --slurpfile creates arrays (use $var[0])

### Documentation Updates

1. **nats-kv-operations.md**: Add --json-file usage section with examples
2. **peer-express.md**: Update to use hybrid approach with file injection
3. **troubleshooting.md**: Add section on:
   - File not found errors
   - Invalid JSON errors
   - Variable name restrictions
   - Array access with --slurpfile