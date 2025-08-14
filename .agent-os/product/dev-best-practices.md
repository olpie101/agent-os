# Development Best Practices

> Version: 1.0.0
> Last updated: 2025-08-13
> Scope: Agent OS project-specific development standards

## Context

This file contains Agent OS project-specific best practices that extend the global standards defined in @~/.agent-os/standards/best-practices.md. These practices apply specifically to Agent OS development work.

## Agent OS Specific Guidelines

### NATS Service Patterns

- **Key naming conventions:**
  - **MUST use dots (.) as delimiters** in NATS KV keys for optimal compatibility
  - Example: `peer.spec.user-auth.cycle.1` (correct format)
  - **AVOID colons (:)** as they can cause compatibility issues with some NATS clients
  - Use hierarchical naming to enable wildcard subscriptions and efficient key management
  - Pattern: `[category].[type].[identifier].[sub-identifier]`

### PEER Pattern Development

- Follow unified state schema defined in @~/.agent-os/instructions/meta/unified_state_schema.md
- All PEER agents must respect phase ownership rules
- Use wrapper scripts for NATS KV operations to ensure consistency
- Maintain backward compatibility when updating state schemas

### Schema Documentation

- All schemas must include version fields for evolution tracking
- Follow the pattern established in unified_state_schema.md for new schemas
- Document field constraints, usage examples, and validation rules
- Include migration notes when schema versions change

### XML Declarative Instruction Patterns

Agent OS uses XML-based declarative patterns for instruction documentation and workflow definition. These patterns provide structured, readable alternatives to bash scripting for complex logic.

#### When to Use XML vs Bash

**Use XML Declarative Patterns for:**
- Complex workflow definitions with multiple decision points
- User interaction patterns requiring structured options
- State management workflows with validation steps
- Multi-step processes that benefit from structured documentation
- Instructions that need clear visual organization

**Use Bash for:**
- Simple command execution
- Direct system operations
- Quick utility scripts
- One-off operations without complex logic

#### XML Pattern Examples

**Process Flow Structure:**
```xml
<process_flow>
  <step number="1" name="descriptive_name">
    ### Step 1: Clear Description
    
    <validation_logic>
      CHECK: condition to verify
      IF condition not met:
        ERROR: "clear error message"
        STOP execution
      ELSE:
        PROCEED to next step
    </validation_logic>
    
    <instructions>
      ACTION: what to do
      VALIDATE: what to check
      ERROR_HANDLING: how to handle failures
    </instructions>
  </step>
</process_flow>
```

**User Interaction Patterns:**
```xml
<user_interaction_workflow>
  <trigger_condition>when to show this interaction</trigger_condition>
  
  <presentation_flow>
    <display_step>
      <action>DISPLAY visual guide or information</action>
      <content>what to show to user</content>
    </display_step>
    
    <user_prompt>
      <option id="option_1">
        <label>User-friendly option label</label>
        <consequences>
          <immediate>what happens right away</immediate>
          <future>long-term implications</future>
          <risks>potential problems</risks>
          <benefits>advantages of this choice</benefits>
        </consequences>
      </option>
    </user_prompt>
    
    <execution_flow>
      <wait_step>
        <action>WAIT for user selection</action>
        <validation>ensure valid choice</validation>
      </wait_step>
    </execution_flow>
  </presentation_flow>
</user_interaction_workflow>
```

**State Management Operations:**
```xml
<state_operation_workflow>
  <read_step>
    <action>READ current state</action>
    <source>data source location</source>
    <validation>verify read succeeded</validation>
  </read_step>
  
  <modification_step>
    <action>UPDATE specific fields</action>
    <operation>what changes to make</operation>
    <safety_check>validation before changes</safety_check>
  </modification_step>
  
  <write_step>
    <action>WRITE updated state</action>
    <target>destination for updated data</target>
    <confirmation>verify write succeeded</confirmation>
  </write_step>
</state_operation_workflow>
```

#### XML Structure Guidelines

- Use descriptive element names that indicate purpose
- Include `<action>` tags to specify what should happen
- Add `<validation>` or `<safety_check>` elements for important verifications
- Use `<condition>` tags for decision logic
- Include `<instructions>` blocks for implementation guidance
- Nest elements logically to show relationships and dependencies

#### Integration with Agent OS Patterns

XML declarative patterns work alongside:
- **PEER Pattern:** Use XML for complex step definitions in peer agent instructions
- **State Management:** Structure state operations with clear read/modify/write patterns  
- **User Interactions:** Provide consistent user experience across all Agent OS instructions
- **Cross-References:** Enable clear navigation between related documentation

#### Best Practices for XML Instructions

1. **Clarity Over Brevity:** Use descriptive names even if they're longer
2. **Consistent Structure:** Follow established patterns across all instructions
3. **Action-Oriented:** Each step should have clear actions to take
4. **Error Handling:** Include error scenarios and recovery paths
5. **Cross-Referencing:** Link related documentation and schemas
6. **Validation Steps:** Include checks to ensure operations succeed

---

*These practices supplement the global Agent OS standards and should be followed for all Agent OS development work.*