---
description: JSON Creation Standard for PEER Pattern Agents
globs:
alwaysApply: false
version: 2.2
encoding: UTF-8
---

# JSON Creation Standard for PEER Agents

## Scope

This standard applies when PEER agents need to create JSON data.

## The Standard

**Use jq exclusively for JSON creation. No exceptions.**

### Basic Pattern

```bash
JSON=$(jq -n \
  --arg string_var "$STRING" \
  --argjson num_var "$NUMBER" \
  --argjson bool_var "$BOOLEAN" \
  '{
    text: $string_var,
    number: $num_var,
    boolean: $bool_var
  }')

# Always validate
echo "$JSON" | jq empty || exit 1
```

### Multi-line Content Pattern

Direct assignment of multi-line content to bash variables introduces control characters that corrupt JSON.

**Correct Approach:**
1. Agent: Write content to file using Write tool
2. Bash: Read file into variable and use --arg

```
Write "/tmp/content.md" with:
[Multi-line content]
```

```bash
CONTENT=$(<"/tmp/content.md")
JSON=$(jq -n --arg text "$CONTENT" '{content: $text}')
echo "$JSON" | jq empty || exit 1
rm -f "/tmp/content.md"
```

## Prohibited Methods

These methods cause escaping issues or control character corruption:

- **Direct assignment**: `JSON='{"key": "'$VAR'"}'`
- **Heredoc**: `JSON=$(cat <<EOF...EOF)`
- **String concatenation**: `JSON="{\"key\": \"$VAR\"}"`
- **Direct multi-line assignment**: `VAR="line1\nline2"` (introduces control characters)
- **--rawfile flag**: Not in approved standard

## Rules

- Only `--arg` (strings) and `--argjson` (numbers/booleans/objects) are permitted
- Always validate with `jq empty` before use
- Multi-line content must go through file intermediary
- No other jq flags or string manipulation allowed