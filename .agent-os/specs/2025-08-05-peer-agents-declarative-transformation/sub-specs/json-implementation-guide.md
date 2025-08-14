# JSON Implementation Guide for PEER Agents

> Parent Spec: @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/spec.md
> Created: 2025-08-07
> Purpose: Implementation details and troubleshooting for JSON creation standard
> Status: Active

## Problem Background

The peer-express agent was experiencing failures due to:
1. Appending "EOF < /dev/null" to JSON strings
2. Shell escaping issues with complex markdown content
3. Improper handling of special characters in JSON values
4. Confusion between declarative instructions and bash execution
5. Control character errors from direct multi-line variable assignment

## Critical Note on Multi-line Content

**IMPORTANT**: The json-creation-standards.md file MUST provide examples of how to handle multi-line/markdown content. Direct assignment of multi-line content to bash variables introduces control characters that cause JSON parsing errors, even when using --arg.

## Implementation Examples

### Complex Content Handling

#### Multi-line Markdown

**Agent Action (First):**
```
Write "/tmp/markdown_content.txt" with content:
### Summary
- Item with "quotes"
- Path: /usr/bin/test
- Command: `echo $VAR`
- Special chars: \ / $ { } [ ]
```

**Bash Script (After file is created):**
```bash
# File already created by Write tool
# Read file content into variable
MARKDOWN_CONTENT=$(<"/tmp/markdown_content.txt")

# Now jq can handle it without control character errors
JSON=$(jq -n --arg content "$MARKDOWN_CONTENT" '{
  report: $content,
  format: "markdown"
}')

# Clean up
rm -f "/tmp/markdown_content.txt"
```

**WRONG Approach:**
```bash
# Direct assignment causes control character issues
MARKDOWN_CONTENT='### Summary
- Item with "quotes"
- Special chars: \ / $ { } [ ]'
# This introduces control characters!
```

#### Building Arrays
```bash
# Array of items with special characters
ITEMS=("item 1" "item with \"quotes\"" "item with \$pecial chars")

# Convert bash array to JSON array
JSON=$(printf '%s\n' "${ITEMS[@]}" | jq -R . | jq -s '{items: .}')

# Or inline with jq
JSON=$(jq -n \
  --arg item1 "${ITEMS[0]}" \
  --arg item2 "${ITEMS[1]}" \
  --arg item3 "${ITEMS[2]}" \
  '{items: [$item1, $item2, $item3]}')
```

#### Nested Structures

**Agent Action (First):**
```
Write "/tmp/details.md" with content:
## Details
- All tests passed  
- No errors found
```

**Bash Script (After file is created):**
```bash
# Simple single-line strings are OK
SUMMARY="Task completed successfully"
COUNT=42
SUCCESS=true

# Read the multi-line content from file created by Write tool
MARKDOWN=$(<"/tmp/details.md")

JSON=$(jq -n \
  --arg summary "$SUMMARY" \
  --arg details "$MARKDOWN" \
  --argjson count "$COUNT" \
  --argjson success "$SUCCESS" \
  '{
    status: {
      message: $summary,
      success: $success
    },
    report: {
      format: "markdown",
      content: $details,
      item_count: $count
    },
    timestamp: (now | todate)
  }')

# Clean up
rm -f "/tmp/details.md"
```

**WRONG Approach:**
```bash
# Multi-line string in variable causes control character issues
MARKDOWN="## Details\n- All tests passed\n- No errors found"
```

## Integration with Wrapper Scripts

### File Injection Pattern

**Agent Actions (First):**
```
1. Write "/tmp/markdown.txt" with content:
   ## Detailed Report
   - Item 1 completed
   - Item 2 in progress

2. Execute bash script below
```

