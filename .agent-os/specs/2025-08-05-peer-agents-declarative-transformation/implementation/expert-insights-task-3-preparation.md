# Expert Insights and Task 3 Preparation

> Based on Gemini thinkdeep Analysis
> Created: 2025-08-05

## Critical Architectural Refinements

### 1. State vs Artifacts Separation ⚠️

The expert analysis identified a critical issue: large outputs in the unified state object could exceed NATS KV limits (1MB) or become inefficient.

#### Refined Schema v1.1

```json
{
  "version": "1.1",
  "sequence": 4,
  "metadata": {
    "instruction_name": "create-web-server",
    "spec_name": "simple-http-api",
    "status": "in_progress",
    "current_phase": "execute"
  },
  "phases": {
    "plan": {
      "status": "complete",
      "output": {
        "plan_summary": "...",  // Small, structured output
        "phases_count": 3
      }
    },
    "execute": {
      "status": "in_progress",
      "current_step": "generate_scaffolding",  // Granular recovery
      "error_count": 0,
      "output": {
        // Large artifacts stored by reference
        "source_code_ref": "obj.agent-os-artifacts.cycle-XYZ.source-v1"
      }
    }
  }
}
```

#### Implementation for Task 3 (peer-executor)

```xml
<artifact_management>
  <large_output_handling>
    IF output_size > 100KB:
      <store_to_object_store>
        bucket: agent-os-artifacts
        key: cycle-${CYCLE_NUMBER}.${PHASE}.${TIMESTAMP}
      </store_to_object_store>
      <store_reference_in_state>
        field: phases.execute.output.artifact_ref
        value: ${object_store_key}
      </store_reference_in_state>
    ELSE:
      <store_inline>
        field: phases.execute.output
        value: ${output_data}
      </store_inline>
  </large_output_handling>
</artifact_management>
```

### 2. Enhanced Optimistic Locking with Bounded Backoff

The expert recommends bounded exponential backoff to prevent thundering herd problems:

```xml
<optimistic_locking_v2>
  <retry_strategy>
    <attempt number="1">
      <delay>10ms * 2^0 + random(0-10ms)</delay>
    </attempt>
    <attempt number="2">
      <delay>10ms * 2^1 + random(0-20ms)</delay>
    </attempt>
    <attempt number="3">
      <delay>10ms * 2^2 + random(0-40ms)</delay>
    </attempt>
    <attempt number="4">
      <delay>10ms * 2^3 + random(0-80ms)</delay>
    </attempt>
    <attempt number="5">
      <delay>10ms * 2^4 + random(0-160ms)</delay>
      <on_failure>
        <mark_phase_failed>true</mark_phase_failed>
        <escalate>true</escalate>
      </on_failure>
    </attempt>
  </retry_strategy>
</optimistic_locking_v2>
```

### 3. History Stream Instead of Embedded Array

Remove the history array from state and use NATS Stream:

```xml
<audit_trail_pattern>
  <on_state_update>
    <!-- Update KV state without history -->
    <nats_operation type="kv_update_with_lock">
      <bucket>agent-os-peer-state</bucket>
      <key>${STATE_KEY}</key>
      <data>${state_without_history}</data>
    </nats_operation>
    
    <!-- Publish to history stream -->
    <nats_operation type="stream_publish">
      <stream>agent-os-peer-state-history</stream>
      <subject>history.${KEY_PREFIX}.cycle.${CYCLE_NUMBER}</subject>
      <message>
        {
          "timestamp": "${ISO8601}",
          "sequence_before": ${old_sequence},
          "sequence_after": ${new_sequence},
          "state_snapshot": ${complete_state},
          "phase": "${current_phase}",
          "event": "state_update"
        }
      </message>
    </nats_operation>
  </on_state_update>
</audit_trail_pattern>
```

## Task 3 Implementation Strategy: peer-executor

### Key Challenges for peer-executor

1. **Delegating to Task Tool**: Most complex transformation
2. **Managing Execution State**: Tracking progress across potentially long operations
3. **Handling Partial Failures**: Recovery from interrupted execution
4. **Large Output Management**: Generated code could be substantial

### Recommended Approach

#### 1. Granular Status Tracking

```xml
<execution_state_tracking>
  <phase_level>
    status: pending|in_progress|complete|failed
  </phase_level>
  
  <step_level>
    current_step: string  <!-- Which instruction step -->
    step_status: pending|running|complete|error
    step_started_at: timestamp
    last_checkpoint: timestamp
  </step_level>
  
  <error_tracking>
    error_count: integer
    last_error: string
    recoverable: boolean
  </error_tracking>
</execution_state_tracking>
```

