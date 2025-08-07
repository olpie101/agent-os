# Task 1.5: Error Handling Patterns in Process Flows

## Overview

This document analyzes error handling patterns in Agent OS process flows, demonstrating how errors are managed through declarative process logic rather than script exit codes or exceptions.

## Core Error Handling Principles

1. **Explicit Error Messages**: Clear, actionable error messages
2. **Recovery Instructions**: Always provide next steps
3. **Process-Based Recovery**: Handle errors through conditional logic
4. **User Communication**: Keep users informed of issues
5. **Graceful Degradation**: Continue when possible, stop when necessary

## Error Handling Patterns

### 1. Validation Error Pattern

```xml
<validation_logic>
  IF neither instruction nor continue provided:
    ERROR: "Must provide either --instruction or --continue"
  IF both instruction and continue provided:
    ERROR: "Cannot use both --instruction and --continue"
</validation_logic>
```

**Characteristics:**
- Clear error messages explaining the problem
- Validation happens early in the process
- Stops execution before invalid state

### 2. Availability Check Pattern

```xml
<error_handling>
  IF command fails:
    DISPLAY: "❌ NATS server is not available"
    PROVIDE: "Please ensure NATS server is running before using /peer"
    STOP execution
</error_handling>
```

**Characteristics:**
- Visual indicator (❌) for error state
- Actionable recovery instruction
- Clean process termination

### 3. Resource Creation Error Pattern

```xml
<error_handling>
  IF NATS not available:
    DISPLAY: "❌ Cannot connect to NATS server"
    STOP execution
  IF bucket creation fails:
    DISPLAY: "❌ Failed to create KV bucket. Check NATS server permissions"
    STOP execution
</error_handling>
```

**Characteristics:**
- Multiple error conditions handled separately
- Context-specific error messages
- Hints at possible causes (permissions)

### 4. Blocking Issue Pattern

From execute-tasks.md:
```xml
<error_protocols>
  <blocking_issues>
    - document in tasks.md
    - mark with ⚠️ emoji
    - include in summary
  </blocking_issues>
  <test_failures>
    - fix before proceeding
    - never commit broken tests
  </test_failures>
  <technical_roadblocks>
    - attempt 3 approaches
    - document if unresolved
    - seek user input
  </technical_roadblocks>
</error_protocols>
```

**Characteristics:**
- Different handling for different error types
- Documentation requirements for issues
- Clear escalation path

### 5. Conditional Recovery Pattern

```xml
<update_format>
  <completed>- [x] Task description</completed>
  <incomplete>- [ ] Task description</incomplete>
  <blocked>
    - [ ] Task description
    ⚠️ Blocking issue: [DESCRIPTION]
  </blocked>
</update_format>

<blocking_criteria>
  <attempts>maximum 3 different approaches</attempts>
  <action>document blocking issue</action>
  <emoji>⚠️</emoji>
</blocking_criteria>
```

**Characteristics:**
- Visual indicators for different states
- Retry logic with limits
- Documentation of blocking issues

### 6. User Interaction Error Pattern

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

<user_prompt>
  A development server is currently running.
  Should I shut it down before proceeding? (yes/no)
</user_prompt>
```

**Characteristics:**
- Proactive error prevention
- User choice for resolution
- Clear communication of issue

### 7. Graceful Degradation Pattern

```xml
<conditional_loading>
  IF roadmap.md NOT already in context:
    LOAD @.agent-os/product/roadmap.md
  ELSE:
    SKIP loading (use existing context)
</conditional_loading>
```

**Characteristics:**
- Handles missing resources gracefully
- Uses available data when possible
- Avoids redundant operations

### 8. Test Failure Handling Pattern

```xml
<failure_handling>
  <action>troubleshoot and fix</action>
  <priority>before proceeding</priority>
</failure_handling>

<test_execution>
  <order>
    1. Run entire test suite
    2. Fix any failures
  </order>
  <requirement>100% pass rate</requirement>
</test_execution>
```

**Characteristics:**
- Clear requirement (100% pass)
- Fix-before-proceed approach
- No option to ignore failures

## Error Communication Patterns

### 1. Visual Indicators
- ❌ - Error/failure
- ⚠️ - Warning/blocked
- ✅ - Success
- 🚀 - Completion

### 2. Message Structure
```
[INDICATOR] [ERROR DESCRIPTION]
[RECOVERY INSTRUCTION]
```

### 3. Context in Errors
- Include what was being attempted
- Explain why it failed
- Suggest how to fix

## Recovery Strategies

### 1. Retry with Limits
```xml
<technical_roadblocks>
  - attempt 3 approaches
  - document if unresolved
  - seek user input
</technical_roadblocks>
```

### 2. Alternative Paths
```xml
IF primary_method_fails:
  TRY alternative_method
  IF still_fails:
    DOCUMENT issue
    ASK user for guidance
```

### 3. Partial Completion
```xml
<exit_conditions>
  - All assigned tasks marked complete
  - User requests early termination
  - Blocking issue prevents continuation
</exit_conditions>
```

### 4. User Escalation
```xml
IF automated_resolution_fails:
  EXPLAIN situation to user
  ASK for guidance
  WAIT for user decision
```

## Error Prevention Patterns

### 1. Pre-flight Checks
- Validate environment before starting
- Check prerequisites
- Verify permissions

### 2. Conditional Execution
- Check state before actions
- Skip unnecessary operations
- Validate inputs early

### 3. Clear Contracts
- Define expected inputs
- Specify success criteria
- Document failure modes

## Best Practices

### 1. Always Provide Context
- What failed
- Why it failed
- What to do next

### 2. Fail Fast
- Validate early
- Stop on critical errors
- Don't cascade failures

### 3. Document Failures
- Log blocking issues
- Track attempted solutions
- Preserve error context

### 4. User-Friendly Messages
- Avoid technical jargon
- Provide actionable steps
- Use visual indicators

### 5. Recovery Over Retry
- Offer alternatives
- Guide manual intervention
- Preserve partial progress

## Anti-Patterns to Avoid

1. **Silent Failures**: Always communicate errors
2. **Cryptic Messages**: Use clear, helpful language
3. **No Recovery Path**: Always suggest next steps
4. **Infinite Retries**: Set reasonable limits
5. **Hidden State**: Make error conditions visible
6. **Script Exit Codes**: Use process logic instead

## Summary

Agent OS error handling follows these principles:
- **Declarative**: Errors handled through process logic
- **Communicative**: Clear messages with recovery steps
- **Preventive**: Pre-flight checks and validation
- **Recoverable**: Alternative paths and user escalation
- **Traceable**: Document issues and attempts
- **User-Centric**: Actionable guidance over technical details

This approach ensures robust error handling without relying on script mechanisms, making processes more reliable and maintainable.