**Bash Script (After files are created):**
```bash
# Read multi-line content from file created by Write tool
MARKDOWN_CONTENT=$(<"/tmp/markdown.txt")

# Build complex JSON using jq (with properly loaded content)
EXPRESS_JSON=$(jq -n \
  --arg summary "$SUMMARY_TEXT" \
  --arg markdown "$MARKDOWN_CONTENT" \
  --argjson items "$ITEM_COUNT" \
  '{
    summary: $summary,
    details: $markdown,
    item_count: $items,
    timestamp: (now | todate)
  }')

# Validate JSON
echo "$EXPRESS_JSON" | jq empty || exit 1

# Write JSON to file for wrapper injection
echo "$EXPRESS_JSON" > /tmp/express.json

# Use with wrapper's file injection
~/.agent-os/scripts/peer/update-state.sh "$KEY" \
  '.phases.express.output = $expr[0]' \
  --json-file "expr=/tmp/express.json"

# Clean up
rm -f /tmp/express.json /tmp/markdown.txt
```

## Declarative Instruction Interpretation

When interpreting declarative instructions like:
```xml
<create_express_output>
  SET express_output = {
    "summary": "...",
    "key_points": [...]
  }
</create_express_output>
```

### Implementation Steps:
```bash
# Step 1: Extract values from context
SUMMARY="Successfully refined spec"
INSTRUCTION="refine-spec"

# Step 2: Build JSON using jq
EXPRESS_OUTPUT=$(jq -n \
  --arg sum "$SUMMARY" \
  --arg inst "$INSTRUCTION" \
  --argjson complete 100 \
  '{
    summary: $sum,
    instruction_type: $inst,
    completion_percentage: $complete
  }')

# Step 3: Validate before writing
echo "$EXPRESS_OUTPUT" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Generated invalid JSON" >&2
  exit 1
fi

# Step 4: Write to file (if needed)
echo "$EXPRESS_OUTPUT" > "$EXPRESS_FILE"
```

## Multi-line Markdown Content Pattern

For the express agent's formatted output:

**CRITICAL:** Never assign multi-line content directly to variables! This causes control character errors (U+0000 through U+001F).

**Agent Actions (First):**
```
Write "/tmp/formatted.txt" with content:
## Summary
Successfully completed task

## Key Accomplishments  
- Achievement 1
- Achievement 2
```

**Bash Script (After file is created):**
```bash
# Read file content into variable (now safe from control characters)
FORMATTED_CONTENT=$(<"/tmp/formatted.txt")

# Use --arg with the variable (NOT --rawfile)
EXPRESS_OUTPUT=$(jq -n \
  --arg formatted "$FORMATTED_CONTENT" \
  '{formatted_output: $formatted}')

# Clean up
rm -f "/tmp/formatted.txt"
```

**WRONG Approaches:**
```bash
# 1. Direct variable assignment with multi-line content
FORMATTED_OUTPUT="## Summary
Multi-line content..."  # This introduces control characters!

# 2. Using --rawfile (not in approved standard)
EXPRESS_OUTPUT=$(jq -n \
  --rawfile formatted "/tmp/formatted.txt" \
  '{formatted_output: $formatted}')
```

### Why --rawfile is Wrong

1. `--rawfile` is not in the approved standard
2. It may handle newlines differently than --arg  
3. It bypasses our standardized escaping mechanism
4. It can cause control character errors with complex markdown content

### Why Direct Variable Assignment is Wrong

1. **Control Character Issues**: Multi-line content in bash variables can contain control characters (U+0000 through U+001F) that cause JSON parsing errors
2. **Shell Escaping Problems**: Bash variables don't properly escape quotes, backslashes, and special characters for JSON
3. **Brittle with echo**: Using `echo "$VARIABLE" > file` doesn't handle special characters reliably

## Debugging and Troubleshooting

### Common Issues to Check

1. **Trailing text**: Look for "EOF", "< /dev/null", or other suffixes
2. **Missing quotes**: Ensure all strings are properly quoted
3. **Trailing commas**: Remove commas after last element
4. **Unescaped characters**: Check for unescaped quotes or backslashes

### Debug Commands
```bash
# Show exact bytes including hidden characters
echo "$JSON_VARIABLE" | od -c

# Validate and show error location
echo "$JSON_VARIABLE" | jq empty

# Pretty-print if valid
echo "$JSON_VARIABLE" | jq .
```

### Validation Patterns

