---
description: User Interaction Workflows for Git Commit Decision Points
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# User Interaction Workflows

## Overview

Declarative XML workflows for managing user decision points during complex git commit operations. These patterns handle dependency conflicts, branch strategy decisions, and conflict resolution guidance with clear visual presentations and structured choice handling.

<pre_flight_check>
  EXECUTE: @.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

## Multi-Branch File Dependency Decisions

<dependency_decision_workflow>
  
  <step number="1" name="detect_file_dependency_conflict">
    
    ### Step 1: Detect File Dependency Conflict
    
    <conflict_detection>
      <file_analysis>
        ANALYZE: all files across planned commits
        IDENTIFY: files that appear in multiple branch commits
        MAP: file-to-branch relationships
        DETECT: dependency complexity levels
      </file_analysis>
      
      <dependency_classification>
        <simple_dependency>
          FILE appears in 2 branches with same operation type
          CLASSIFICATION: standard dependency resolution needed
        </simple_dependency>
        
        <complex_dependency>
          FILE appears in 3+ branches OR mixed operations (add/delete)
          CLASSIFICATION: complex dependency requiring careful user guidance
        </complex_dependency>
        
        <circular_dependency>
          BRANCH A requires BRANCH B files, BRANCH B requires BRANCH A files
          CLASSIFICATION: circular dependency requiring strategy decision
        </circular_dependency>
      </dependency_classification>
      
      <trigger_evaluation>
        IF any files have dependencies:
          TRIGGER: user decision workflow
          PREPARE: visual decision tree presentation
          RECORD: dependency details for user context
      </trigger_evaluation>
    </conflict_detection>
    
  </step>
  
  <step number="2" name="present_visual_decision_tree">
    
    ### Step 2: Present Visual Decision Tree
    
    <visual_presentation>
      <ascii_diagram_generation>
        GENERATE: visual representation of branch dependencies
        TEMPLATE: 
        ```
        Current Situation:
        ┌─────────────────────────────────────────────────┐
        │ File "[filename]" needed by multiple branches   │
        │                                                 │
        │  [base_branch]     ──●──●                      │
        │                      \                          │
        │  [branch_1]           ●──●  (needs [filename]) │
        │                      \                          │
        │  [branch_2]           ●  (also needs [filename])│
        └─────────────────────────────────────────────────┘
                                  │
                                  ▼
                           ┌─────────────┐
                           │How to handle│
                           │shared file? │
                           └─────────────┘
                      /           |           \
                     ▼            ▼            ▼
            ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
            │Option 1:     │ │Option 2:     │ │Option 3:     │
            │Merge branch  │ │Create new    │ │Skip file     │
            │dependencies  │ │branch from   │ │(manual       │
            │first         │ │dependency    │ │resolution)   │
            └──────────────┘ └──────────────┘ └──────────────┘
        ```
        
        CUSTOMIZE: with actual branch names and file paths
        HIGHLIGHT: specific conflict areas
      </ascii_diagram_generation>
      
      <context_explanation>
        EXPLAIN: current repository state
        DESCRIBE: planned commit operations
        IDENTIFY: specific files causing dependencies
        CLARIFY: why user decision is needed
      </context_explanation>
    </visual_presentation>
    
  </step>
  
  <step number="3" name="present_decision_options">
    
    ### Step 3: Present Decision Options with Consequences
    
    <option_presentation>
      <merge_dependency_option>
        <option_id>merge_dependency</option_id>
        <label>Merge branch [dependency_branch] into [current_branch] first</label>
        
        <consequences>
          <immediate>
            DESCRIBE: "Merges dependency branch content into current branch"
            ACTION: "Creates unified branch with all changes"
          </immediate>
          
          <future>
            DESCRIBE: "Single branch contains all related changes"
            ACTION: "Simplified commit history, related work together"
          </future>
          
          <risks>
            LIST: 
              - "Potential merge conflicts requiring resolution"
              - "Larger changeset may be harder to review"
              - "Branch history becomes more complex"
          </risks>
          
          <benefits>
            LIST:
              - "Simplified workflow with unified changes"
              - "Related changes committed together"
              - "Easier to track feature completion"
          </benefits>
        </consequences>
      </merge_dependency_option>
      
      <create_new_branch_option>
        <option_id>create_new_branch</option_id>
        <label>Create new branch from [dependency_branch] for this work</label>
        
        <consequences>
          <immediate>
            DESCRIBE: "Creates isolated branch for new work based on dependency"
            ACTION: "Work continues on separate branch with dependency context"
          </immediate>
          
          <future>
            DESCRIBE: "Separate pull requests for each feature"
            ACTION: "Independent review and merge processes"
          </future>
          
          <risks>
            LIST:
              - "More complex merge process with multiple PRs"
              - "Potential conflicts when integrating multiple features"
              - "Additional coordination required between branches"
          </risks>
          
          <benefits>
            LIST:
              - "Smaller, focused commits easier to review"
              - "Independent feature development"
              - "Reduced risk of large conflicts"
          </benefits>
        </consequences>
      </create_new_branch_option>
      
      <skip_file_option>
        <option_id>skip_file</option_id>
        <label>Skip this file for now (manual handling required)</label>
        
        <consequences>
          <immediate>
            DESCRIBE: "File excluded from current commit plan"
            ACTION: "Execution continues without conflicted file"
          </immediate>
          
          <future>
            DESCRIBE: "Manual resolution required later"
            ACTION: "User must handle file separately after automation"
          </future>
          
          <risks>
            LIST:
              - "Incomplete implementation may cause issues"
              - "Manual work required to complete feature"
              - "Potential for forgotten file handling"
          </risks>
          
          <benefits>
            LIST:
              - "Avoids complex branching decisions now"
              - "Allows progression with most work"
              - "Defers complex decisions to later"
          </benefits>
        </consequences>
      </skip_file_option>
    </option_presentation>
    
  </step>
  
  <step number="4" name="capture_user_decision">
    
    ### Step 4: Capture and Validate User Decision
    
    <decision_capture>
      <user_prompt>
        DISPLAY: "Please choose your strategy:"
        OPTIONS:
          1. "[merge_dependency.label]"
          2. "[create_new_branch.label]"
          3. "[skip_file.label]"
        
        PROMPT: "Enter choice (1-3): "
        WAIT: for user input
        VALIDATE: input is valid option number
      </user_prompt>
      
      <input_validation>
        CHECK: input is numeric and in range 1-3
        IF invalid:
          ERROR: "Please enter 1, 2, or 3"
          RETRY: user prompt
        ELSE:
          MAP: numeric choice to option_id
          PROCEED: to confirmation step
      </input_validation>
      
      <choice_confirmation>
        DISPLAY: "You chose: [selected_option.label]"
        SHOW: selected option consequences
        CONFIRM: "Proceed with this strategy? (y/n): "
        
        IF user confirms:
          RECORD: decision in NATS state
          PROCEED: to execution
        ELSE:
          RETURN: to option presentation
      </choice_confirmation>
    </decision_capture>
    
  </step>
  
  <step number="5" name="execute_chosen_strategy">
    
    ### Step 5: Execute Chosen Strategy
    
    <strategy_execution>
      <merge_dependency_execution>
        <condition>option_id == "merge_dependency"</condition>
        <actions>
          NOTIFY: "Executing merge strategy..."
          COMMAND: git merge [dependency_branch]
          HANDLE: merge conflicts if they occur
          UPDATE: commit plan to reflect merged state
          RECORD: merge operation in NATS state
          CONTINUE: with modified execution plan
        </actions>
      </merge_dependency_execution>
      
      <create_new_branch_execution>
        <condition>option_id == "create_new_branch"</condition>
        <actions>
          GENERATE: new branch name (e.g., feature-[timestamp] or user-specified)
          COMMAND: git checkout -b [new_branch_name] [dependency_branch]
          UPDATE: commit plan to use new branch name
          RECORD: branch creation and strategy in NATS state
          CONTINUE: with modified execution plan
        </actions>
      </create_new_branch_execution>
      
      <skip_file_execution>
        <condition>option_id == "skip_file"</condition>
        <actions>
          REMOVE: conflicted file from affected commits
          RECORD: skipped files list in NATS state
          WARN: "File [filename] skipped - manual handling required"
          UPDATE: execution plan to exclude skipped files
          CONTINUE: with reduced scope execution plan
        </actions>
      </skip_file_execution>
    </strategy_execution>
    
  </step>
  
