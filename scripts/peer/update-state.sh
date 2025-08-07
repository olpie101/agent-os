#!/bin/bash
# update-state.sh - Wrapper for updating NATS KV state
# Usage: ./update-state.sh <STATE_KEY> <JQ_FILTER>
# The JQ filter receives the current state and should output the modified state

STATE_KEY="$1"
JQ_FILTER="$2"

if [ -z "$STATE_KEY" ] || [ -z "$JQ_FILTER" ]; then
  echo "ERROR: STATE_KEY and JQ_FILTER are required" >&2
  echo "Usage: ./update-state.sh <STATE_KEY> <JQ_FILTER>" >&2
  exit 1
fi

# Step 1: Read current state
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw 2>&1)
READ_EXIT=$?

if [ $READ_EXIT -ne 0 ]; then
  echo "ERROR: Failed to read state from NATS KV" >&2
  echo "NATS Error: $STATE" >&2
  exit 1
fi

# Step 2: Extract revision number
REVISION=$(nats kv get agent-os-peer-state "$STATE_KEY" 2>/dev/null | grep 'revision:' | sed 's/.*revision: \([0-9]*\).*/\1/')
if [ -z "$REVISION" ]; then
  echo "ERROR: Failed to get revision number for key: $STATE_KEY" >&2
  exit 1
fi

# Step 3: Validate current JSON
echo "$STATE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Current state has invalid JSON at key: $STATE_KEY" >&2
  exit 1
fi

# Step 4: Apply JQ filter (capture both output and errors)
JQ_ERROR=$(mktemp)
MODIFIED_STATE=$(echo "$STATE" | jq "$JQ_FILTER" 2>"$JQ_ERROR")
JQ_EXIT=$?

if [ $JQ_EXIT -ne 0 ]; then
  echo "ERROR: Failed to modify JSON with jq (exit code: $JQ_EXIT)" >&2
  echo "JQ Error: $(cat "$JQ_ERROR")" >&2
  echo "JQ Filter was: $JQ_FILTER" >&2
  rm -f "$JQ_ERROR"
  exit 1
fi
rm -f "$JQ_ERROR"

# Step 5: Validate modified JSON
echo "$MODIFIED_STATE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Modified state resulted in invalid JSON" >&2
  echo "Modified JSON (first 500 chars): ${MODIFIED_STATE:0:500}" >&2
  exit 1
fi

# Step 6: Log the JSON being written (to stderr so it doesn't interfere with stdout)
echo "INFO: Writing JSON to $STATE_KEY at revision $REVISION" >&2
echo "INFO: JSON size: $(echo "$MODIFIED_STATE" | wc -c) bytes" >&2
if [ $(echo "$MODIFIED_STATE" | wc -c) -lt 5000 ]; then
  echo "INFO: Full JSON:" >&2
  echo "$MODIFIED_STATE" | jq . >&2
else
  echo "INFO: JSON preview (first 1000 chars):" >&2
  echo "${MODIFIED_STATE:0:1000}" >&2
fi

# Step 7: Update with revision check
UPDATE_RESULT=$(nats kv update agent-os-peer-state "$STATE_KEY" "$MODIFIED_STATE" "$REVISION" 2>&1)
UPDATE_EXIT=$?

if [ $UPDATE_EXIT -ne 0 ]; then
  echo "ERROR: Failed to update state (likely revision mismatch)" >&2
  echo "Expected revision was: $REVISION" >&2
  echo "NATS Error: $UPDATE_RESULT" >&2
  echo "Another process may have updated the state concurrently" >&2
  exit 1
fi

echo "SUCCESS: Updated state at key $STATE_KEY at revision $REVISION" >&2
# Output success to stdout for agent to confirm
echo "OK"