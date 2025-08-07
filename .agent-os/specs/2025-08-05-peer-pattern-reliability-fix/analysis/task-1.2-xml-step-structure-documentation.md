# Task 1.2: XML-like Step Structure Documentation

## Overview

This document analyzes and documents the XML-like step structure patterns used in execute-tasks.md and create-spec.md, which serve as the reference patterns for Agent OS instruction design.

## Common Process Flow Structure

### Basic Pattern

Both files follow this fundamental structure:

```xml
<process_flow>
  <step number="X" [subagent="agent-name"] name="step_name">
    ### Step X: Step Title
    
    Step description explaining purpose and context.
    
    <instructions>
      ACTION: Primary action to perform
      [Additional directives as needed]
    </instructions>
    
    [Additional XML blocks for logic/data]
  </step>
</process_flow>
```

## Patterns from execute-tasks.md

### 1. Simple Step (No Subagent)

```xml
<step number="1" name="task_assignment">

### Step 1: Task Assignment

Identify which tasks to execute from the spec...

<task_selection>
  <explicit>user specifies exact task(s)</explicit>
  <implicit>find next uncompleted task in tasks.md</implicit>
</task_selection>

<instructions>
  ACTION: Identify task(s) to execute
  DEFAULT: Select next uncompleted parent task if not specified
  CONFIRM: Task selection with user
</instructions>

</step>
```

### 2. Subagent Delegation Step

```xml
<step number="2" subagent="context-fetcher" name="context_analysis">

### Step 2: Context Analysis

Use the context-fetcher subagent to gather minimal context...

<instructions>
  ACTION: Use context-fetcher subagent to:
    - REQUEST: "Get product pitch from mission-lite.md"
    - REQUEST: "Get spec summary from spec-lite.md"
    - REQUEST: "Get technical approach from technical-spec.md"
  PROCESS: Returned information
</instructions>

<context_gathering>
  <essential_docs>
    - tasks.md for task breakdown
  </essential_docs>
  <conditional_docs>
    - mission-lite.md for product alignment
    - spec-lite.md for feature summary
    - technical-spec.md for implementation details
  </conditional_docs>
</context_gathering>

</step>
```

### 3. Conditional Logic Step

```xml
<step number="3" name="development_server_check">

### Step 3: Check for Development Server

Check for any running development server...

<server_check_flow>
  <if_running>
    ASK user to shut down
    WAIT for response
  </if_running>
  <if_not_running>
    PROCEED immediately
  </if_not_running>
</server_check_flow>

<user_prompt>
  A development server is currently running.
  Should I shut it down before proceeding? (yes/no)
</user_prompt>

<instructions>
  ACTION: Check for running local development server
  CONDITIONAL: Ask permission only if server is running
  PROCEED: Immediately if no server detected
</instructions>

</step>
```

### 4. Loop/Complex Logic Step

```xml
<step number="5" name="task_execution_loop">

### Step 5: Task Execution Loop

Execute all assigned parent tasks...

<execution_flow>
  LOAD @~/.agent-os/instructions/core/execute-task.md ONCE

  FOR each parent_task assigned in Step 1:
    EXECUTE instructions from execute-task.md with:
      - parent_task_number
      - all associated subtasks
    WAIT for task completion
    UPDATE tasks.md status
  END FOR
</execution_flow>

<loop_logic>
  <continue_conditions>
    - More unfinished parent tasks exist
    - User has not requested stop
  </continue_conditions>
  <exit_conditions>
    - All assigned tasks marked complete
    - User requests early termination
    - Blocking issue prevents continuation
  </exit_conditions>
</loop_logic>

</step>
```

### 5. Reference Command Pattern

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

## Patterns from create-spec.md

### 1. Conditional Logic Pattern

```xml
<step number="2" subagent="context-fetcher" name="context_gathering">

### Step 2: Context Gathering (Conditional)

Use the context-fetcher subagent to read...

<conditional_logic>
  IF both mission-lite.md AND tech-stack.md already read in current context:
    SKIP this entire step
    PROCEED to step 3
  ELSE:
    READ only files not already in context:
      - mission-lite.md (if not in context)
      - tech-stack.md (if not in context)
    CONTINUE with context analysis
</conditional_logic>

<context_analysis>
  <mission_lite>core product purpose and value</mission_lite>
  <tech_stack>technical requirements</tech_stack>
</context_analysis>

</step>
```

### 2. Decision Tree Pattern

```xml
<step number="3" subagent="context-fetcher" name="requirements_clarification">

### Step 3: Requirements Clarification

Use the context-fetcher subagent to clarify...

<clarification_areas>
  <scope>
    - in_scope: what is included
    - out_of_scope: what is excluded (optional)
  </scope>
  <technical>
    - functionality specifics
    - UI/UX requirements
    - integration points
  </technical>
</clarification_areas>

<decision_tree>
  IF clarification_needed:
    ASK numbered_questions
    WAIT for_user_response
  ELSE:
    PROCEED to_date_determination
</decision_tree>

</step>
```

### 3. Template/File Creation Pattern

```xml
<step number="6" subagent="file-creator" name="create_spec_md">

### Step 6: Create spec.md

Use the file-creator subagent to create the file...

<file_template>
  <header>
    # Spec Requirements Document

    > Spec: [SPEC_NAME]
    > Created: [CURRENT_DATE]
  </header>
  <required_sections>
    - Overview
    - User Stories
    - Spec Scope
    - Out of Scope
    - Expected Deliverable
  </required_sections>
</file_template>

<section name="overview">
  <template>
    ## Overview

    [1-2_SENTENCE_GOAL_AND_OBJECTIVE]
  </template>
  <constraints>
    - length: 1-2 sentences
    - content: goal and objective
  </constraints>
</section>

</step>
```

## Key XML Structure Elements

### 1. Step Attributes
- `number`: Sequential step number (required)
- `name`: Programmatic step name (required)
- `subagent`: Agent to delegate to (optional)

### 2. Instruction Block Elements
- `ACTION`: Primary action to perform
- `REQUEST`: Specific request to subagent
- `WAIT`: What to wait for
- `PROCESS`: How to process results
- `CONDITIONAL`: Conditional execution
- `PROCEED`: Next action

### 3. Logic Control Elements
- `<conditional_logic>`: Contains IF/ELSE logic
- `<decision_tree>`: Decision branching
- `<loop_logic>`: Loop conditions
- `<validation_logic>`: Validation rules

### 4. Data/Content Elements
- `<file_template>`: File content templates
- `<user_prompt>`: User interaction prompts
- `<notification_command>`: Reference commands
- `<example>`: Example content

### 5. Organization Elements
- `<clarification_areas>`: Grouped items
- `<context_gathering>`: Data collection
- `<task_selection>`: Options/choices
- `<constraints>`: Rules and limits

## Design Principles

1. **Sequential Numbering**: Steps are numbered sequentially for clear flow
2. **Descriptive Naming**: Step names use snake_case and describe the action
3. **Clear Instructions**: ACTION directives are imperative and specific
4. **Subagent Pattern**: Subagent steps always include REQUEST format
5. **Conditional Logic**: Uses natural language IF/ELSE structures
6. **Reference Examples**: Commands shown as examples, not executable
7. **Nested Structure**: Related data grouped in semantic XML blocks
8. **Process Focus**: Logic expressed as process flow, not scripts

## Summary

The XML-like structure provides:
- Clear visual hierarchy
- Semantic grouping of related information
- Natural language logic expressions
- Separation of instructions from data
- Consistent patterns for different step types
- No dependency on external scripts or tools

This structure enables reliable process coordination through declarative instructions rather than imperative script execution.