#### 2. Task Tool Delegation Pattern

```xml
<task_delegation>
  <prepare_context>
    <!-- Gather all needed context from state -->
    <read_plan>
      FROM: phases.plan.output
      EXTRACT: instruction_details
    </read_plan>
    
    <build_task_request>
      instruction: ${instruction_name}
      context: ${gathered_context}
      spec_name: ${spec_name}
    </build_task_request>
  </prepare_context>
  
  <delegate_to_task>
    <task_invocation>
      tool: Task
      subagent_type: ${target_instruction_agent}
      prompt: ${constructed_prompt}
    </task_invocation>
    
    <capture_output>
      IF size > 100KB:
        STORE to object store
        SAVE reference in state
      ELSE:
        STORE inline in state
    </capture_output>
  </delegate_to_task>
  
  <update_progress>
    <!-- Atomic state update with progress -->
    <checkpoint_data>
      step_completed: true
      output_captured: true
      next_step: ${next_step_id}
    </checkpoint_data>
  </update_progress>
</task_delegation>
```

#### 3. Recovery Pattern

```xml
<recovery_mechanism>
  <on_executor_start>
    <check_incomplete_execution>
      IF phases.execute.status == "in_progress":
        <examine_checkpoint>
          last_checkpoint: ${phases.execute.output.checkpoint}
          current_step: ${phases.execute.current_step}
        </examine_checkpoint>
        
        <recovery_decision>
          IF checkpoint_recent AND recoverable:
            RESUME from checkpoint
          ELSE:
            RESTART execution phase
        </recovery_decision>
    </check_incomplete_execution>
  </on_executor_start>
</recovery_mechanism>
```

## Task 3 Checklist

### Must Implement
- [ ] Remove all bash scripts from peer-executor
- [ ] Implement artifact storage for large outputs
- [ ] Add granular step tracking for recovery
- [ ] Use bounded exponential backoff
- [ ] Separate history to stream

### Should Implement
- [ ] Checkpoint mechanism for long operations
- [ ] Progress reporting during execution
- [ ] Error categorization (recoverable vs fatal)

### Nice to Have
- [ ] Execution time estimates
- [ ] Resource usage tracking
- [ ] Parallel step execution where possible

## PEER Review Loop Handling

For Task 5, handling the review → re-plan loop:

```xml
<peer_loop_control>
  <review_decision>
    <quality_assessment>
      score: 0-100
      threshold: 80
    </quality_assessment>
    
    <conditional_transition>
      IF score >= threshold:
        <action>mark_cycle_complete</action>
      ELSE:
        <action>initiate_replanning</action>
        <reset_phases>
          - plan.status = "pending"
          - execute.status = "pending"
          - express.status = "pending"
        </reset_phases>
        <preserve>
          - review.feedback
          - review.improvement_suggestions
        </preserve>
        <increment>
          - metadata.iteration_count
        </increment>
      </conditional_transition>
  </review_decision>
</peer_loop_control>
```

## Performance Optimization Recommendations

### 1. State Caching
```xml
<caching_strategy>
  <local_cache>
    TTL: 5 seconds
    invalidate_on: sequence_change
  </local_cache>
  
  <etag_support>
    IF_NONE_MATCH: ${cached_etag}
    RETURN: 304 if unchanged
  </etag_support>
</caching_strategy>
```

### 2. Batch Operations
```xml
<batch_updates>
  <collect_changes>
    duration: 100ms
    max_changes: 10
  </collect_changes>
  
  <apply_once>
    single_state_update: true
    combine_events: true
  </apply_once>
</batch_updates>
```

## Summary of Expert Recommendations

1. **Separate State from Artifacts**: Keep state lean, store large outputs in Object Store
2. **Use Bounded Exponential Backoff**: Prevent thundering herd with smart retry logic
3. **Move History to Stream**: Don't embed audit trail in state object
4. **Granular Status Tracking**: Enable recovery from any point
5. **Prepare for peer-executor Complexity**: It's the hardest transformation

These refinements will ensure the declarative transformation scales to production use while maintaining the benefits of the unified state design.

## Next Immediate Steps

1. **Update State Schema**: Incorporate v1.1 changes before Task 3
2. **Implement Object Store Pattern**: Add artifact management to peer-executor
3. **Create Recovery Tests**: Verify checkpoint/resume works correctly
4. **Document Task Delegation**: Clear pattern for Task tool invocation

With these insights, Task 3 (peer-executor transformation) can proceed with confidence.