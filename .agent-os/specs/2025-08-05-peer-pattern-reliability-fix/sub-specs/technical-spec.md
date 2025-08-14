# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-05-peer-pattern-reliability-fix/spec.md

## Process-Based Architecture Requirements

### XML-like Process Flow Structure
- Replace current script orchestration with `<process_flow>` containing numbered `<step>` elements
- Each step must follow Agent OS pattern: `<step number="X" subagent="agent-name" name="step_name">`
- Steps must include structured `<instructions>` blocks defining ACTION, REQUEST, WAIT, PROCESS directives
- Add conditional logic blocks: `<conditional_logic>`, `<decision_tree>`, `<validation_checkpoint>`
- Include flow control elements: `<if_condition>`, `<else_condition>`, `<proceed_to>`

### Subagent Coordination Pattern
- Step delegation must follow established pattern: specify subagent in step attribute
- Instructions must use REQUEST format for subagent communication
- Add proper context passing: planning output → executor → express → review
- Implement state validation between phases through process logic
- Remove all direct tool calls except reference examples

### NATS CLI Reference Commands
Following the `<notification_command>` pattern from execute-tasks.md:

```xml
<nats_health_check>
  nats kv ls --timeout=5s
</nats_health_check>

<nats_bucket_create>
  nats kv add agent-os-peer-state --replicas=3 --history=50 --description="PEER pattern state storage"
</nats_bucket_create>

<nats_kv_read>
  nats kv get agent-os-peer-state "key-name" --raw
</nats_kv_read>

<nats_kv_write>
  nats kv put agent-os-peer-state "key-name" "value"
</nats_kv_write>
```

These are reference examples only - actual NATS operations handled by subagents.

### Process Validation Requirements
- Add mandatory Execute phase validation before Express phase: conditional block checking execution completion
- Implement phase dependency verification: Express requires Execute, Review requires Express  
- Add deliverable validation: check required outputs exist before marking phases complete
- Create validation checkpoints preventing false success reporting through comprehensive process logic
- Include error handling through conditional flow rather than script exit codes

### Script Dependency Elimination
- Remove all `Bash` tool calls to `~/.agent-os/scripts/peer/*.sh` files
- Replace script functionality with process steps and subagent delegation
- Convert initialization logic to process validation and conditional flow
- Move argument parsing from scripts to process logic with decision trees
- Transform finalization from script validation to process completion verification

## Process Flow Design

### Argument Processing (Process Logic)
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

### Phase Coordination (Subagent Delegation)
```xml
<step number="1" subagent="peer-planner" name="planning_phase">
  <instructions>
    ACTION: Analyze target instruction and create execution plan
    REQUEST: "Plan execution for [INSTRUCTION] with context [CONTEXT]"
    VALIDATE: Planning output exists and is complete
    STORE: Planning results for executor consumption
  </instructions>
</step>

<step number="2" subagent="peer-executor" name="execution_phase">
  <conditional_logic>
    IF planning_output not available:
      ERROR: "Cannot execute without planning data"
      PROVIDE: Recovery instructions
    ELSE:
      PROCEED: With execution
  </conditional_logic>
  <instructions>
    ACTION: Execute planned instruction using Agent OS patterns
    REQUEST: "Execute [INSTRUCTION] using plan from step 1"
    VALIDATE: Execution completed and deliverables created
    STORE: Execution results for express consumption
  </instructions>
</step>
```

### Phase Validation (Conditional Logic)
```xml
<phase_validation>
  <execute_before_express>
    IF execution_phase not completed:
      SKIP express phase
      ERROR: "Express phase requires Execute completion"
      PROVIDE: Status check instructions
    ELSE:
      PROCEED: To express phase
  </execute_before_express>
</phase_validation>
```

## Implementation Standards

### Backward Compatibility
- Maintain existing NATS KV key naming conventions
- Preserve subagent interface contracts and communication patterns  
- Keep command line argument structure (--instruction, --continue, --spec)
- Ensure existing PEER cycles can be resumed with new process logic

### Error Handling Through Process Logic
- Replace script exit codes with conditional flow and decision trees
- Add specific error contexts through structured instruction blocks
- Include recovery instructions in error conditions
- Implement graceful degradation through alternative process paths

### Process Flexibility
- Design conditional branches for different instruction types
- Add decision trees for handling runtime conditions
- Include validation checkpoints that can adapt to different scenarios  
- Create process paths that can recover from partial failures through logic rather than scripts