</dependency_decision_workflow>

## Conflict Resolution Guidance

<conflict_resolution_workflow>
  
  <step number="1" name="detect_conflict_state">
    
    ### Step 1: Detect Conflict State
    
    <conflict_identification>
      <git_conflict_detection>
        MONITOR: git command exit codes for conflict indicators
        PARSE: git output for "CONFLICT" messages
        IDENTIFY: files in conflicted state
        ANALYZE: conflict complexity and type
      </git_conflict_detection>
      
      <conflict_categorization>
        <merge_conflicts>
          TYPE: Content conflicts in file merging
          INDICATOR: "<<<<<<< HEAD" markers in files
          COMPLEXITY: Variable based on change overlap
        </merge_conflicts>
        
        <delete_modify_conflicts>
          TYPE: File deleted in one branch, modified in another
          INDICATOR: "deleted by us/them" messages
          COMPLEXITY: Requires decision on file fate
        </delete_modify_conflicts>
        
        <rename_conflicts>
          TYPE: File renamed differently in branches
          INDICATOR: "both modified" with different names
          COMPLEXITY: Requires name resolution decision
        </rename_conflicts>
      </conflict_categorization>
    </conflict_identification>
    
  </step>
  
  <step number="2" name="present_conflict_context">
    
    ### Step 2: Present Conflict Context
    
    <context_presentation>
      <conflict_summary>
        DISPLAY: "⚠️ Merge Conflicts Detected"
        LIST: conflicted files with conflict types
        SHOW: current branch and merge context
        EXPLAIN: why conflicts occurred
      </conflict_summary>
      
      <repository_state_explanation>
        DESCRIBE: "Current repository state:"
        DETAIL: "- Branch: [current_branch]"
        DETAIL: "- Conflicted files: [count] files need resolution"
        DETAIL: "- Uncommitted work: [saved in stash_ref]"
        DETAIL: "- Next step: Manual conflict resolution required"
      </repository_state_explanation>
      
      <conflict_file_details>
        FOR each conflicted file:
          SHOW: "File: [filepath]"
          DESCRIBE: "Conflict type: [conflict_type]"
          EXPLAIN: "Resolution needed: [resolution_guidance]"
          PROVIDE: "Conflict markers: Look for <<<<<<< and >>>>>>>"
      </conflict_file_details>
    </context_presentation>
    
  </step>
  
  <step number="3" name="provide_resolution_guidance">
    
    ### Step 3: Provide Step-by-Step Resolution Guidance
    
    <resolution_guidance>
      <step_by_step_instructions>
        TITLE: "🔧 Conflict Resolution Steps:"
        
        STEP 1:
          INSTRUCTION: "Review conflicted files in your editor"
          COMMAND: "Open each file: [list_conflicted_files]"
          GUIDANCE: "Look for conflict markers (<<<<<<< ======= >>>>>>>)"
          
        STEP 2:
          INSTRUCTION: "Edit files to resolve conflicts"
          GUIDANCE: "Choose which changes to keep or combine them"
          WARNING: "Remove all conflict markers (<<<<<<< ======= >>>>>>>)"
          
        STEP 3:
          INSTRUCTION: "Stage resolved files"
          COMMAND: "git add [resolved_files]"
          VERIFICATION: "Use 'git status' to confirm staging"
          
        STEP 4:
          INSTRUCTION: "Resume automated execution"
          COMMAND: "/peer --instruction=git-commit --continue"
          EXPLANATION: "This will restore stashed work and continue"
      </step_by_step_instructions>
      
      <helpful_commands>
        TITLE: "🛠️ Helpful Commands During Resolution:"
        
        COMMANDS:
          - "git status - See current conflict status"
          - "git diff - Review current changes"
          - "git add [file] - Stage resolved file"
          - "git reset [file] - Unstage file if needed"
          - "git checkout --ours [file] - Accept our version"
          - "git checkout --theirs [file] - Accept their version"
      </helpful_commands>
      
      <warning_notes>
        TITLE: "⚠️ Important Notes:"
        
        WARNINGS:
          - "Do not commit manually - use --continue to resume automation"
          - "Stashed work will be restored automatically when resuming"  
          - "All conflict markers must be removed before staging"
          - "NATS state preserves your progress - safe to take breaks"
      </warning_notes>
    </resolution_guidance>
    
  </step>
  
