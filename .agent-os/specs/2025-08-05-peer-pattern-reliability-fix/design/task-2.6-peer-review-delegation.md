# Task 2.6: Peer-Review Subagent Delegation

## Overview

This document defines the detailed step delegation for the peer-review subagent, ensuring quality assessment and continuous improvement insights from the PEER execution.

## Step Definition

```xml
<step number="10" subagent="peer-review" name="review_phase">

### Step 10: Review Phase

Use the peer-review subagent to assess execution quality and provide improvement recommendations.

<review_context>
  CYCLE_NUMBER: [CYCLE_NUMBER]
  KEY_PREFIX: [KEY_PREFIX]
  INSTRUCTION: [INSTRUCTION_NAME]
  ALL_PHASE_OUTPUTS: Available in NATS KV under [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:*
</review_context>

<review_considerations>
  FOR create-spec: 
    - Focus on spec completeness and clarity
    - Skip detailed quality review (user approval in Step 11 of create-spec)
    - Check documentation consistency
  FOR execute-tasks: 
    - Assess task completion thoroughness
    - Review code quality and test coverage
    - Evaluate implementation decisions
  FOR analyze-product: 
    - Evaluate analysis depth and breadth
    - Assess actionability of insights
    - Review strategic recommendations
  FOR plan-product:
    - Evaluate planning comprehensiveness
    - Assess feasibility and alignment
    - Review strategic decisions
  DEFAULT: 
    - General quality and completeness review
    - Process improvement opportunities
</review_considerations>

<instructions>
  ACTION: Use peer-review subagent
  REQUEST: "Review PEER execution quality and provide insights
            Cycle: [CYCLE_NUMBER]
            Instruction: [INSTRUCTION_NAME]
            
            Context:
            - NATS KV Bucket: agent-os-peer-state
            - All outputs at: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:*
            - Review all phases: planning, execution, express
            
            Review Requirements:
            1. Retrieve and analyze all phase outputs:
               - Planning: objectives, approach, expected outcomes
               - Execution: actual results, issues, completions
               - Express: presentation quality and accuracy
            
            2. Assess execution quality across dimensions:
               
               Completeness:
               - Were all planned objectives achieved?
               - Are deliverables complete and usable?
               - Any gaps or missing elements?
               
               Quality:
               - Does work meet Agent OS standards?
               - Are outputs well-structured and clear?
               - Technical correctness and best practices?
               
               Process:
               - Was the PEER pattern followed effectively?
               - Were phases well-coordinated?
               - Smooth transitions and state management?
               
               Efficiency:
               - Appropriate effort for outcomes?
               - Any unnecessary complexity?
               - Time and resource usage?
            
            3. Provide instruction-specific assessment:
               
               For create-spec:
               - Documentation completeness
               - Spec clarity and actionability
               - Task breakdown quality
               - Note: Detailed content review deferred to user
               
               For execute-tasks:
               - Code quality and patterns
               - Test coverage and quality
               - Implementation decisions
               - Performance considerations
               
               For analyze-product:
               - Analysis thoroughness
               - Insight quality and depth
               - Recommendation practicality
               - Strategic alignment
            
            4. Identify improvement opportunities:
               - What went well (reinforce)
               - What could be improved
               - Specific actionable suggestions
               - Process refinements
            
            5. Structure the review output:
               {
                 'summary': {
                   'overall_quality': 'excellent' | 'good' | 'adequate' | 'needs_improvement',
                   'objectives_met': boolean,
                   'key_strengths': string[],
                   'key_improvements': string[]
                 },
                 'detailed_assessment': {
                   'completeness_score': number (1-10),
                   'quality_score': number (1-10),
                   'process_score': number (1-10),
                   'efficiency_score': number (1-10)
                 },
                 'findings': [
                   {
                     'category': 'strength' | 'improvement' | 'issue',
                     'description': string,
                     'recommendation': string (if applicable)
                   }
                 ],
                 'lessons_learned': string[],
                 'future_recommendations': string[]
               }
            
            6. Create review presentation:
               # PEER Cycle Review
               
               ## Quality Assessment
               [Overall quality summary with scores]
               
               ## Strengths
               [What worked well]
               
               ## Areas for Improvement
               [Specific suggestions]
               
               ## Lessons Learned
               [Key takeaways for future cycles]
               
               ## Recommendations
               [Actionable next steps]
            
            7. Store review outputs in NATS KV:
               - Full review: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:review
               - Review summary: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:review_summary
               - Improvement actions: [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:improvements
            
            8. Focus on constructive feedback:
               - Celebrate successes
               - Frame improvements positively
               - Provide specific examples
               - Make recommendations actionable"
  
  WAIT: For review phase completion
  
  PROCESS: Present review insights to user
           Store review outputs in NATS KV
           Extract key improvements for future cycles
</instructions>

<review_principles>
  MAINTAIN:
    - Constructive and supportive tone
    - Focus on continuous improvement
    - Specific, actionable feedback
    - Recognition of good work
    - Learning-oriented approach
</review_principles>

<validation>
  AFTER review:
    CHECK: Review outputs stored in NATS KV
    VERIFY: All phases were assessed
    ENSURE: Actionable insights provided
    CONFIRM: Constructive tone maintained
</validation>

</step>
```

