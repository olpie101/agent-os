---
description: Git Commit State Management Workflows for PEER Pattern
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Git Commit State Management

## Overview

Declarative XML workflows for managing git commit execution state in NATS KV. These patterns enable persistent state tracking for complex multi-branch commit operations with resume capability and conflict handling.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
  ALSO_EXECUTE: @~/.agent-os/instructions/meta/nats-kv-operations.md
</pre_flight_check>

## State Key Format

<key_format>
  PATTERN: peer.commit.yyyy.mm.dd.hh.mm
  PURPOSE: Matches commit plan filename timestamp
  COMPATIBILITY: Uses dots for NATS KV compatibility
  EXAMPLE: peer.commit.2025.08.13.17.30
</key_format>

## State Creation Workflow

<state_creation_workflow>
  
  <step number="1" name="extract_timestamp_from_plan">
    
    ### Step 1: Extract Timestamp from Plan Filename
    
    <timestamp_extraction>
      <source_pattern>
        EXTRACT timestamp from plan filename format: YYYY-MM-DD-HH-MM-plan.(json|md)
        EXAMPLE: "2025-08-13-17-30-plan.md" → "2025.08.13.17.30"
      </source_pattern>
      
      <conversion_rules>
        REPLACE hyphens with dots for NATS compatibility
        VALIDATE timestamp format matches YYYY.MM.DD.HH.MM pattern
        FALLBACK to current timestamp if extraction fails
      </conversion_rules>
      
      <key_construction>
        COMBINE prefix with timestamp: "peer.commit." + timestamp
        RESULT: "peer.commit.2025.08.13.17.30"
      </key_construction>
    </timestamp_extraction>
    
  </step>
  
  <step number="2" name="initialize_state_object">
    
    ### Step 2: Initialize State Object
    
    <state_initialization>
      <base_structure>
        {
          "version": 1,
          "plan_file": "[plan_filename]",
          "plan_format": "[json|markdown]",
          "execution_id": "[state_key]",
          "status": "initialized",
          "execution_mode": "[full|partial]",
          "target_branch": "[branch_name_or_null]",
          "created_at": "[iso_timestamp]",
          "updated_at": "[iso_timestamp]",
          "current_branch": "[current_git_branch]",
          "original_branch": "[current_git_branch]",
          "initial_stash_ref": null,
          "initial_stash_message": null
        }
      </base_structure>
      
      <plan_metadata_extraction>
        EXTRACT from loaded plan:
          - expected_branches: list of all branch names in plan
          - total_commits: count of commit objects
          - commits_per_branch: group commits by target branch
          - source_format: "json" or "markdown" based on detection
          - execution_scope: "full" or "single_branch" based on --branch flag
        
        ADD stash management tracking:
          {
            "stash_management": {
              "initial_stash_required": true if uncommitted changes exist,
              "restoration_planned": true if partial execution,
              "conflict_stashes": []
            }
          }
      </plan_metadata_extraction>
      
      <progress_tracking_initialization>
        {
          "progress": {
            "current_step": 0,
            "total_steps": "[total_commits]",
            "completed_commits": [],
            "current_commit_files": [],
            "remaining_commits": "[total_commits]"
          }
        }
      </progress_tracking_initialization>
    </state_initialization>
    
  </step>
  
  <step number="3" name="store_initial_state">
    
    ### Step 3: Store Initial State in NATS KV
    
    <storage_operation>
      <validation_step>
        VALIDATE state object structure before storage
        ENSURE all required fields are present
        VERIFY JSON structure is valid
      </validation_step>
      
      <storage_command>
        USE: ~/.agent-os/scripts/peer/create-state.sh wrapper
        KEY: "[generated_state_key]"
        VALUE: "[complete_state_object]"
        
        EXAMPLE:
        RESULT=$(~/.agent-os/scripts/peer/create-state.sh "$STATE_KEY" "$INITIAL_STATE")
        if [ $? -ne 0 ]; then
          exit 1
        fi
      </storage_command>
      
      <success_validation>
        VERIFY key creation succeeded
        LOG state key for reference
        RETURN state key for subsequent operations
      </success_validation>
    </storage_operation>
    
  </step>
  
