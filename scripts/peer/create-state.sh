#!/bin/bash
# create-state.sh - Wrapper for creating new NATS KV state
# Usage: ./create-state.sh <STATE_KEY> <INITIAL_JSON>
# Creates a new key only if it doesn't already exist

STATE_KEY="$1"
INITIAL_JSON="$2"

if [ -z "$STATE_KEY" ] || [ -z "$INITIAL_JSON" ]; then
  echo "ERROR: STATE_KEY and INITIAL_JSON are required" >&2
  echo "Usage: ./create-state.sh <STATE_KEY> <INITIAL_JSON>" >&2
  exit 1
fi

# Validate JSON before attempting to create
echo "$INITIAL_JSON" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Invalid JSON provided for new state" >&2
  echo "JSON (first 500 chars): ${INITIAL_JSON:0:500}" >&2
  exit 1
fi

# Log what we're creating (to stderr for debugging)
echo "INFO: Creating new state at key: $STATE_KEY" >&2
echo "INFO: JSON size: $(echo "$INITIAL_JSON" | wc -c) bytes" >&2
if [ $(echo "$INITIAL_JSON" | wc -c) -lt 5000 ]; then
  echo "INFO: Full JSON:" >&2
  echo "$INITIAL_JSON" | jq . >&2
else
  echo "INFO: JSON preview (first 1000 chars):" >&2
  echo "${INITIAL_JSON:0:1000}" >&2
fi

# Use nats kv create to ensure key doesn't already exist
CREATE_RESULT=$(echo "$INITIAL_JSON" | nats kv create agent-os-peer-state "$STATE_KEY" 2>&1)
CREATE_EXIT=$?

if [ $CREATE_EXIT -ne 0 ]; then
  # Check if error is because key already exists
  if echo "$CREATE_RESULT" | grep -q "already exists\|wrong last sequence"; then
    echo "ERROR: Key already exists: $STATE_KEY" >&2
    echo "Use update-state.sh to modify existing keys" >&2
  else
    echo "ERROR: Failed to create new state" >&2
    echo "NATS Error: $CREATE_RESULT" >&2
  fi
  exit 1
fi

echo "SUCCESS: Created new state at key $STATE_KEY" >&2
# Output success to stdout for agent to confirm
echo "OK"