## Context Passing Details

### Input Context

The review agent receives:
1. **Complete Cycle Data**: All phase outputs
2. **Instruction Type**: For focused review
3. **Execution Context**: What was attempted
4. **Quality Baselines**: Agent OS standards

### Output Expectations

The review agent should produce:
1. **Quality Assessment**: Scored evaluation
2. **Key Findings**: Strengths and improvements
3. **Lessons Learned**: For future cycles
4. **Actionable Recommendations**: Next steps

### State Management

```
NATS KV Keys:
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:review        → Full review analysis
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:review_summary → Executive summary
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:improvements  → Actionable improvements
- [KEY_PREFIX]:cycle:[CYCLE_NUMBER]:phases_completed → Updated to include "review"
```

## Review Dimensions

### Completeness
- Planned vs achieved
- Deliverable quality
- Gap analysis

### Quality
- Technical excellence
- Best practices adherence
- Output clarity

### Process
- PEER pattern execution
- Phase coordination
- State management

### Efficiency
- Resource utilization
- Time management
- Complexity balance

## Instruction-Specific Focus

### create-spec Reviews
- Documentation structure
- Clarity of requirements
- Task organization
- (Defer content details to user review)

### execute-tasks Reviews
- Implementation quality
- Testing practices
- Code patterns
- Performance impacts

### analyze-product Reviews
- Analysis coverage
- Insight depth
- Recommendation quality
- Strategic value

## Review Output Format

### Summary Section
```
## Quality Assessment
Overall Quality: Good (7.5/10)
✅ All objectives met
📊 Completeness: 9/10
📊 Quality: 7/10
📊 Process: 8/10
📊 Efficiency: 6/10
```

### Findings Section
```
## Key Strengths
✅ Clear documentation structure
✅ Comprehensive test coverage
✅ Excellent error handling

## Areas for Improvement
🔧 Consider extracting common patterns
🔧 Add performance benchmarks
🔧 Enhance logging for debugging
```

## Quality Criteria

A successful review phase:
1. Provides balanced assessment
2. Identifies specific improvements
3. Recognizes good work
4. Offers actionable insights
5. Maintains positive tone
6. Supports learning

## Integration Considerations

### 1. Comprehensive Analysis
The review must:
- Access all phase outputs
- Correlate plan with results
- Assess holistic quality

### 2. Constructive Feedback
Focus on:
- What to reinforce
- What to improve
- How to improve
- Why it matters

### 3. Future Value
Ensure insights:
- Apply to future cycles
- Build on successes
- Address root causes
- Enable growth

## Summary

This delegation pattern ensures the peer-review:
- Performs comprehensive quality assessment
- Provides balanced, constructive feedback
- Identifies specific improvements
- Celebrates successes appropriately
- Stores insights for future use
- Supports continuous improvement

The detailed REQUEST ensures thorough review while maintaining a supportive, learning-oriented approach.