</state_creation_workflow>

## Progress Update Workflow

<progress_update_workflow>
  
  <step number="1" name="read_current_state">
    
    ### Step 1: Read Current State
    
    <read_operation>
      USE: ~/.agent-os/scripts/peer/read-state.sh wrapper
      KEY: "[state_key]"
      
      EXAMPLE:
      STATE=$(~/.agent-os/scripts/peer/read-state.sh "$STATE_KEY")
      if [ $? -ne 0 ]; then
        exit 1
      fi
    </read_operation>
    
  </step>
  
  <step number="2" name="update_progress_fields">
    
    ### Step 2: Update Progress Fields
    
    <progress_modifications>
      <commit_completion>
        INCREMENT: .progress.current_step
        ADD: commit hash to .progress.completed_commits array
        DECREMENT: .progress.remaining_commits
        UPDATE: .metadata.updated_at timestamp
      </commit_completion>
      
      <branch_context>
        UPDATE: .current_branch if branch switch occurred
        RECORD: branch operations in state history
      </branch_context>
      
      <file_tracking>
        UPDATE: .progress.current_commit_files with staged files
        CLEAR: after successful commit
        PRESERVE: during conflict resolution
      </file_tracking>
    </progress_modifications>
    
    <jq_filter_pattern>
      JQ_FILTER='
        .progress.current_step += 1 |
        .progress.completed_commits += [$commit_hash] |
        .progress.remaining_commits -= 1 |
        .progress.current_commit_files = $files |
        .current_branch = $branch |
        .metadata.updated_at = (now | todate)
      '
      
      --arg commit_hash "$COMMIT_HASH" \
      --argjson files "$FILES_JSON" \
      --arg branch "$CURRENT_BRANCH"
    </jq_filter_pattern>
    
  </step>
  
  <step number="3" name="write_updated_state">
    
    ### Step 3: Write Updated State
    
    <update_operation>
      USE: ~/.agent-os/scripts/peer/update-state.sh wrapper
      KEY: "[state_key]"
      FILTER: "[jq_filter]"
      ARGS: "[jq_arguments]"
      
      EXAMPLE:
      RESULT=$(~/.agent-os/scripts/peer/update-state.sh "$STATE_KEY" "$JQ_FILTER" \
        --arg commit_hash "$COMMIT_HASH" \
        --argjson files "$FILES_JSON")
      if [ $? -ne 0 ]; then
        exit 1
      fi
    </update_operation>
    
  </step>
  
</progress_update_workflow>

## Conflict State Management

<conflict_state_workflow>
  
  <step number="1" name="detect_conflict_condition">
    
    ### Step 1: Detect Conflict Condition
    
    <conflict_detection>
      <merge_conflict_indicators>
        GIT command returns non-zero exit code
        Git status shows conflicted files
        Error messages contain "CONFLICT" text
      </merge_conflict_indicators>
      
      <conflict_analysis>
        IDENTIFY conflicted files using git status
        EXTRACT conflict markers from files
        DETERMINE resolution complexity
      </conflict_analysis>
    </conflict_detection>
    
  </step>
  
  <step number="2" name="create_stash_with_label">
    
    ### Step 2: Create Descriptive Stash
    
    <stash_creation>
      <stash_message_format>
        TEMPLATE: "PEER-git-commit: remaining files from [branch-name]"
        EXAMPLE: "PEER-git-commit: remaining files from feature/auth"
      </stash_message_format>
      
      <stash_command>
        git stash push -m "[stash_message]" --include-untracked
        CAPTURE: stash reference (stash@{0})
      </stash_command>
      
      <stash_validation>
        VERIFY stash was created successfully
        RECORD stash reference for later restoration
      </stash_validation>
    </stash_creation>
    
  </step>
  
  <step number="3" name="update_conflict_state">
    
    ### Step 3: Update State for Conflict Resolution
    
    <conflict_state_update>
      <status_change>
        SET: .status = "paused_for_conflict"
        PRESERVE: all progress made so far
        TIMESTAMP: conflict occurrence time
      </status_change>
      
      <conflict_context>
        CREATE: .conflict_context object with:
          - conflicted_files: array of file paths
          - stash_ref: stash reference string
          - stash_message: descriptive stash message
          - resolution_branch: current branch name
      </conflict_context>
      
      <jq_filter_example>
        JQ_FILTER='
          .status = "paused_for_conflict" |
          .conflict_context = {
            "conflicted_files": $files,
            "stash_ref": $stash_ref,
            "stash_message": $stash_msg,
            "resolution_branch": $branch
          } |
          .metadata.updated_at = (now | todate)
        '
        
        --argjson files "$CONFLICTED_FILES" \
        --arg stash_ref "$STASH_REF" \
        --arg stash_msg "$STASH_MESSAGE" \
        --arg branch "$CURRENT_BRANCH"
      </jq_filter_example>
    </conflict_state_update>
    
  </step>
  