</conflict_resolution_workflow>

## Resume Capability User Interaction

<resume_interaction_workflow>
  
  <step number="1" name="detect_resumable_state">
    
    ### Step 1: Detect Resumable Execution State
    
    <resumable_detection>
      <state_discovery>
        SEARCH: NATS KV for keys matching "peer.commit.*"
        FILTER: states with status in ["in_progress", "paused_for_conflict"]
        COLLECT: resumable execution information
        SORT: by creation timestamp (newest first)
      </state_discovery>
      
      <state_analysis>
        FOR each resumable state:
          EXTRACT: execution metadata
          ANALYZE: progress completion percentage
          IDENTIFY: pause reason (conflict, interruption, etc.)
          DETERMINE: resume feasibility
      </state_analysis>
    </resumable_detection>
    
  </step>
  
  <step number="2" name="present_resume_options">
    
    ### Step 2: Present Resume Options to User
    
    <resume_presentation>
      <no_resumable_states>
        CONDITION: no incomplete executions found
        MESSAGE: "No incomplete git commit executions found to resume."
        GUIDANCE: "Start a new execution with: /peer --instruction=git-commit --plan=[filename]"
        ACTION: exit resume workflow
      </no_resumable_states>
      
      <single_resumable_state>
        CONDITION: exactly one incomplete execution found
        MESSAGE: "Found incomplete execution:"
        DETAILS:
          - "Execution ID: [execution_id]"
          - "Plan file: [plan_file]" 
          - "Progress: [completed_commits]/[total_commits] commits"
          - "Status: [current_status]"
          - "Paused: [pause_timestamp]"
        
        CONFIRMATION: "Resume this execution? (y/n): "
        
        IF confirmed:
          PROCEED: to resume execution
        ELSE:
          EXIT: resume workflow
      </single_resumable_state>
      
      <multiple_resumable_states>
        CONDITION: multiple incomplete executions found
        MESSAGE: "Multiple incomplete executions found:"
        
        DISPLAY: execution selection menu
        FOR each execution:
          SHOW: "[index]. [execution_id]"
          DETAILS: "   Plan: [plan_file]"
          DETAILS: "   Progress: [progress_summary]"
          DETAILS: "   Status: [status]"
          DETAILS: "   Created: [creation_time]"
          
        PROMPT: "Select execution to resume (1-[count]): "
        VALIDATE: user selection is valid
        MAP: selection to execution state
      </multiple_resumable_states>
    </resume_presentation>
    
  </step>
  
  <step number="3" name="validate_resume_conditions">
    
    ### Step 3: Validate Resume Conditions
    
    <resume_validation>
      <repository_state_check>
        VERIFY: current repository state supports resume
        CHECK: working directory is clean or conflicts resolved
        VALIDATE: current branch context matches saved state
        CONFIRM: no blocking issues prevent resumption
      </repository_state_check>
      
      <conflict_resolution_validation>
        IF saved state indicates conflict:
          CHECK: conflicts have been resolved
          VERIFY: no conflicted files remain
          CONFIRM: working directory is ready for continuation
          VALIDATE: user has completed manual resolution steps
      </conflict_resolution_validation>
      
      <plan_file_validation>
        VERIFY: original plan file still exists
        CHECK: plan file has not been modified since pause
        VALIDATE: execution context remains consistent
        CONFIRM: all preconditions for continuation are met
      </plan_file_validation>
    </resume_validation>
    
  </step>
  
