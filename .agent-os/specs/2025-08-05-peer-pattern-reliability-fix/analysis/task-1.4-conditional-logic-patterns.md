# Task 1.4: Conditional Logic and Decision Tree Structures

## Overview

This document maps the conditional logic and decision tree structures used in Agent OS instructions, providing patterns for implementing process-based flow control without script dependencies.

## Conditional Logic Patterns

### 1. Simple IF/ELSE Pattern

```xml
<conditional_logic>
  IF condition:
    ACTION or SKIP or PROCEED
  ELSE:
    ALTERNATIVE action
</conditional_logic>
```

**Example from create-spec.md:**
```xml
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
```

### 2. Nested Conditional Pattern

```xml
<server_check_flow>
  <if_running>
    ASK user to shut down
    WAIT for response
  </if_running>
  <if_not_running>
    PROCEED immediately
  </if_not_running>
</server_check_flow>
```

### 3. Decision Tree Pattern

```xml
<decision_tree>
  IF primary_condition:
    ACTION with parameters
    WAIT for result
  ELSE IF secondary_condition:
    ALTERNATIVE action
  ELSE:
    DEFAULT behavior
</decision_tree>
```

**Example from create-spec.md:**
```xml
<decision_tree>
  IF clarification_needed:
    ASK numbered_questions
    WAIT for_user_response
  ELSE:
    PROCEED to_date_determination
</decision_tree>
```

### 4. Complex Conditional with Multiple Checks

```xml
<decision_tree>
  IF spec_does_NOT_significantly_deviate:
    SKIP this entire step
    STATE "Spec aligns with mission and roadmap"
    PROCEED to step 13
  ELSE IF spec_significantly_deviates:
    EXPLAIN the significant deviation
    ASK user: "This spec significantly deviates from our mission/roadmap. Should I draft a decision entry?"
    IF user_approves:
      DRAFT decision entry
      UPDATE decisions.md
    ELSE:
      SKIP updating decisions.md
      PROCEED to step 13
</decision_tree>
```

### 5. Validation Logic Pattern

```xml
<validation_logic>
  IF neither instruction nor continue provided:
    ERROR: "Must provide either --instruction or --continue"
  IF both instruction and continue provided:
    ERROR: "Cannot use both --instruction and --continue"
</validation_logic>
```

### 6. Loop Control Pattern

```xml
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
```

### 7. Error Handling Pattern

```xml
<error_handling>
  IF command fails:
    DISPLAY: "❌ Error message"
    PROVIDE: "Recovery instructions"
    STOP execution
</error_handling>
```

## Decision Tree Structures

### 1. Sequential Decision Tree

Each decision leads to the next:
```xml
<argument_validation>
  <required_parameters>
    - --instruction OR --continue (mutually exclusive)
    - Optional: --spec
  </required_parameters>
  <validation_logic>
    IF neither instruction nor continue provided:
      ERROR with usage instructions
    IF both instruction and continue provided:
      ERROR with conflict explanation
  </validation_logic>
</argument_validation>
```

### 2. Branching Decision Tree

Multiple paths from a single decision:
```xml
<option_a_flow>
  <trigger_phrases>
    - "what's next?"
  </trigger_phrases>
  <actions>
    1. CHECK @.agent-os/product/roadmap.md
    2. FIND next uncompleted item
    3. SUGGEST item to user
    4. WAIT for approval
  </actions>
</option_a_flow>

<option_b_flow>
  <trigger>user describes specific spec idea</trigger>
  <accept>any format, length, or detail level</accept>
  <proceed>to context gathering</proceed>
</option_b_flow>
```

### 3. State-Based Decision Tree

Decisions based on current state:
```xml
<preliminary_check>
  EVALUATE: Did executed tasks potentially complete a roadmap item?
  IF NO:
    SKIP this entire step
    PROCEED to step 9
  IF YES:
    CONTINUE with roadmap check
</preliminary_check>
```

### 4. Conditional Execution Pattern

```xml
<conditional_execution>
  <preliminary_check>
    EVALUATE: Did executed tasks potentially complete a roadmap item?
    IF NO:
      SKIP this entire step
      PROCEED to step 9
    IF YES:
      CONTINUE with roadmap check
  </preliminary_check>
</conditional_execution>

<conditional_loading>
  IF roadmap.md NOT already in context:
    LOAD @.agent-os/product/roadmap.md
  ELSE:
    SKIP loading (use existing context)
</conditional_loading>
```

## Flow Control Elements

### 1. Action Directives
- **SKIP**: Skip current step/action
- **PROCEED**: Continue to specified step
- **CONTINUE**: Continue with current flow
- **STOP**: Halt execution
- **WAIT**: Pause for input/completion
- **ERROR**: Report error and handle

### 2. Evaluation Directives
- **EVALUATE**: Assess condition
- **CHECK**: Verify state
- **VALIDATE**: Ensure correctness
- **IF/ELSE IF/ELSE**: Conditional branches

### 3. User Interaction
- **ASK**: Request user input
- **DISPLAY**: Show information
- **PROVIDE**: Give instructions
- **CONFIRM**: Get user confirmation

## Conditional Logic Best Practices

### 1. Clear Conditions
- Use natural language conditions
- Be explicit about what's being checked
- Avoid complex boolean logic

### 2. Explicit Actions
- Each branch should have clear actions
- Use consistent action verbs
- Include error recovery paths

### 3. State Awareness
- Check if data already in context
- Validate preconditions
- Handle partial completion

### 4. User Communication
- Provide clear error messages
- Explain why actions are taken
- Offer recovery options

## Common Conditional Patterns

### 1. Skip If Already Done
```xml
IF data already in context:
  SKIP loading
ELSE:
  LOAD required data
```

### 2. Ask If Unclear
```xml
IF clarification_needed:
  ASK specific questions
  WAIT for response
ELSE:
  PROCEED with defaults
```

### 3. Error with Recovery
```xml
IF operation fails:
  DISPLAY error message
  PROVIDE recovery steps
  STOP or RETRY based on error type
```

### 4. Progressive Enhancement
```xml
IF basic_requirement_met:
  PROCEED to basic implementation
  IF advanced_requirement_met:
    ADD advanced features
  ELSE:
    SKIP advanced features
```

## Decision Tree Design Principles

1. **Clarity First**: Conditions should be immediately understandable
2. **Explicit Paths**: Every branch should have a clear outcome
3. **No Hidden State**: All decisions based on explicit conditions
4. **Error Recovery**: Every error path should offer recovery
5. **User Agency**: Give users control over important decisions
6. **Progressive Disclosure**: Complex logic broken into simple decisions

## Anti-Patterns to Avoid

1. **Script Exit Codes**: Don't rely on $? or exit codes
2. **Hidden Conditions**: All conditions should be explicit
3. **Goto-Style Flow**: Use structured PROCEED, not arbitrary jumps
4. **Silent Failures**: Always communicate failures
5. **Infinite Loops**: Ensure clear exit conditions

## Summary

Agent OS uses declarative conditional logic and decision trees that:
- Express flow control in natural language
- Make all paths explicit and traceable
- Handle errors through process logic
- Maintain state awareness
- Provide clear user communication
- Enable complex flows without scripts

This approach ensures reliable, understandable process coordination that can adapt to runtime conditions while remaining maintainable and debuggable.