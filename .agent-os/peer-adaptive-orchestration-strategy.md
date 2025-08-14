# PEER Pattern Adaptive Orchestration Strategy

> Created: 2025-08-11
> Status: Proposal
> Context: Analysis of PEER Cycle 4 execution

## Overview

Based on analysis of PEER pattern execution, this document proposes an adaptive orchestration approach to optimize the PEER process based on task complexity. The goal is to maintain robustness for complex tasks while reducing overhead for simple ones.

## Background

Current PEER process observations:
- ~6 NATS KV revisions per cycle (normal)
- All tasks receive same level of orchestration regardless of complexity
- Review phase generates extensive insights even for simple tasks
- Process is reliable but could be more efficient for simple tasks

## Adaptive Orchestration Approaches

### Approach 1: Instruction-Based Complexity Scoring

Define complexity tiers at the coordinator level based on instruction characteristics:

**SIMPLE (Tier 1)**
- Single file modifications
- No external dependencies  
- Clear success criteria
- Examples: update-config, fix-typo, add-comment

**MODERATE (Tier 2)**
- Multiple file modifications
- Some integration points
- Testing required
- Examples: create-spec, add-endpoint, refactor-function

**COMPLEX (Tier 3)**
- Cross-domain changes
- External service integration
- Performance/security critical
- Examples: execute-tasks, migrate-database, security-audit

**Implementation**: Coordinator determines tier during initialization and passes complexity tier in context for subagent adaptation.

### Approach 2: Progressive Complexity Detection

Let the Planning phase analyze and score complexity dynamically:

**Planning Phase Signals**:
- Number of files to modify
- Presence of external dependencies
- Risk assessment scores
- Number of subtasks generated
- Estimated duration

**Scoring Formula Example**:
```
complexity_score = (
    file_count * 0.2 +
    dependency_count * 0.3 +
    risk_level * 0.3 +
    subtask_count * 0.2
)
```

The planner adds complexity assessment to output:
```json
{
  "complexity_assessment": {
    "score": 7.5,
    "tier": "complex",
    "rationale": "Multiple service integrations with high risk"
  }
}
```

### Approach 3: Hybrid Adaptive Model (Recommended)

Combine static rules with dynamic assessment:

1. **Initial Classification** (Coordinator):
   - Base tier from instruction type
   - Override flags from user (e.g., `--thorough`, `--quick`)

2. **Refined Assessment** (Planner):
   - Adjust tier based on actual analysis
   - Can upgrade but not downgrade initial tier

3. **Phase Adaptations**:

**For SIMPLE tasks**:
- **Plan**: Abbreviated planning, checklist format
- **Execute**: Minimal progress updates
- **Express**: Bullet-point summary
- **Review**: Quality checklist only (no deep insights)

**For COMPLEX tasks**:
- **Plan**: Full risk analysis, detailed phases
- **Execute**: Granular progress tracking
- **Express**: Comprehensive documentation
- **Review**: Deep insights, patterns, recommendations

## Practical Adaptation Examples

### Review Phase Adaptations

**Simple Task Review**:
```json
{
  "quality_score": "PASS",
  "checklist": {
    "requirements_met": true,
    "tests_passing": true,
    "no_regressions": true
  },
  "duration": "< 30 seconds"
}
```

**Complex Task Review**:
```json
{
  "quality_score": 92,
  "detailed_scores": {...},
  "strengths": [...],
  "improvements": [...],
  "insights": {
    "patterns": {...},
    "learnings": [...],
    "recommendations": {...}
  },
  "duration": "2-3 minutes"
}
```

### State Update Adaptations

- **Simple**: Update only on phase completion (4 updates total)
- **Complex**: Update on significant milestones (current behavior)

## Implementation Path

### Phase 1: Classification System
1. Add complexity classification to coordinator's context determination
2. Use instruction name + simple heuristics initially
3. Pass tier in context for all phases to see

### Phase 2: Planner Enhancement
1. Have planner calculate complexity score based on its analysis
2. Include in plan output for downstream phases
3. Allow planner to upgrade (but not downgrade) initial tier

### Phase 3: Phase Adaptations
1. Start with Review phase (easiest to adapt)
2. Implement two templates: "checklist" vs "comprehensive"
3. Measure time savings and quality impact

### Phase 4: Fine-tuning
1. Adjust scoring weights based on actual execution data
2. Add user preference flags (`--thorough`, `--quick`)
3. Consider task history (repeated tasks could use lighter touch)

## Key Design Decisions

### Where to store complexity decision?
- In context object: `context.complexity_tier`
- Immutable once set by planner
- All phases can read and adapt

### How to handle edge cases?
- User can override with flags
- Default to higher tier when uncertain
- Allow "promotion" during execution if complexity emerges

### Measurement approach?
- Track actual vs estimated duration
- Monitor review insights value (user feedback)
- Measure state size correlation with complexity

## Benefits

1. **Efficiency**: Reduce overhead for simple tasks
2. **Scalability**: Handle more cycles without fatigue
3. **User Experience**: Faster feedback for simple operations
4. **Resource Optimization**: Less state storage and processing for simple tasks

## Risks and Mitigations

- **Risk**: Misclassification leading to inadequate review
  - **Mitigation**: Conservative defaults, allow tier promotion

- **Risk**: Added complexity in orchestration logic
  - **Mitigation**: Phased rollout, start with simple classification

- **Risk**: User confusion about varying output formats
  - **Mitigation**: Clear indication of tier in output

## Next Steps

1. Review and refine classification criteria
2. Prototype simple vs complex review templates
3. Test with real-world tasks of varying complexity
4. Gather metrics on time savings and quality impact

## Conclusion

Adaptive orchestration maintains the robustness of the current PEER pattern while optimizing for efficiency based on task complexity. The key is starting simple (basic classification) and evolving based on real usage patterns.