</resume_interaction_workflow>

## User Decision State Management

<decision_state_workflow>
  
  <step number="1" name="record_decision_context">
    
    ### Step 1: Record Decision Context
    
    <context_recording>
      <decision_metadata>
        RECORD: in NATS state:
          - decision_type: type of decision required
          - decision_trigger: what caused the decision point
          - available_options: list of options presented
          - decision_context: relevant context information
          - decision_timestamp: when decision was requested
      </decision_metadata>
      
      <branch_dependency_context>
        IF decision involves branch dependencies:
          RECORD: specific dependency details:
            - conflicted_files: files causing dependency
            - affected_branches: branches involved in conflict
            - dependency_chain: sequence of branch dependencies
            - user_context: explanation provided to user
      </branch_dependency_context>
      
      <conflict_resolution_context>
        IF decision involves conflict resolution:
          RECORD: conflict-specific information:
            - conflict_type: nature of the conflict
            - conflicted_files: files requiring resolution
            - stash_context: stash information for preservation
            - resolution_guidance: instructions provided to user
      </conflict_resolution_context>
    </context_recording>
    
  </step>
  
  <step number="2" name="persist_user_choice">
    
    ### Step 2: Persist User Choice and Reasoning
    
    <choice_persistence>
      <decision_recording>
        STORE: in NATS state:
          - user_choice: selected option ID
          - choice_label: human-readable choice description
          - choice_timestamp: when decision was made
          - choice_reasoning: consequences user accepted
      </decision_recording>
      
      <execution_plan_updates>
        UPDATE: execution plan based on user choice:
          - modify branch strategies if needed
          - update file lists if files were skipped
          - adjust commit sequence if branches changed
          - record plan modifications with reasoning
      </execution_plan_updates>
      
      <audit_trail_maintenance>
        MAINTAIN: complete decision audit trail:
          - preserve original execution plan
          - record all decision points and choices
          - track plan modifications and their causes
          - enable decision review and learning
      </audit_trail_maintenance>
    </choice_persistence>
    
  </step>
  
