# Enhanced Unified State Schema Design

> Based on Expert Analysis from Gemini thinkdeep
> Created: 2025-08-05

## Critical Design Refinement: Separate State from Audit Trail

### Problem with Original Design
Embedding the `history` array directly in the state object causes:
- State bloat as history grows
- Mixed concerns (current state vs audit trail)
- Potential KV size limit issues
- Inefficient reads for state-only operations

### Enhanced Architecture: KV + Stream Separation

#### 1. State Object (NATS KV)
Store current state at `[KEY_PREFIX]:cycle:[CYCLE_NUMBER]`:

```json
{
  "schema_version": "1.0",
  "sequence": 4,  // For optimistic locking
  "status": "EXECUTING",  // PLANNING, EXECUTING, EXPRESSING, REVIEWING, FAILED, COMPLETED
  "metadata": {
    "instruction_name": "create-spec",
    "spec_name": "feature-name",
    "cycle_number": 1,
    "key_prefix": "peer:spec:feature-name",
    "created_at": "2025-08-05T10:00:00Z",
    "last_updated_at": "2025-08-05T10:15:00Z"
  },
  "context": {
    // Shared data needed across phases
    "user_requirements": "Original user input",
    "instruction_args": "--spec=feature-name"
  },
  "phases": {
    "plan": {
      "status": "complete",  // pending, in_progress, complete, error
      "output": {
        /* plan content */
      },
      "started_at": "2025-08-05T10:00:00Z",
      "completed_at": "2025-08-05T10:05:00Z"
    },
    "execute": {
      "status": "in_progress",
      "output": {
        "checkpoint": {
          /* resumable state for executor */
        }
      },
      "started_at": "2025-08-05T10:05:00Z",
      "completed_at": null
    },
    "express": {
      "status": "pending"
    },
    "review": {
      "status": "pending"
    }
  },
  "error_info": {  // Populated on FAILED status
    "phase": "execute",
    "message": "Permission denied creating file",
    "details": {
      "file": "/protected/path",
      "operation": "write"
    }
  }
}
```

#### 2. Event Stream (NATS Stream)
Stream name: `agent-os-peer-events`
Subject pattern: `peer.events.[KEY_PREFIX].cycle.[CYCLE_NUMBER]`

Event structure:
```json
{
  "event_id": "uuid",
  "timestamp": "2025-08-05T10:05:00Z",
  "cycle_id": "peer:spec:feature-name:cycle:1",
  "phase": "plan",
  "event_type": "phase_completed",
  "sequence_before": 3,
  "sequence_after": 4,
  "details": {
    "duration_ms": 5000,
    "output_size": 2048
  }
}
```

### Benefits of Separation

1. **Lean State Object**: Remains small and focused
2. **Purpose-Built Tooling**: NATS Streams designed for append-only logs
3. **Decoupling**: Other systems can consume events without polling KV
4. **Performance**: Reduced read/write latency
5. **Debugging**: Time-based lookup and replay capabilities

## Control Flow for PEER Loops

### Challenge: Review → Re-plan → Re-execute
The PEER methodology implies potential loops when review phase determines quality issues.

### Solution: Conditional Transitions in Declarative Format

```xml
<process_flow>
  <!-- Review phase steps... -->
  
  <step name="finalize_review">
    <operation>analyze_review_output</operation>
    <output_to>review_decision</output_to>
  </step>
  
  <conditional_transition on_variable="review_decision.quality_ok">
    <case value="true">
      <action type="set_state_field" field="status" value="COMPLETED"/>
      <action type="publish_event" event="cycle_completed"/>
    </case>
    <case value="false">
      <action type="set_state_field" field="status" value="PLANNING"/>
      <action type="reset_phase" phase="plan"/>
      <action type="reset_phase" phase="execute"/>
      <action type="reset_phase" phase="express"/>
      <action type="publish_event" event="cycle_restarting"/>
    </case>
  </conditional_transition>
</process_flow>
```

### Declarative Action Vocabulary

