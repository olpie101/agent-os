# Task 1.6: Notification Command Pattern for Reference Commands

## Overview

This document analyzes the notification_command pattern used in Agent OS instructions for providing reference commands without executing them through tool calls.

## The Notification Command Pattern

### Core Structure

```xml
<notification_command>
  command with parameters
</notification_command>
```

This pattern presents commands as reference examples that users or agents can understand without attempting direct execution.

### Primary Example from execute-tasks.md

```xml
<step number="9" name="completion_notification">

### Step 9: Task Completion Notification

Play a system sound to alert the user that tasks are complete.

<notification_command>
  afplay /System/Library/Sounds/Glass.aiff
</notification_command>

<instructions>
  ACTION: Play completion sound
  PURPOSE: Alert user that task is complete
</instructions>

</step>
```

## Pattern Characteristics

### 1. Declarative Reference
- Command shown for reference, not execution
- No Bash tool wrapper
- Clear intent without implementation details

### 2. Semantic Naming
- Tag name describes purpose: `<notification_command>`
- Could be adapted: `<reference_command>`, `<example_command>`
- Self-documenting XML structure

### 3. Separation of Concerns
- Command reference separate from instructions
- Instructions describe what to do
- Command shows one way it could be done

## Application to NATS Commands

Based on the technical spec, here's how the pattern applies to NATS commands:

### Health Check Example
```xml
<nats_health_check>
  nats kv ls --timeout=5s
</nats_health_check>
```

### Bucket Creation Example
```xml
<nats_bucket_create>
  nats kv add agent-os-peer-state --replicas=3 --history=50 --description="PEER pattern state storage"
</nats_bucket_create>
```

### KV Operations Examples
```xml
<nats_kv_read>
  nats kv get agent-os-peer-state "key-name" --raw
</nats_kv_read>

<nats_kv_write>
  nats kv put agent-os-peer-state "key-name" "value"
</nats_kv_write>
```

## Pattern Variations

### 1. Simple Command Reference
```xml
<command_name>
  command --with --flags
</command_name>
```

### 2. Multi-line Command Reference
```xml
<complex_command>
  command --flag1 value1 \
    --flag2 value2 \
    --flag3 value3
</complex_command>
```

### 3. Command with Context
```xml
<command_with_explanation>
  # This checks if the bucket exists
  nats kv info agent-os-peer-state
  
  # This creates it if needed
  nats kv add agent-os-peer-state --replicas=3
</command_with_explanation>
```

## Best Practices

### 1. Descriptive Tag Names
- Use semantic names that describe purpose
- Examples: `<health_check>`, `<bucket_setup>`, `<validation_command>`
- Avoid generic names like `<command>` or `<cmd>`

### 2. Complete Examples
- Include all necessary flags and parameters
- Show real values, not just placeholders
- Make examples directly usable as reference

### 3. No Execution Markup
- Don't wrap in ````bash` blocks (implies execution)
- Don't use "Run:" or "Execute:" prefixes
- Let the XML tag indicate it's a reference

### 4. Context Placement
- Place near relevant instructions
- Group related commands together
- Include in appropriate step context

## Integration with Process Flow

### Proper Integration Example
```xml
<step number="1" name="nats_validation">

### Step 1: NATS Validation

Verify NATS server is available and properly configured.

<health_check_example>
  nats kv ls --timeout=5s
</health_check_example>

<instructions>
  ACTION: Verify NATS availability
  CHECK: Server responds to KV operations
  ERROR_HANDLING: 
    IF not available:
      DISPLAY: "❌ NATS server not available"
      STOP execution
</instructions>

</step>
```

### What NOT to Do
```xml
<!-- DON'T DO THIS -->
<step number="1" name="run_script">
  <instructions>
    ACTION: Use Bash tool
    COMMAND: ~/.agent-os/scripts/check-nats.sh
  </instructions>
</step>
```

## Semantic Command Categories

### 1. Validation Commands
```xml
<availability_check>
  nats kv ls
</availability_check>

<configuration_verify>
  nats kv info agent-os-peer-state
</configuration_verify>
```

### 2. Setup Commands
```xml
<bucket_creation>
  nats kv add agent-os-peer-state --replicas=3 --history=50
</bucket_creation>

<initial_state>
  nats kv put agent-os-peer-state "cycle:current" "0"
</initial_state>
```

### 3. Operation Commands
```xml
<state_read>
  nats kv get agent-os-peer-state "cycle:1:plan" --raw
</state_read>

<state_update>
  nats kv put agent-os-peer-state "cycle:1:status" "complete"
</state_update>
```

## Benefits of This Pattern

### 1. Clarity
- Clear separation between reference and execution
- Self-documenting through semantic tags
- Easy to understand intent

### 2. Flexibility
- Agents can interpret appropriately
- Users can copy and modify
- No hard coupling to implementation

### 3. Maintainability
- Easy to update command examples
- No script dependencies
- Version-independent references

### 4. Safety
- No accidental execution
- Clear boundary between docs and code
- Predictable behavior

## Summary

The notification_command pattern provides a clean way to include reference commands in Agent OS instructions:

- **Structure**: Semantic XML tags containing command examples
- **Purpose**: Show how something could be done without mandating execution
- **Integration**: Complements process instructions without replacing them
- **Flexibility**: Allows different implementations while providing guidance

This pattern is essential for the PEER redesign, allowing NATS commands to be shown as references while actual execution is handled through process logic and subagent delegation.