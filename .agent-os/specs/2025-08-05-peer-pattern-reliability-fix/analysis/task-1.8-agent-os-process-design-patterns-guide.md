# Agent OS Process Design Patterns Reference Guide

## Overview

This reference guide consolidates all Agent OS process design patterns discovered through analysis of execute-tasks.md and create-spec.md. These patterns form the foundation for reliable, maintainable instruction files.

## Table of Contents

1. [Core Structure Patterns](#core-structure-patterns)
2. [Step Definition Patterns](#step-definition-patterns)
3. [Subagent Patterns](#subagent-patterns)
4. [Conditional Logic Patterns](#conditional-logic-patterns)
5. [Error Handling Patterns](#error-handling-patterns)
6. [Data Flow Patterns](#data-flow-patterns)
7. [User Interaction Patterns](#user-interaction-patterns)
8. [Reference Command Patterns](#reference-command-patterns)
9. [Best Practices](#best-practices)
10. [Pattern Quick Reference](#pattern-quick-reference)

## Core Structure Patterns

### 1. Instruction File Structure

```markdown
---
description: [Purpose of the instruction]
globs:
alwaysApply: false
version: X.X
encoding: UTF-8
---

# [Instruction Title]

## Overview

[Brief description of what this instruction does]

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>
  [Steps go here]
</process_flow>

## [Additional Sections as Needed]
```

### 2. Process Flow Container

```xml
<process_flow>
  <step number="1" name="first_step">
    ...
  </step>
  <step number="2" name="second_step">
    ...
  </step>
</process_flow>
```

## Step Definition Patterns

### 1. Basic Step (No Delegation)

```xml
<step number="X" name="descriptive_name">

### Step X: Human-Readable Title

Description of what this step accomplishes.

<instructions>
  ACTION: Primary action to perform
  VALIDATE: What to check
  PROCEED: Next action
</instructions>

</step>
```

### 2. Subagent Delegation Step

```xml
<step number="X" subagent="agent-name" name="step_name">

### Step X: Step Title

Description of delegation purpose.

<instructions>
  ACTION: Use [agent-name] subagent
  REQUEST: "[Detailed request with context]"
  WAIT: For [expected outcome]
  PROCESS: [How to handle response]
</instructions>

</step>
```

### 3. Conditional Step

```xml
<step number="X" name="conditional_step">

### Step X: Conditional Action

Description of conditional logic.

<conditional_logic>
  IF condition:
    ACTION or SKIP
  ELSE:
    ALTERNATIVE action
</conditional_logic>

<instructions>
  ACTION: Check condition
  CONDITIONAL: Apply based on result
  PROCEED: To next appropriate step
</instructions>

</step>
```

## Subagent Patterns

### 1. Simple Request Pattern

```xml
<instructions>
  ACTION: Use [agent] subagent
  REQUEST: "[Single clear request]"
  PROCESS: [Result handling]
</instructions>
```

### 2. Multi-Request Pattern

```xml
<instructions>
  ACTION: Use [agent] subagent to:
    - REQUEST: "[First request]"
    - REQUEST: "[Second request]"
    - REQUEST: "[Third request]"
  PROCESS: Combine all responses
</instructions>
```

### 3. Context-Rich Request Pattern

```xml
<instructions>
  ACTION: Use [agent] subagent
  REQUEST: "[Main request]
            Context: [additional context]
            Requirements: [specific needs]
            Format: [expected output]"
  VALIDATE: Response completeness
  STORE: Results for next phase
</instructions>
```

## Conditional Logic Patterns

### 1. Simple IF/ELSE

```xml
<conditional_logic>
  IF condition:
    ACTION
  ELSE:
    ALTERNATIVE
</conditional_logic>
```

### 2. Nested Conditions

```xml
<validation_logic>
  IF primary_condition:
    IF secondary_condition:
      ACTION_A
    ELSE:
      ACTION_B
  ELSE:
    ACTION_C
</validation_logic>
```

### 3. Decision Tree

```xml
<decision_tree>
  IF option_a:
    FOLLOW path_a
  ELSE IF option_b:
    FOLLOW path_b
  ELSE IF option_c:
    FOLLOW path_c
  ELSE:
    DEFAULT path
</decision_tree>
```

### 4. State-Based Logic

```xml
<state_check>
  IF already_in_context:
    SKIP loading
    USE existing data
  ELSE:
    LOAD required data
    PROCESS new information
</state_check>
```

## Error Handling Patterns

### 1. Validation Error

```xml
<validation_logic>
  IF invalid_input:
    ERROR: "[Clear error message]"
    PROVIDE: "[Recovery instructions]"
    STOP execution
</validation_logic>
```

### 2. Resource Availability

```xml
<availability_check>
  CHECK: Resource availability
  IF not_available:
    DISPLAY: "❌ [Resource] not available"
    PROVIDE: "[Setup instructions]"
    STOP execution
</availability_check>
```

### 3. Graceful Degradation

```xml
<fallback_logic>
  TRY primary_method
  IF fails:
    TRY secondary_method
    IF still_fails:
      USE minimal_approach
      WARN user of limitations
</fallback_logic>
```

### 4. Retry with Limits

```xml
<retry_logic>
  ATTEMPT operation
  IF fails:
    RETRY up to 3 times
    IF all_attempts_fail:
      DOCUMENT issue
      ASK user for guidance
</retry_logic>
```

## Data Flow Patterns

### 1. Context Gathering

```xml
<context_gathering>
  <required_data>
    - item_1 from source_1
    - item_2 from source_2
  </required_data>
  <optional_data>
    - item_3 if available
  </optional_data>
</context_gathering>
```

### 2. Data Templates

```xml
<data_template>
  <field_1>[VALUE_1]</field_1>
  <field_2>[VALUE_2]</field_2>
  <nested>
    <subfield>[NESTED_VALUE]</subfield>
  </nested>
</data_template>
```

### 3. File Templates

```xml
<file_template>
  <header>
    # Document Title
    > Metadata: [VALUE]
  </header>
  <sections>
    - Section 1
    - Section 2
  </sections>
</file_template>
```

## User Interaction Patterns

### 1. Simple Prompt

```xml
<user_prompt>
  Question or request for the user.
  Format: [expected format]
</user_prompt>
```

### 2. Choice Prompt

```xml
<user_choice>
  Please select an option:
  1. [Option 1 description]
  2. [Option 2 description]
  3. [Option 3 description]
</user_choice>
```

### 3. Confirmation Request

```xml
<confirmation>
  [Action description]
  Do you want to proceed? (yes/no)
</confirmation>
```

## Reference Command Patterns

### 1. Simple Reference

```xml
<command_name>
  command --with --parameters
</command_name>
```

### 2. Command with Context

```xml
<operation_example>
  # Comment explaining purpose
  command --flag value
  
  # Alternative approach
  other-command --different-flag
</operation_example>
```

### 3. Multi-Step Reference

```xml
<setup_commands>
  # Step 1: Check status
  command status
  
  # Step 2: Perform operation
  command operation --param value
  
  # Step 3: Verify result
  command verify
</setup_commands>
```

## Best Practices

### 1. Step Naming
- Use descriptive snake_case names
- Match name to primary action
- Keep names concise but clear

### 2. Instructions Clarity
- Start ACTION with imperative verb
- Be specific about expectations
- Include all necessary context

### 3. Error Messages
- Use clear, non-technical language
- Always provide recovery path
- Include visual indicators (❌, ⚠️, ✅)

### 4. Conditional Logic
- Express in natural language
- Make all paths explicit
- Avoid deep nesting

### 5. Subagent Communication
- Pass complete context in REQUEST
- Specify expected response format
- Handle response appropriately

### 6. Process Flow
- Number steps sequentially
- Maintain logical progression
- Group related operations

### 7. Documentation
- Describe step purpose clearly
- Explain complex logic
- Provide examples where helpful

## Pattern Quick Reference

### Essential Patterns for Every Instruction

1. **File Header**: Metadata and description
2. **Preflight Check**: Always execute meta preflight
3. **Process Flow**: Container for all steps
4. **Step Structure**: number, name, optional subagent
5. **Instructions Block**: ACTION directives

### Common Patterns by Use Case

**For User Input:**
- User prompt pattern
- Confirmation pattern
- Decision tree pattern

**For External Resources:**
- Availability check pattern
- Graceful degradation pattern
- Retry logic pattern

**For Complex Logic:**
- Nested conditions pattern
- State-based logic pattern
- Loop control pattern

**For Subagent Work:**
- Simple request pattern
- Multi-request pattern
- Context passing pattern

**For Error Handling:**
- Validation error pattern
- Resource error pattern
- Recovery instruction pattern

### Visual Indicators

- ❌ Error/Failure
- ⚠️ Warning/Caution
- ✅ Success/Complete
- 🚀 Ready/Launch
- 📦 Package/Delivery
- 👀 Review/Check

## Summary

Agent OS process design patterns provide:

1. **Consistency**: Standard patterns across all instructions
2. **Reliability**: Process-based logic without script dependencies
3. **Clarity**: Self-documenting structure and flow
4. **Flexibility**: Adaptable patterns for various scenarios
5. **Maintainability**: Easy to understand and modify

By following these patterns, Agent OS instructions remain reliable, understandable, and maintainable while avoiding the pitfalls of script-based orchestration.