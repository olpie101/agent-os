---
description: Multi-Branch Git Execution Workflows for PEER Pattern
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Multi-Branch Execution

## Overview

Declarative XML workflows for executing git operations across multiple branches as specified in commit plans. These patterns handle branch creation, switching, file staging, and commit operations with comprehensive state tracking and conflict detection.

<pre_flight_check>
  EXECUTE: @.agent-os/instructions/meta/pre-flight.md
  ALSO_EXECUTE: @.agent-os/instructions/meta/git-commit-state-management.md
</pre_flight_check>

## Execution Context Initialization

<execution_initialization_workflow>
  
  <step number="1" name="analyze_execution_plan">
    
    ### Step 1: Analyze Execution Plan
    
    <plan_analysis>
      <branch_extraction>
        EXTRACT: unique branch names from all commits
        IDENTIFY: branch creation requirements
        ANALYZE: branch switching sequence
        RECORD: branch dependencies from requires_branches fields
      </branch_extraction>
      
      <commit_sequencing>
        ORDER: commits by branch dependencies
        RESOLVE: dependency chains between branches
        DETECT: circular dependencies (error condition)
        PLAN: optimal execution sequence
      </commit_sequencing>
      
      <file_dependency_analysis>
        IDENTIFY: files that appear in multiple commits
        MAP: file-to-branch relationships
        DETECT: potential conflicts between branch modifications
        PREPARE: user decision points for complex dependencies
      </file_dependency_analysis>
    </plan_analysis>
    
  </step>
  
  <step number="2" name="prepare_execution_environment">
    
    ### Step 2: Prepare Execution Environment
    
    <environment_preparation>
      <repository_state_check>
        VERIFY: working directory is clean
        CHECK: no uncommitted changes exist
        VALIDATE: current branch is known and safe
        RECORD: original branch for restoration
      </repository_state_check>
      
      <branch_availability_check>
        FOR each required branch:
          CHECK: if branch already exists locally
          VERIFY: branch is in sync with remote (if applicable)
          PLAN: branch creation or switching strategy
          RECORD: branch operation requirements
      </branch_availability_check>
      
      <git_environment_validation>
        VERIFY: git repository is in good state
        CHECK: remote connections if needed
        VALIDATE: user permissions for required operations
        CONFIRM: staging area is clean
      </git_environment_validation>
    </environment_preparation>
    
  </step>
  
</execution_initialization_workflow>

## Initial Stash Operations

<initial_stash_workflow>
  
  <step number="1" name="preserve_uncommitted_changes">
    
    ### Step 1: Preserve All Uncommitted Changes
    
    <stash_creation>
      <check_uncommitted>
        COMMAND: git status --porcelain
        IF output is not empty:
          PROCEED: to stash all changes
          RECORD: list of uncommitted files for tracking
        ELSE:
          SKIP: no changes to preserve
          NOTE: Clean working directory
      </check_uncommitted>
      
      <create_initial_stash>
        <stash_message>
          FORMAT: "PEER-git-commit: initial stash for [plan_id] execution"
          INCLUDE: timestamp and execution mode (full/partial)
          EXAMPLE: "PEER-git-commit: initial stash for 2025-08-13-19-00 execution"
        </stash_message>
        
        <stash_command>
          COMMAND: git stash push -m "[stash_message]" --include-untracked
          VERIFY: stash created successfully
          CAPTURE: stash reference (e.g., stash@{0})
          RECORD: in NATS state as "initial_stash_ref"
          NOTE: Working directory now clean for branch operations
        </stash_command>
      </create_initial_stash>
    </stash_creation>
    
  </step>
  
</initial_stash_workflow>

## Partial Execution Support

<partial_execution_workflow>
  
  <step number="1" name="handle_branch_flag">
    
    ### Step 1: Process --branch Flag
    
    <branch_flag_detection>
      IF --branch flag provided:
        SET: execution_mode = "partial"
        FILTER: commit plan to only include specified branch
        RECORD: partial execution context in NATS state
      ELSE:
        SET: execution_mode = "full"
        PROCESS: all branches in commit plan
    </branch_flag_detection>
    
  </step>
  
  <step number="2" name="post_execution_restoration">
    
    ### Step 2: Restore Files After Partial Execution
    
    <restoration_logic>
      IF execution_mode == "partial":
        <restore_original_files>
          RETRIEVE: initial_stash_ref from NATS state
          COMMAND: git stash pop [initial_stash_ref]
          HANDLE: any merge conflicts during restoration
          VERIFY: uncommitted files restored to working directory
          NOTE: User's original work preserved
        </restore_original_files>
      ELSE IF execution_mode == "full":
        <preserve_stash>
          INFORM: User that original files remain in stash
          PROVIDE: stash reference for manual recovery
          NOTE: git stash list to view, git stash pop to restore
        </preserve_stash>
    </restoration_logic>
    
  </step>
  