```xml
<!-- State Manipulation Actions -->
<action type="set_state_field" field="path.to.field" value="new_value"/>
<action type="increment_field" field="path.to.counter" by="1"/>
<action type="append_to_array" field="path.to.array" value="item"/>

<!-- Phase Control Actions -->
<action type="reset_phase" phase="plan|execute|express|review"/>
<action type="mark_phase_complete" phase="plan"/>
<action type="checkpoint_progress" data="${current_progress}"/>

<!-- Event Publishing Actions -->
<action type="publish_event" event="event_name" details="${event_data}"/>
<action type="notify_parent" message="Phase complete"/>

<!-- Flow Control Actions -->
<action type="retry_step" step="previous_step" max_attempts="3"/>
<action type="skip_to_step" step="target_step"/>
<action type="fail_with_error" message="Error description"/>
```

## Implementation Roadmap

### Phase 1: Pilot with peer-planner
1. **Define Contracts**:
   ```xml
   <input_contract>
     <from_nats>
       bucket: agent-os-peer-state
       key: ${KEY_PREFIX}:cycle:${CYCLE_NUMBER}
       required_fields: [metadata, context, phases]
     </from_nats>
   </input_contract>
   
   <output_contract>
     <to_nats>
       bucket: agent-os-peer-state
       key: ${KEY_PREFIX}:cycle:${CYCLE_NUMBER}
       update_fields: [phases.plan, status]
       use_optimistic_lock: true
     </to_nats>
     <to_stream>
       stream: agent-os-peer-events
       subject: peer.events.${KEY_PREFIX}.cycle.${CYCLE_NUMBER}
       event: plan_completed
     </to_stream>
   </output_contract>
   ```

2. **Process Flow**:
   ```xml
   <process_flow>
     <step number="1" name="read_state">
       <nats_operation type="kv_read_with_sequence">
         <bucket>agent-os-peer-state</bucket>
         <key>${KEY_PREFIX}:cycle:${CYCLE_NUMBER}</key>
         <output_to>current_state</output_to>
       </nats_operation>
     </step>
     
     <step number="2" name="validate_planning_allowed">
       <validation>
         <check field="current_state.status" equals="PLANNING"/>
         <check field="current_state.phases.plan.status" not_equals="complete"/>
         <on_failure>
           <action type="fail_with_error" message="Invalid state for planning"/>
         </on_failure>
       </validation>
     </step>
     
     <step number="3" name="create_plan">
       <operation>analyze_instruction</operation>
       <input>${current_state.metadata.instruction_name}</input>
       <output_to>execution_plan</output_to>
     </step>
     
     <step number="4" name="update_state">
       <nats_operation type="kv_update_with_lock">
         <bucket>agent-os-peer-state</bucket>
         <key>${KEY_PREFIX}:cycle:${CYCLE_NUMBER}</key>
         <expected_sequence>${current_state.sequence}</expected_sequence>
         <updates>
           <set field="phases.plan.status" value="complete"/>
           <set field="phases.plan.output" value="${execution_plan}"/>
           <set field="phases.plan.completed_at" value="${timestamp}"/>
           <set field="status" value="EXECUTING"/>
           <increment field="sequence" by="1"/>
         </updates>
         <on_conflict>
           <retry max="3" backoff="exponential"/>
         </on_conflict>
       </nats_operation>
     </step>
     
     <step number="5" name="publish_event">
       <nats_operation type="stream_publish">
         <stream>agent-os-peer-events</stream>
         <subject>peer.events.${KEY_PREFIX}.cycle.${CYCLE_NUMBER}</subject>
         <message>
           {
             "event_type": "plan_completed",
             "phase": "plan",
             "timestamp": "${timestamp}",
             "cycle_id": "${KEY_PREFIX}:cycle:${CYCLE_NUMBER}"
           }
         </message>
       </nats_operation>
     </step>
   </process_flow>
   ```

### Phase 2: Extend to Other Agents
- Apply same pattern to peer-executor, peer-express, peer-review
- Ensure consistent state management across all agents
- Test phase transitions and error scenarios

### Phase 3: Full Integration
- Update peer.md to reference new state structure
- Test complete PEER cycles with loops
- Verify event stream for debugging

## Key Takeaways

1. **Separate Concerns**: State (KV) vs Audit Trail (Stream)
2. **Lean State**: Keep KV entries focused and small
3. **Rich Control Flow**: Support loops and conditionals declaratively
4. **Optimistic Locking**: Prevent lost updates with sequence checks
5. **Event-Driven**: Publish events for monitoring and debugging
6. **Checkpoint Support**: Enable resumable operations within phases
7. **Declarative Actions**: Rich vocabulary for state manipulation

This enhanced design addresses the core issues while maintaining the benefits of the unified state approach.