</conflict_state_workflow>

## Resume State Discovery

<resume_discovery_workflow>
  
  <step number="1" name="search_incomplete_executions">
    
    ### Step 1: Search for Incomplete Executions
    
    <execution_search>
      <key_pattern_search>
        SEARCH NATS KV for keys matching "peer.commit.*"
        USE: nats kv ls agent-os-peer-state | grep "peer.commit"
        FILTER: only keys with specific pattern
      </key_pattern_search>
      
      <state_validation>
        FOR each found key:
          READ state object using wrapper script
          CHECK .status field value
          IF status IN ["initialized", "in_progress", "paused_for_conflict"]:
            ADD to resumable_executions list
      </state_validation>
    </execution_search>
    
  </step>
  
  <step number="2" name="present_resumable_options">
    
    ### Step 2: Present Resumable Options
    
    <option_presentation>
      <no_executions_case>
        IF resumable_executions is empty:
          ERROR: "No incomplete git commit executions found"
          PROVIDE: "Start a new execution with --plan argument"
          STOP: execution workflow
      </no_executions_case>
      
      <single_execution_case>
        IF resumable_executions has 1 item:
          AUTOMATICALLY select the single execution
          NOTIFY: user of resumed execution details
          PROCEED: to state restoration
      </single_execution_case>
      
      <multiple_executions_case>
        IF resumable_executions has multiple items:
          DISPLAY: execution selection menu
          INCLUDE: for each execution:
            - Execution ID (state key)
            - Creation timestamp  
            - Current status
            - Progress summary (X of Y commits)
            - Plan file name
          WAIT: for user selection
          VALIDATE: user choice is valid
      </multiple_executions_case>
    </option_presentation>
    
  </step>
  
  <step number="3" name="restore_execution_context">
    
    ### Step 3: Restore Execution Context
    
    <context_restoration>
      <state_loading>
        READ complete state from selected execution key
        PARSE all execution context:
          - Original plan file and format
          - Current progress and completed commits
          - Branch context and file tracking
          - Conflict context if applicable
      </state_loading>
      
      <environment_preparation>
        VALIDATE current git branch matches expected state
        CHECK if stash restoration is needed
        VERIFY plan file still exists if referenced
        PREPARE for continuation from saved progress
      </environment_preparation>
      
      <resume_validation>
        IF conflict state detected:
          VERIFY stash reference still exists
          PROVIDE conflict resolution instructions
          PREPARE for user conflict resolution
        ELSE:
          PREPARE for normal execution continuation
          VALIDATE execution environment is ready
      </resume_validation>
    </context_restoration>
    
  </step>
  
</resume_discovery_workflow>

## State Completion Workflow