</partial_execution_workflow>

## Branch Management Operations

<branch_management_workflow>
  
  <step number="1" name="branch_creation_and_switching">
    
    ### Step 1: Branch Creation and Switching
    
    <branch_operations>
      <branch_existence_check>
        FOR target branch in current commit:
          CHECK: git branch --list [branch_name]
          IF branch exists:
            PROCEED: to branch switching
          ELSE:
            PROCEED: to branch creation
      </branch_existence_check>
      
      <branch_creation>
        <new_branch_creation>
          COMMAND: git checkout -b [branch_name]
          VERIFY: branch created successfully
          UPDATE: current_branch in NATS state
          RECORD: branch creation in execution log
        </new_branch_creation>
        
        <creation_validation>
          CONFIRM: new branch is active
          VERIFY: branch points to correct commit
          CHECK: working directory state
          UPDATE: NATS state with branch context
        </creation_validation>
      </branch_creation>
      
      <branch_switching>
        <existing_branch_switch>
          COMMAND: git checkout [branch_name]
          HANDLE: any switching conflicts or issues
          VERIFY: switch completed successfully
          UPDATE: current_branch in NATS state
        </existing_branch_switch>
        
        <switch_validation>
          CONFIRM: correct branch is now active
          VERIFY: working directory reflects branch state
          CHECK: no unexpected file changes
          RECORD: branch switch in execution log
        </switch_validation>
      </branch_switching>
    </branch_operations>
    
  </step>
  
  <step number="2" name="dependency_resolution">
    
    ### Step 2: Branch Dependency Resolution
    
    <dependency_handling>
      <requires_branches_check>
        IF commit has requires_branches field:
          FOR each required branch:
            VERIFY: branch exists and is accessible
            CHECK: merge status with current branch
            ANALYZE: potential conflicts
      </requires_branches_check>
      
      <dependency_strategies>
        <merge_dependency_strategy>
          <condition>User chooses to merge dependency first</condition>
          <actions>
            EXECUTE: git merge [dependency_branch]
            HANDLE: merge conflicts if they occur
            UPDATE: NATS state with merge operation
            RECORD: dependency resolution method
          </actions>
        </merge_dependency_strategy>
        
        <new_branch_strategy>
          <condition>User chooses to create new branch from dependency</condition>
          <actions>
            CREATE: new branch from dependency: git checkout -b [new_name] [dependency]
            UPDATE: commit plan to use new branch name
            RECORD: branch strategy change
            CONTINUE: with modified plan
          </actions>
        </new_branch_strategy>
        
        <skip_file_strategy>
          <condition>User chooses to skip conflicted files</condition>
          <actions>
            FILTER: files from current commit
            RECORD: skipped files in execution log
            WARN: about incomplete implementation
            CONTINUE: with reduced file set
          </actions>
        </skip_file_strategy>
      </dependency_strategies>
    </dependency_handling>
    
  </step>
  
</branch_management_workflow>

## File Staging and Commit Operations

