# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-05-peer-agents-declarative-transformation/spec.md

> Created: 2025-08-05
> Version: 1.0.0

## Technical Requirements

### Subagent Transformation Requirements

- **peer-planner.md**: Replace bash script analysis with `<step>` XML-like blocks for context gathering, instruction analysis, and plan creation
- **peer-executor.md**: Convert script-based delegation to structured `<process_flow>` patterns using appropriate Agent OS instructions
- **peer-express.md**: Transform bash formatting logic to declarative presentation rules using XML-structured templates
- **peer-review.md**: Replace assessment scripts with structured evaluation criteria and scoring mechanisms

### State Management Architecture

- **Unified Schema**: Design single JSON structure containing all phase data, timestamps, and sequence numbers
- **Optimistic Locking**: Implement sequence-based updates where each state modification increments sequence number
- **State Validation**: Add JSON schema validation for state structure consistency across phases
- **Error Recovery**: Define rollback mechanisms for failed state updates

### NATS Operation Patterns

- **Declarative KV Operations**: Replace `nats kv put/get` bash calls with structured operation blocks
- **State Retrieval Logic**: Implement conditional logic for loading/creating state entries
- **Sequence Management**: Handle sequence number increments and conflict detection
- **Connection Error Handling**: Define retry patterns and error states for NATS operations

### Process Flow Integration

- **XML Step Structure**: Use `<step number="N" name="step_name">` patterns consistent with Agent OS instructions
- **Conditional Logic**: Implement `<conditional_logic>` blocks for phase-specific decision trees
- **Error Templates**: Define structured error messages and recovery instructions
- **Validation Patterns**: Add input validation and dependency checking within steps

## Approach

### Phase 1: State Schema Design

1. Analyze current state usage across all four subagents
2. Design unified JSON schema supporting all phase requirements
3. Define sequence number and optimistic locking patterns
4. Create state validation and migration logic

### Phase 2: Subagent Transformation

1. Transform peer-planner from script-based to declarative patterns
2. Convert peer-executor using structured instruction execution
3. Update peer-express with declarative presentation logic
4. Modify peer-review to use structured evaluation processes

### Phase 3: NATS Operation Integration

1. Replace bash NATS CLI calls with structured operation blocks
2. Implement optimistic locking for all state updates
3. Add error handling and retry patterns
4. Test concurrent access scenarios

### Phase 4: Validation and Testing

1. Verify all subagents work without bash dependencies
2. Test state consistency under concurrent access
3. Validate error handling and recovery mechanisms
4. Confirm integration with existing peer.md instruction

## External Dependencies

- No new external dependencies required
- Maintains compatibility with existing NATS KV bucket structure
- Uses existing Agent OS instruction patterns and XML-like syntax