</decision_state_workflow>

## Integration Points

<integration>
  <with_multi_branch_execution>
    TRIGGERED: by multi-branch-execution.md when dependencies detected
    PROVIDES: user decisions for branch strategy resolution
    RETURNS: modified execution plan based on user choices
  </with_multi_branch_execution>
  
  <with_state_management>
    USES: git-commit-state-management.md for all state persistence
    COORDINATES: decision context storage with execution state
    MAINTAINS: consistent state structure across decision workflows
  </with_state_management>
  
  <with_conflict_recovery>
    COORDINATES: with git-error-recovery.md for conflict handling
    PROVIDES: user guidance during conflict resolution
    SUPPORTS: resume operations after manual intervention
  </with_conflict_recovery>
</integration>

## Visual Presentation Standards

<visual_standards>
  <ascii_art_guidelines>
    USE: clean, readable ASCII diagrams for decision trees
    MAINTAIN: consistent formatting and alignment
    INCLUDE: clear labeling and directional flow
    ADAPT: diagram content to specific decision context
  </ascii_art_guidelines>
  
  <option_presentation_format>
    STRUCTURE: consistent option presentation with consequences
    INCLUDE: immediate, future, risks, and benefits for each option
    USE: clear numbering and labeling for user selection
    PROVIDE: sufficient detail for informed decision-making
  </option_presentation_format>
  
  <progress_indicators>
    SHOW: clear progress indicators during multi-step decisions
    DISPLAY: current step and total steps in decision process
    PROVIDE: context about decision placement in overall workflow
    MAINTAIN: user orientation throughout complex decision trees
  </progress_indicators>
</visual_standards>

## Notes

- All user interactions preserve complete context in NATS state for resume capability
- Visual decision trees adapt to specific branch and file contexts dynamically
- Decision workflows support both simple and complex dependency scenarios
- Conflict resolution guidance provides clear step-by-step instructions
- Resume capability maintains user context across system interruptions
- Decision audit trail enables learning and process improvement
- Integration points maintain clean separation with other workflow components