<file_staging_workflow>
  
  <step number="1" name="file_existence_validation">
    
    ### Step 1: File Existence Validation
    
    <file_validation>
      <file_checks>
        FOR each file in commit.files:
          CHECK: file exists in working directory
          VERIFY: file has actual changes (git status)
          VALIDATE: file is not in .gitignore
          RECORD: file status for staging
      </file_checks>
      
      <missing_file_handling>
        FOR files that don't exist:
          WARN: "File [filepath] not found or unchanged"
          RECORD: warning in NATS state
          OPTION: continue without file or abort execution
          LOG: missing file details for user review
      </missing_file_handling>
      
      <deletion_handling>
        IF commit has deletions array:
          FOR each file in deletions:
            CHECK: file exists for deletion
            VERIFY: file is tracked by git
            PREPARE: deletion operation
            RECORD: deletion plan in execution log
      </deletion_handling>
    </file_validation>
    
  </step>
  
  <step number="2" name="staging_operations">
    
    ### Step 2: File Staging Operations
    
    <staging_process>
      <add_operations>
        FOR each valid file in commit.files:
          COMMAND: git add [filepath]
          VERIFY: staging completed successfully
          CHECK: staged changes match expectations
          RECORD: staged file in NATS state current_commit_files
      </add_operations>
      
      <deletion_operations>
        IF deletions array present:
          FOR each file in deletions:
            COMMAND: git rm [filepath]
            VERIFY: deletion staged successfully
            RECORD: deletion operation in execution log
            UPDATE: current_commit_files with deletion marker
      </deletion_operations>
      
      <staging_validation>
        VERIFY: git status shows expected staged changes
        CHECK: no unintended files are staged
        CONFIRM: staged changes match commit specification
        VALIDATE: staging area state is correct for commit
      </staging_validation>
    </staging_process>
    
  </step>
  
  <step number="3" name="commit_creation">
    
    ### Step 3: Commit Creation with Conflict Detection
    
    <commit_operations>
      <pre_commit_validation>
        VERIFY: staging area contains expected changes
        CHECK: commit message is valid and non-empty
        VALIDATE: no obvious conflicts or issues
        CONFIRM: ready for commit creation
      </pre_commit_validation>
      
      <commit_execution>
        <commit_attempt>
          COMMAND: git commit -m "[commit.message]"
          CAPTURE: command output and exit code
          RECORD: commit attempt in execution log
          PREPARE: for success or failure handling
        </commit_attempt>
        
        <success_handling>
          IF commit succeeds:
            CAPTURE: new commit hash
            UPDATE: NATS state with successful commit
            INCREMENT: progress counters
            RECORD: commit hash in completed_commits array
            PROCEED: to next commit in plan
        </success_handling>
        
        <conflict_handling>
          IF merge conflicts detected:
            TRIGGER: conflict resolution workflow
            CREATE: descriptive stash for remaining files
            UPDATE: NATS state to paused_for_conflict
            PROVIDE: user with resolution instructions
            STOP: execution with resume capability
        </conflict_handling>
      </commit_execution>
    </commit_operations>
    
  </step>
  
</file_staging_workflow>

## Conflict Detection and Recovery

<conflict_detection_workflow>
  
  <step number="1" name="conflict_identification">
    
    ### Step 1: Identify Conflict Conditions
    
    <conflict_detection>
      <git_error_analysis>
        MONITOR: git command exit codes
        PARSE: error messages for conflict indicators
        DETECT: patterns like "CONFLICT", "merge failed", "conflicts"
        IDENTIFY: specific files with conflicts
      </git_error_analysis>
      
      <conflict_type_classification>
        <merge_conflicts>
          DETECT: conflicts during branch merging
          IDENTIFY: conflicted file sections
          ANALYZE: conflict complexity and resolution difficulty
        </merge_conflicts>
        
        <staging_conflicts>
          DETECT: conflicts during file staging
          IDENTIFY: files that can't be staged cleanly
          ANALYZE: overlapping changes from different sources
        </staging_conflicts>
        
        <commit_conflicts>
          DETECT: conflicts during commit creation
          IDENTIFY: pre-commit hook failures or validation issues
          ANALYZE: commit message or content problems
        </commit_conflicts>
      </conflict_type_classification>
    </conflict_detection>
    
  </step>
  
  <step number="2" name="conflict_state_preservation">
    
    ### Step 2: Preserve State During Conflicts
    
    <state_preservation>
      <working_directory_cleanup>
        ASSESS: current working directory state
        IDENTIFY: uncommitted changes that need preservation
        DETERMINE: safest cleanup strategy
        PREPARE: for stash creation
      </working_directory_cleanup>
      
      <stash_creation_with_labeling>
        <stash_message_generation>
          FORMAT: "PEER-git-commit: remaining files from [branch-name]"
          INCLUDE: branch context and conflict details
          EXAMPLE: "PEER-git-commit: remaining files from feature/auth"
        </stash_message_generation>
        
        <stash_operation>
          COMMAND: git stash push -m "[stash_message]" --include-untracked
          VERIFY: stash creation succeeded
          CAPTURE: stash reference (stash@{0})
          RECORD: stash details in NATS conflict_context
        </stash_operation>
      </stash_creation_with_labeling>
      
      <conflict_context_recording>
        UPDATE: NATS state with conflict information:
          - conflicted_files: array of file paths with conflicts
          - stash_ref: reference to created stash
          - stash_message: descriptive stash message
          - resolution_branch: current branch during conflict
          - conflict_type: classification of conflict type
        SET: status to "paused_for_conflict"
        TIMESTAMP: conflict occurrence for reference
      </conflict_context_recording>
    </state_preservation>
    
  </step>
  
  <step number="3" name="user_guidance_provision">
    
    ### Step 3: Provide User Conflict Resolution Guidance
    
    <user_guidance>
      <conflict_summary_display>
        DISPLAY: clear conflict summary:
          - Number of conflicted files
          - Branch context and operations attempted
          - Stash reference for preserved work
          - Current repository state
      </conflict_summary_display>
      
      <resolution_instructions>
        PROVIDE: step-by-step resolution guidance:
          1. "Review conflicted files: [list_files]"
          2. "Resolve conflicts manually using your preferred editor"
          3. "Stage resolved files: git add [resolved_files]"
          4. "Resume execution: /peer --instruction=git-commit --continue"
      </resolution_instructions>
      
      <context_preservation_note>
        INFORM: user about preserved state:
          - "Uncommitted changes saved in stash: [stash_ref]"
          - "Resume will restore stash and continue from current step"
          - "NATS state preserved for complete recovery"
      </context_preservation_note>
    </user_guidance>
    
  </step>
  
