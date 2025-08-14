#!/bin/bash
# read-state.sh - Wrapper for reading NATS KV state
# Usage: ./read-state.sh <STATE_KEY>

STATE_KEY="$1"

if [ -z "$STATE_KEY" ]; then
  echo "ERROR: STATE_KEY is required as first argument" >&2
  exit 1
fi

# Read current state
STATE=$(nats kv get agent-os-peer-state "$STATE_KEY" --raw 2>&1)
READ_EXIT=$?

if [ $READ_EXIT -ne 0 ]; then
  echo "ERROR: Failed to read state from NATS KV at key: $STATE_KEY" >&2
  echo "NATS Error: $STATE" >&2
  exit 1
fi

# Validate JSON is readable
echo "$STATE" | jq empty 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  echo "ERROR: Invalid JSON in NATS KV state at key: $STATE_KEY" >&2
  echo "Raw data received (first 500 chars): ${STATE:0:500}" >&2
  exit 1
fi

# Output the valid JSON to stdout (for agent to capture)
echo "$STATE"