#### Before Writing to Files
```bash
# ALWAYS validate before writing
echo "$JSON_VARIABLE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Invalid JSON detected" >&2
  echo "JSON content: $JSON_VARIABLE" >&2
  exit 1
fi
```

#### After Reading from Files
```bash
# Validate after reading
JSON_CONTENT=$(cat "$JSON_FILE")
echo "$JSON_CONTENT" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: File contains invalid JSON: $JSON_FILE" >&2
  exit 1
fi
```

## Testing Requirements

Test JSON creation with:
1. Empty objects and arrays
2. Special characters in strings (quotes, backslashes, newlines)
3. Large nested structures
4. Unicode characters
5. Very long strings (>1MB)
6. Numeric values (integers and floats)
7. Boolean values
8. Null values

## Error Recovery

If malformed JSON is detected:
1. Log the complete JSON string for debugging
2. Log the specific validation error from jq
3. Exit immediately - do not attempt to use malformed JSON
4. Do not attempt automatic correction
5. Preserve the malformed file for investigation

## Migration Notes

### From Direct Assignment
```bash
# OLD (WRONG):
JSON='{"status": "'$STATUS'"}'

# NEW (CORRECT):
JSON=$(jq -n --arg s "$STATUS" '{status: $s}')
```

### From Heredoc
```bash
# OLD (WRONG):
JSON=$(cat <<EOF
{
  "message": "$MESSAGE"
}
EOF
)

# NEW (CORRECT):
JSON=$(jq -n --arg m "$MESSAGE" '{message: $m}')
```

### From String Concatenation
```bash
# OLD (WRONG):
JSON="{\"data\": \"$DATA\"}"

# NEW (CORRECT):
JSON=$(jq -n --arg d "$DATA" '{data: $d}')
```

## Express Agent Must Follow JSON Standard

The express agent MUST use the approved jq method with --arg for creating JSON, even for multi-line content. See @instructions/meta/json-creation-standards.md for the mandatory pattern.

### Specific Requirements for Express Agent

1. **No --rawfile usage** - Even for large markdown content
2. **Use file-to-variable pattern** - Read file into bash variable, then use --arg
3. **Use Write tool for file creation** - More reliable than echo for complex content
4. **Follow the standard** - No exceptions for "complex" content

### Correct Express Agent Pattern

**Agent Actions (First):**
```
Write "/tmp/peer-express/formatted_$$.md" with content:
## Executive Summary
Successfully completed the task with all requirements met.

## Key Accomplishments
- Achievement 1: Completed spec refinement
- Achievement 2: Updated all documentation

## Next Steps
Review the updated files and proceed with implementation.
```

**Bash Script (After file is created):**
```bash
# Read file content into variable (now safe from control characters)
FORMATTED_CONTENT=$(<"/tmp/peer-express/formatted_$$.md")

# Prepare summary (single-line is OK)
SUMMARY_TEXT="Successfully completed task"

# Use --arg with the variables (NOT --rawfile)
EXPRESS_OUTPUT=$(jq -n \
  --arg formatted "$FORMATTED_CONTENT" \
  --arg summary "$SUMMARY_TEXT" \
  '{
    formatted_output: $formatted,
    summary: $summary
  }')

# Clean up temporary file
rm -f "/tmp/peer-express/formatted_$$.md"
```

## Key Takeaways

1. **Never assign multi-line content to variables directly** - This introduces control characters
2. **Always use Write tool for multi-line content** - Write to file first, then read into variable
3. **jq prevents escaping issues** - But only if content is properly loaded without control characters
4. **Variable injection is safe** - Using --arg/--argjson prevents injection attacks
5. **Type preservation** - Numbers and booleans maintain proper JSON types
6. **Validation is mandatory** - Always check JSON validity before use

## Critical Pattern Summary

For ANY multi-line or markdown content:
1. **DO NOT**: Assign directly to bash variable (`VAR="multi\nline"`)
2. **DO**: Write to file with Write tool
3. **DO**: Read file into variable (`VAR=$(<"file")`)
4. **DO**: Use variable with --arg in jq
5. **DO**: Clean up temporary files