</conflict_detection_workflow>

## Resume and Recovery Operations

<resume_workflow>
  
  <step number="1" name="conflict_resolution_validation">
    
    ### Step 1: Validate Conflict Resolution
    
    <resolution_validation>
      <git_status_check>
        CHECK: git status for conflicted files
        VERIFY: no files remain in conflicted state
        CONFIRM: working directory is clean or properly staged
        VALIDATE: resolution appears complete
      </git_status_check>
      
      <stash_restoration_check>
        IF stash exists from conflict context:
          EVALUATE: whether stash restoration is needed
          CHECK: if user resolved conflicts manually
          DETERMINE: best restoration strategy
          PREPARE: for stash application if needed
      </stash_restoration_check>
      
      <execution_readiness>
        VERIFY: repository is ready for continued execution
        CHECK: current branch matches expected state
        VALIDATE: no unexpected changes or issues
        CONFIRM: safe to proceed with remaining commits
      </execution_readiness>
    </resolution_validation>
    
  </step>
  
  <step number="2" name="restore_execution_context">
    
    ### Step 2: Restore Execution Context
    
    <context_restoration>
      <state_reconstruction>
        LOAD: saved execution state from NATS KV
        RESTORE: progress counters and commit tracking
        REBUILD: execution plan from saved progress
        IDENTIFY: next commit to execute
      </state_reconstruction>
      
      <stash_restoration>
        IF stash restoration needed:
          COMMAND: git stash pop [stash_ref]
          HANDLE: any restoration conflicts
          VERIFY: stash applied successfully
          CLEAN UP: stash reference if fully restored
      </stash_restoration>
      
      <branch_context_restoration>
        VERIFY: correct branch is active
        RESTORE: any branch-specific context
        VALIDATE: working directory state matches expectations
        PREPARE: for continued execution
      </branch_context_restoration>
    </context_restoration>
    
  </step>
  
  <step number="3" name="continue_execution">
    
    ### Step 3: Continue Multi-Branch Execution
    
    <execution_continuation>
      <progress_reconstruction>
        CALCULATE: remaining commits from saved state
        REBUILD: file staging and commit queue
        UPDATE: progress tracking in NATS state
        RESUME: from last successful commit
      </progress_reconstruction>
      
      <normal_execution_flow>
        RETURN: to main execution workflow
        CONTINUE: with branch management and file operations
        MAINTAIN: conflict detection for remaining commits
        TRACK: progress through NATS state updates
      </normal_execution_flow>
      
      <completion_handling>
        WHEN: all requested commits completed:
          DETERMINE: if partial execution (--branch flag)
          IF partial execution:
            RESTORE: original stashed files to working directory
            UPDATE: NATS state to "partial_completed"
          ELSE:
            UPDATE: NATS state to "completed"
            NOTE: Original stash preserved for user access
          RECORD: final execution summary
          PROVIDE: success summary to user
      </completion_handling>
    </execution_continuation>
    
  </step>
  
</resume_workflow>

## Execution Progress Tracking

<progress_tracking>
  
  <commit_level_tracking>
    UPDATE: after each successful commit:
      - Increment progress.current_step
      - Add commit hash to progress.completed_commits
      - Decrement progress.remaining_commits  
      - Update progress.current_commit_files
  </commit_level_tracking>
  
  <branch_level_tracking>
    RECORD: branch operations and switches
    TRACK: branch creation and modification history
    MAINTAIN: branch context for conflict resolution
    UPDATE: current_branch field with each switch
  </branch_level_tracking>
  
  <file_level_tracking>
    MONITOR: file staging and commit inclusion
    RECORD: files successfully committed vs skipped
    TRACK: deletion operations and their completion
    MAINTAIN: file operation audit trail
  </file_level_tracking>
  
  <state_persistence>
    UPDATE: NATS state after each significant operation
    ENSURE: state contains sufficient context for resume
    VALIDATE: state updates succeed before proceeding
    PROVIDE: comprehensive execution audit trail
  </state_persistence>
  
