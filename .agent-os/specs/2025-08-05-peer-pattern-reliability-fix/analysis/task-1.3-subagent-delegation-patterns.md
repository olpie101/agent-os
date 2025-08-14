# Task 1.3: Subagent Delegation Patterns and Instruction Formats

## Overview

This document identifies and analyzes the subagent delegation patterns and instruction formats used in Agent OS instructions, based on examination of execute-tasks.md and create-spec.md.

## Core Subagent Delegation Pattern

### Step Declaration with Subagent

```xml
<step number="X" subagent="agent-name" name="step_name">
```

The `subagent` attribute in the step declaration indicates that this step will delegate work to a specific subagent.

## Instruction Format Patterns

### 1. Basic Subagent Request Pattern

```xml
<instructions>
  ACTION: Use [agent-name] subagent
  REQUEST: "[Specific request with all necessary context]"
  WAIT: For [expected output/completion]
  PROCESS: [How to handle the response]
</instructions>
```

**Example from execute-tasks.md:**
```xml
<step number="4" subagent="git-workflow" name="git_branch_management">
  <instructions>
    ACTION: Use git-workflow subagent
    REQUEST: "Check and manage branch for spec: [SPEC_FOLDER]
              - Create branch if needed
              - Switch to correct branch
              - Handle any uncommitted changes"
    WAIT: For branch setup completion
  </instructions>
</step>
```

### 2. Multiple Request Pattern

```xml
<instructions>
  ACTION: Use [agent-name] subagent to:
    - REQUEST: "[First request]"
    - REQUEST: "[Second request]"
    - REQUEST: "[Third request]"
  PROCESS: [How to process all responses]
</instructions>
```

**Example from execute-tasks.md:**
```xml
<step number="2" subagent="context-fetcher" name="context_analysis">
  <instructions>
    ACTION: Use context-fetcher subagent to:
      - REQUEST: "Get product pitch from mission-lite.md"
      - REQUEST: "Get spec summary from spec-lite.md"
      - REQUEST: "Get technical approach from technical-spec.md"
    PROCESS: Returned information
  </instructions>
</step>
```

### 3. Context-Aware Request Pattern

```xml
<instructions>
  ACTION: Use [agent-name] subagent
  REQUEST: "[Main request]
            [Additional context line 1]
            [Additional context line 2]"
  WAIT: For [specific outcome]
  PROCESS: [Processing instructions]
</instructions>
```

**Example from execute-tasks.md:**
```xml
<step number="7" subagent="git-workflow" name="git_workflow">
  <instructions>
    ACTION: Use git-workflow subagent
    REQUEST: "Complete git workflow for [SPEC_NAME] feature:
              - Spec: [SPEC_FOLDER_PATH]
              - Changes: All modified files
              - Target: main branch
              - Description: [SUMMARY_OF_IMPLEMENTED_FEATURES]"
    WAIT: For workflow completion
    PROCESS: Save PR URL for summary
  </instructions>
</step>
```

### 4. Conditional Subagent Request Pattern

```xml
<instructions>
  ACTION: Use [agent-name] subagent
  REQUEST: "Find [specific items] relevant to:
            - Condition 1: [details]
            - Condition 2: [details]
            - Condition 3: [details]"
  PROCESS: Returned [items]
  APPLY: [How to apply results]
</instructions>
```

**Example from execute-tasks.md:**
```xml
<step number="3" subagent="context-fetcher" name="best_practices_review">
  <instructions>
    ACTION: Use context-fetcher subagent
    REQUEST: "Find best practices sections relevant to:
              - Task's technology stack: [CURRENT_TECH]
              - Feature type: [CURRENT_FEATURE_TYPE]
              - Testing approaches needed
              - Code organization patterns"
    PROCESS: Returned best practices
    APPLY: Relevant patterns to implementation
  </instructions>
</step>
```

## Common Subagents and Their Patterns

### 1. context-fetcher
- **Purpose**: Retrieve specific information from files
- **Pattern**: Multiple requests for different contexts
- **Returns**: Information extracted from specified files

### 2. file-creator
- **Purpose**: Create files and directories
- **Pattern**: Single request with template/content
- **Returns**: Confirmation of creation

### 3. git-workflow
- **Purpose**: Handle git operations
- **Pattern**: Complex requests with multiple sub-tasks
- **Returns**: Operation results (URLs, status)

### 4. test-runner
- **Purpose**: Execute tests
- **Pattern**: Request specific test scope
- **Returns**: Test results and analysis

### 5. date-checker
- **Purpose**: Get current date
- **Pattern**: Simple request, no parameters
- **Returns**: Date in YYYY-MM-DD format

## Context Passing Patterns

### 1. File-Based Context
Subagents often read context from temporary files:
```
- `/tmp/peer_args.txt` - Contains instruction arguments
- `/tmp/peer_context.txt` - Contains execution context
- `/tmp/peer_cycle.txt` - Contains cycle information
```

### 2. Explicit Context in Request
Context passed directly in the REQUEST:
```xml
REQUEST: "Plan execution for [INSTRUCTION] with context [CONTEXT]"
```

### 3. Reference to Previous Steps
Context built from previous step outputs:
```xml
PLANNING_OUTPUT: {from NATS KV cycle data}
EXECUTION_OUTPUT: {from NATS KV cycle data}
```

## Instruction Format Guidelines

### 1. ACTION Directive
- Always starts with "Use [subagent-name] subagent"
- Can include "to:" for listing multiple actions
- Should be clear and imperative

### 2. REQUEST Directive
- Enclosed in quotes for clarity
- Can be multi-line for complex requests
- Should include all necessary context
- Uses placeholders [LIKE_THIS] for variables

### 3. WAIT Directive
- Describes what completion looks like
- Not always required (implicit wait)
- Used when timing is important

### 4. PROCESS Directive
- Describes how to handle response
- Can include storage instructions
- May reference subsequent steps

### 5. Additional Directives
- **VALIDATE**: Check results before proceeding
- **STORE**: Save results for later use
- **APPLY**: How to use the results
- **SKIP**: Conditional execution

## Key Principles

1. **Self-Contained Requests**: Each REQUEST should contain all necessary context
2. **Clear Expectations**: WAIT and PROCESS clarify expected outcomes
3. **No Direct Tool Use**: Subagents handle tool interactions
4. **Declarative Style**: Describe what, not how
5. **Context Preservation**: Pass context explicitly or through files
6. **Error Handling**: Through process logic, not exceptions

## Anti-Patterns to Avoid

1. **Direct Tool Calls**: Never call tools directly in delegated steps
2. **Implicit Context**: Always pass necessary context explicitly
3. **Script Dependencies**: No reliance on external scripts
4. **State Assumptions**: Don't assume state between steps

## Summary

Subagent delegation in Agent OS follows a consistent pattern:
- Step declaration with `subagent` attribute
- Structured `<instructions>` block
- Clear ACTION, REQUEST, WAIT, PROCESS directives
- Explicit context passing
- Declarative, self-contained requests

This pattern enables reliable coordination between the main instruction and specialized subagents without script dependencies or direct tool manipulation.