<completion_workflow>
  
  <step number="1" name="finalize_execution_state">
    
    ### Step 1: Finalize Execution State
    
    <completion_update>
      <status_finalization>
        DETERMINE: execution mode (partial or full)
        IF partial execution:
          SET: .status = "partial_completed"
          NOTE: "Partial execution - uncommitted files restored"
        ELSE:
          SET: .status = "completed"
          NOTE: "Full execution - original files in stash"
        RECORD: completion timestamp
        PRESERVE: all execution history and progress
      </status_finalization>
      
      <final_summary>
        CALCULATE: total execution time
        RECORD: final branch state
        SUMMARIZE: commits created and branches affected
      </final_summary>
      
      <jq_completion_filter>
        JQ_FILTER='
          .status = "completed" |
          .completed_at = (now | todate) |
          .execution_summary = {
            "total_commits": .progress.completed_commits | length,
            "branches_affected": $branches,
            "execution_time": $duration,
            "final_branch": .current_branch
          } |
          .metadata.updated_at = (now | todate)
        '
        
        --argjson branches "$AFFECTED_BRANCHES" \
        --arg duration "$EXECUTION_DURATION"
      </jq_completion_filter>
    </completion_update>
    
  </step>
  
  <step number="2" name="cleanup_temporary_state">
    
    ### Step 2: Clean Up Temporary State
    
    <cleanup_operations>
      <stash_management>
        IF partial execution:
          RESTORE: initial stash to working directory
          VERIFY: uncommitted files restored successfully
          NOTE: User's work preserved in working directory
        ELSE IF full execution:
          PRESERVE: initial stash for user access
          INFORM: User about stash location
          NOTE: User can manually restore with git stash pop
        
        IF conflict stashes exist:
          EVALUATE: if they need preservation
          CLEAN UP: only if conflicts fully resolved
      </stash_management>
      
      <workspace_preservation>
        DO NOT: Remove uncommitted files from working directory
        DO NOT: Clean files that weren't part of commits
        PRESERVE: Working directory state for user
        PRESERVE: Audit trail in NATS KV state
        CLEAN UP: Only temporary lock files if any
      </workspace_preservation>
    </cleanup_operations>
    
  </step>
  
</completion_workflow>

## Error Recovery Patterns

<error_recovery>
  <transient_errors>
    NATS connection failures: Retry with exponential backoff
    Git command timeouts: Retry up to 3 times
    File system locks: Wait and retry with delay
  </transient_errors>
  
  <permanent_errors>
    State corruption: Log error and request manual intervention
    Missing plan files: Error with clear recovery instructions
    Branch conflicts: Transition to conflict resolution workflow
  </permanent_errors>
  
  <recovery_validation>
    ALWAYS verify state integrity after recovery
    LOG all recovery operations for audit trail
    PROVIDE clear next steps for user intervention
  </recovery_validation>
</error_recovery>

## Integration Points

<integration>
  <with_git_commit_instruction>
    REFERENCE: This workflow from git-commit.md step-by-step processes
    USE: State keys for coordination between instruction phases
    MAINTAIN: Backward compatibility with existing workflows
  </with_git_commit_instruction>
  
  <with_nats_kv_operations>
    FOLLOW: All wrapper script requirements from nats-kv-operations.md
    USE: Mandatory read/update/create patterns
    COMPLY: Phase ownership rules and validation requirements
  </with_nats_kv_operations>
  
  <with_peer_pattern>
    INTEGRATE: With PEER state management for higher-level coordination
    COORDINATE: With PEER cycle state for comprehensive tracking
    MAINTAIN: Separation between commit-specific and cycle-wide state
  </with_peer_pattern>
</integration>

## Validation Requirements

<validation>
  <pre_operation>
    VALIDATE: State key format follows peer.commit.* pattern
    CHECK: NATS KV connection is available
    VERIFY: Wrapper scripts are accessible and executable
  </pre_operation>
  
  <during_operation>
    VALIDATE: JSON structure before each write operation
    CHECK: Required fields are present and correctly typed
    VERIFY: State transitions are logical and valid
  </during_operation>
  
  <post_operation>
    CONFIRM: State write operations succeeded
    VALIDATE: State can be read back correctly
    VERIFY: All required fields are properly updated
  </post_operation>
</validation>

## Notes

- All state operations must use NATS KV wrapper scripts from nats-kv-operations.md
- State keys use dot notation for NATS compatibility (not colons)
- Conflict resolution preserves user work through descriptive stashing
- Resume capability works across agent restarts and system interruptions
- State provides complete audit trail for complex commit operations
- Integration with PEER pattern enables comprehensive workflow tracking