</progress_tracking>

## Error Handling and Recovery

<error_handling>
  
  <transient_errors>
    <git_command_failures>
      RETRY: failed git commands up to 3 times
      IMPLEMENT: exponential backoff between retries
      LOG: retry attempts and outcomes
      ESCALATE: to permanent error handling if retries exhausted
    </git_command_failures>
    
    <network_connectivity>
      DETECT: network-related git failures
      WAIT: for connectivity restoration
      RETRY: remote operations with timeout
      FALLBACK: to local-only operations if possible
    </network_connectivity>
    
    <file_system_locks>
      HANDLE: temporary file locks from other processes
      WAIT: brief period for lock resolution
      RETRY: file operations after delay
      ERROR: if locks persist beyond reasonable time
    </file_system_locks>
  </transient_errors>
  
  <permanent_errors>
    <repository_corruption>
      DETECT: git repository integrity issues
      PRESERVE: current state in NATS
      ERROR: with clear recovery instructions
      RECOMMEND: manual git repository repair
    </repository_corruption>
    
    <permission_errors>
      IDENTIFY: insufficient permissions for git operations
      PRESERVE: execution state for later resume
      PROVIDE: specific permission requirements
      GUIDE: user through permission resolution
    </permission_errors>
    
    <invalid_operations>
      CATCH: logically impossible git operations
      ANALYZE: plan consistency issues
      REPORT: specific operation conflicts
      SUGGEST: plan corrections or alternatives
    </invalid_operations>
  </permanent_errors>
  
</error_handling>

## Integration Points

<integration>
  <with_git_commit_instruction>
    CALLED: from git-commit.md multi-branch execution steps
    COORDINATES: with git-workflow agent for final operations
    PROVIDES: detailed execution results and branch information
  </with_git_commit_instruction>
  
  <with_state_management>
    USES: git-commit-state-management.md for all state operations
    MAINTAINS: consistent state structure and validation
    COORDINATES: progress tracking and conflict state management
  </with_state_management>
  
  <with_user_interaction>
    TRIGGERS: user-interaction-workflows.md for dependency decisions
    COORDINATES: conflict resolution and user guidance
    PROVIDES: execution context for decision-making
  </with_user_interaction>
</integration>

## Performance Optimization

<performance>
  <batch_operations>
    GROUP: related file operations together
    MINIMIZE: redundant git status checks
    OPTIMIZE: branch switching frequency
    BATCH: similar git operations where possible
  </batch_operations>
  
  <state_update_efficiency>
    MINIMIZE: NATS KV update frequency
    BATCH: related state changes
    OPTIMIZE: JSON structure for performance
    REDUCE: network overhead for state operations
  </state_update_efficiency>
  
  <git_operation_optimization>
    USE: git plumbing commands where appropriate
    MINIMIZE: git command overhead
    OPTIMIZE: working directory operations
    REDUCE: unnecessary git repository scans
  </git_operation_optimization>
</performance>

## Success Criteria

<success_criteria>
  <partial_execution>
    - Requested branch commits executed successfully
    - Original uncommitted files restored to working directory
    - No data loss or file corruption
    - Execution state marked as "partial_completed"
  </partial_execution>
  
  <full_execution>
    - All plan commits executed successfully
    - Original files preserved in initial stash
    - Branch structure matches plan specification
    - Execution state marked as "completed"
  </full_execution>
  
  <both_modes>
    - NATS state accurately tracks progress
    - No unexpected file modifications
    - Proper stash management throughout
    - Clear user communication about file locations
  </both_modes>
</success_criteria>

## Notes

- Multi-branch execution maintains complete audit trail through NATS state
- Initial stash preserves all uncommitted changes before branch operations
- Partial execution (--branch flag) restores uncommitted files after completion
- Full execution preserves original files in stash for user recovery
- Conflict detection creates additional stashes without losing original work
- Resume capability works across interruptions and system restarts  
- Branch dependency resolution supports complex commit plan requirements
- File operations include both additions and deletions as specified
- Performance optimization balances thoroughness with execution speed
- Integration points maintain clean separation with other workflow components