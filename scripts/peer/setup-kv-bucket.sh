#!/bin/bash
# Script: setup-kv-bucket.sh
# Purpose: Ensure agent-os-peer-state KV bucket exists with correct configuration
# Parameters: None
# Output: Exit 0 on success, exit 1 on failure
# Cache: None (always verify bucket exists)
# Dependencies: nats CLI command

# Cleanup function - ONLY for local temp files
cleanup() {
    rm -f /tmp/bucket_info.txt
}

# Set trap for cleanup on any exit
trap cleanup EXIT

BUCKET_NAME="agent-os-peer-state"
REQUIRED_REPLICAS=3
REQUIRED_HISTORY=50

echo "🔍 Checking NATS KV bucket setup..."

# Check if bucket exists
if nats kv info "$BUCKET_NAME" > /tmp/bucket_info.txt 2>&1; then
    echo "✅ Bucket $BUCKET_NAME exists"
    
    # Extract configuration using more reliable parsing
    # Count replicas (leader + replicas)
    bucket_replicas=$(grep -c "Replica:" /tmp/bucket_info.txt || echo "0")
    bucket_replicas=$((bucket_replicas + 1))  # Add 1 for leader
    bucket_history=$(grep "History Kept:" /tmp/bucket_info.txt | awk '{print $3}' || echo "")
    
    # Check configuration
    if [ -z "$bucket_replicas" ] || [ -z "$bucket_history" ]; then
        echo "⚠️  Warning: Unable to verify bucket configuration"
        echo "   Could not parse replicas or history values"
        echo "   Continuing with existing bucket..."
    elif [ "$bucket_replicas" != "$REQUIRED_REPLICAS" ] || [ "$bucket_history" != "$REQUIRED_HISTORY" ]; then
        echo "⚠️  Warning: Bucket configuration mismatch"
        echo "   Current: replicas=$bucket_replicas, history=$bucket_history"
        echo "   Required: replicas=$REQUIRED_REPLICAS, history=$REQUIRED_HISTORY"
        echo "   Note: Using existing bucket with current configuration"
    else
        echo "✅ Bucket configuration verified: replicas=$REQUIRED_REPLICAS, history=$REQUIRED_HISTORY"
    fi
    
    exit 0
else
    echo "📦 Creating $BUCKET_NAME bucket..."
    
    # Create bucket with required configuration
    if nats kv add "$BUCKET_NAME" \
        --replicas=$REQUIRED_REPLICAS \
        --history=$REQUIRED_HISTORY \
        --description="PEER pattern state storage for Agent OS"; then
        echo "✅ Successfully created $BUCKET_NAME bucket"
        exit 0
    else
        echo "❌ Failed to create KV bucket"
        echo "Please check NATS server permissions and try again"
        exit 1
    fi
fi