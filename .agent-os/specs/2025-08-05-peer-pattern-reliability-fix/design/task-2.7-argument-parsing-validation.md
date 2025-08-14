# Task 2.7: Argument Parsing and Validation Through Process Logic

## Overview

This document details the argument parsing and validation logic implemented through declarative process flow, eliminating the need for external script dependencies.

## Argument Structure

### Supported Arguments
```
/peer --instruction=<name> [--spec=<name>]
/peer --continue
```

### Argument Rules
1. `--instruction` and `--continue` are mutually exclusive
2. One of them must be provided
3. `--spec` is optional and only valid with `--instruction`
4. Invalid combinations should provide clear error messages

## Process Logic Implementation

### Step 3: Argument Parsing and Validation

```xml
<step number="3" name="argument_parsing">

### Step 3: Parse and Validate Arguments

Parse command arguments to determine execution mode and validate required parameters.

<argument_structure>
  <supported_flags>
    - --instruction=<name>: The instruction to execute
    - --continue: Resume from last incomplete phase  
    - --spec=<name>: Explicitly specify spec (optional)
  </supported_flags>
  
  <mutual_exclusion>
    --instruction and --continue cannot be used together
  </mutual_exclusion>
</argument_structure>

<argument_validation>
  <required_parameters>
    ONE OF:
      - --instruction=<name>
      - --continue
  </required_parameters>
  
  <validation_logic>
    IF neither --instruction nor --continue provided:
      ERROR: "Must provide either --instruction or --continue"
      DISPLAY: "Usage: /peer --instruction=<name> [--spec=<name>]"
      DISPLAY: "   or: /peer --continue"
      STOP execution
      
    IF both --instruction and --continue provided:
      ERROR: "Cannot use both --instruction and --continue"
      DISPLAY: "Choose either:"
      DISPLAY: "  - Start new: /peer --instruction=<name>"
      DISPLAY: "  - Continue: /peer --continue"
      STOP execution
      
    IF --spec provided without --instruction:
      ERROR: "--spec can only be used with --instruction"
      DISPLAY: "Usage: /peer --instruction=<name> --spec=<spec-name>"
      STOP execution
  </validation_logic>
</argument_validation>

<argument_parsing>
  EXTRACT from command line:
    - INSTRUCTION_NAME: value of --instruction flag
    - CONTINUE_FLAG: presence of --continue flag
    - SPEC_NAME: value of --spec flag (optional)
  
  DETERMINE execution mode:
    IF CONTINUE_FLAG present:
      SET: PEER_MODE = "continue"
    ELSE:
      SET: PEER_MODE = "new"
      VALIDATE: INSTRUCTION_NAME is not empty
      IF INSTRUCTION_NAME is empty:
        ERROR: "Instruction name cannot be empty"
        STOP execution
</argument_parsing>

<instruction_validation>
  IF PEER_MODE is "new":
    CHECK: Instruction exists and is valid
    KNOWN_INSTRUCTIONS:
      - create-spec
      - execute-tasks  
      - analyze-product
      - plan-product
      - git-commit
      
    IF INSTRUCTION_NAME not in known instructions:
      WARN: "Unknown instruction: [INSTRUCTION_NAME]"
      ASK: "Do you want to proceed? (yes/no)"
      IF response is not "yes":
        STOP execution
</instruction_validation>

<context_variables>
  SET based on parsing:
    - PEER_MODE: "new" or "continue"
    - INSTRUCTION_NAME: from --instruction flag
    - SPEC_NAME: from --spec flag (optional)
    - CONTINUE_CYCLE: null (will be set in cycle initialization)
</context_variables>

<instructions>
  ACTION: Parse command line arguments
  VALIDATE: Ensure valid argument combination
  EXTRACT: Execution parameters
  STORE: Mode and parameters for subsequent steps
  PROCEED: To execution context determination
</instructions>

</step>
```

## Validation Patterns

### 1. Mutual Exclusion Pattern
```xml
<mutual_exclusion_check>
  COUNT provided flags:
    - instruction_provided = (--instruction is present)
    - continue_provided = (--continue is present)
  
  IF instruction_provided AND continue_provided:
    ERROR: "Conflicting flags"
    STOP execution
</mutual_exclusion_check>
```

### 2. Required Parameter Pattern
```xml
<required_check>
  IF NOT instruction_provided AND NOT continue_provided:
    ERROR: "Missing required flag"
    PROVIDE: Usage instructions
    STOP execution
</required_check>
```

### 3. Dependent Parameter Pattern
```xml
<dependency_check>
  IF --spec provided:
    IF NOT --instruction provided:
      ERROR: "Dependent flag without primary"
      STOP execution
</dependency_check>
```

### 4. Value Validation Pattern
```xml
<value_validation>
  IF --instruction provided:
    IF instruction_value is empty or null:
      ERROR: "Flag requires value"
      STOP execution
      
  IF --spec provided:
    IF spec_value is empty or null:
      ERROR: "Flag requires value"  
      STOP execution
</value_validation>
```

## Error Message Templates

### Missing Required Arguments
```
❌ Error: Must provide either --instruction or --continue

Usage:
  Start new PEER cycle:
    /peer --instruction=<name> [--spec=<name>]
    
  Continue existing cycle:
    /peer --continue
    
Examples:
  /peer --instruction=create-spec
  /peer --instruction=execute-tasks --spec=user-auth
  /peer --continue
```

### Conflicting Arguments
```
❌ Error: Cannot use both --instruction and --continue

Choose one:
  - Start new cycle: /peer --instruction=<name>
  - Continue cycle: /peer --continue
```

### Invalid Dependency
```
❌ Error: --spec can only be used with --instruction

Correct usage:
  /peer --instruction=<name> --spec=<spec-name>
```

### Empty Value
```
❌ Error: Instruction name cannot be empty

Please provide a valid instruction name:
  /peer --instruction=create-spec
```

## Integration with Process Flow

### Context Variables Set
After successful validation:
- `PEER_MODE`: Either "new" or "continue"
- `INSTRUCTION_NAME`: The instruction to execute (if new)
- `SPEC_NAME`: The spec name (if provided)

### Flow Control
- On validation success: PROCEED to step 4
- On validation failure: STOP execution with error

### State Preservation
No external state needed - all validation is stateless and based on provided arguments.

## Advantages of Process-Based Approach

### 1. Transparency
- All validation logic visible in instruction file
- Clear error conditions and messages
- Easy to understand flow

### 2. Maintainability
- Change validation by editing XML logic
- No script files to maintain
- Self-documenting structure

### 3. Reliability
- No script execution failures
- Consistent error handling
- Predictable behavior

### 4. Flexibility
- Easy to add new validations
- Can extend without touching scripts
- Clear extension points

## Testing Validation Logic

### Test Cases
1. No arguments → Error
2. Only --instruction → Success
3. Only --continue → Success  
4. Both --instruction and --continue → Error
5. --spec without --instruction → Error
6. --spec with --instruction → Success
7. Empty instruction value → Error
8. Unknown instruction → Warning + prompt

## Summary

This process-based argument parsing:
- Handles all validation through declarative logic
- Provides clear, helpful error messages
- Sets up context for subsequent steps
- Eliminates script dependencies
- Maintains flexibility for extensions

The implementation follows Agent OS patterns while ensuring robust argument handling.