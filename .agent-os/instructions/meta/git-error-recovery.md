---
description: Git Error Recovery Workflows for PEER Pattern
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Git Error Recovery

## Overview

Declarative XML workflows for handling git operation errors during complex multi-branch commit execution. These patterns provide systematic error detection, classification, recovery strategies, and user guidance for both transient and permanent error conditions.

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
  ALSO_EXECUTE: @~/.agent-os/instructions/meta/git-commit-state-management.md
</pre_flight_check>

## Error Classification and Detection

<error_classification_workflow>
  
  <step number="1" name="capture_git_operation_errors">
    
    ### Step 1: Capture Git Operation Errors
    
    <error_capture>
      <command_monitoring>
        MONITOR: all git command exit codes
        CAPTURE: stdout and stderr from git operations
        RECORD: command that failed and its arguments
        TIMESTAMP: error occurrence for correlation
      </command_monitoring>
      
      <error_context_collection>
        GATHER: repository state at time of error:
          - current branch and HEAD position
          - working directory status
          - staged changes state
          - stash status and references
        
        COLLECT: execution context:
          - current commit plan step
          - files being processed
          - branch switching operations
          - merge or conflict states
      </error_context_collection>
      
      <error_message_parsing>
        EXTRACT: key error indicators from git output
        IDENTIFY: specific error types and codes
        PARSE: file paths and operation details
        CATEGORIZE: error by operational context
      </error_message_parsing>
    </error_capture>
    
  </step>
  
  <step number="2" name="classify_error_types">
    
    ### Step 2: Classify Error Types
    
    <error_classification>
      <transient_errors>
        <network_failures>
          INDICATORS: "Connection refused", "timeout", "network unreachable"
          CLASSIFICATION: temporary network connectivity issues
          RECOVERY: retry with backoff strategy
          TIMEOUT: escalate if retries exhausted
        </network_failures>
        
        <file_system_locks>
          INDICATORS: "unable to lock", "resource temporarily unavailable"
          CLASSIFICATION: temporary file system contention
          RECOVERY: brief wait and retry operation
          ESCALATION: manual intervention if locks persist
        </file_system_locks>
        
        <git_command_timeouts>
          INDICATORS: command timeout or hung process
          CLASSIFICATION: temporary git operation delay
          RECOVERY: kill process and retry with increased timeout
          MONITORING: track timeout patterns for optimization
        </git_command_timeouts>
      </transient_errors>
      
      <permanent_errors>
        <merge_conflicts>
          INDICATORS: "CONFLICT", "Automatic merge failed"
          CLASSIFICATION: content conflicts requiring resolution
          RECOVERY: conflict resolution workflow with user guidance
          STATE: transition to paused_for_conflict
        </merge_conflicts>
        
        <repository_corruption>
          INDICATORS: "fatal: index file corrupt", "bad object"
          CLASSIFICATION: git repository integrity issues
          RECOVERY: repository repair or manual intervention
          PRESERVATION: save execution state for recovery
        </repository_corruption>
        
        <permission_errors>
          INDICATORS: "Permission denied", "insufficient permissions"
          CLASSIFICATION: access control or ownership issues
          RECOVERY: user guidance for permission resolution
          CONTINUATION: resume after permissions fixed
        </permission_errors>
        
        <invalid_operations>
          INDICATORS: "pathspec did not match", "branch already exists"
          CLASSIFICATION: logically impossible or invalid operations
          RECOVERY: plan analysis and correction suggestions
          USER_GUIDANCE: specific operation fixes needed
        </invalid_operations>
      </permanent_errors>
      
      <critical_errors>
        <disk_space_exhaustion>
          INDICATORS: "No space left on device", "disk full"
          CLASSIFICATION: system resource exhaustion
          RECOVERY: immediate cleanup and user notification
          PROTECTION: preserve execution state before cleanup
        </disk_space_exhaustion>
        
        <system_failures>
          INDICATORS: system-level errors, process crashes
          CLASSIFICATION: underlying system problems
          RECOVERY: graceful state preservation and exit
          USER_GUIDANCE: system-level diagnostics needed
        </system_failures>
      </critical_errors>
    </error_classification>
    
  </step>
  
</error_classification_workflow>

## Transient Error Handling

<transient_error_workflow>
  
  <step number="1" name="implement_retry_strategy">
    
    ### Step 1: Implement Retry Strategy
    
    <retry_strategy>
      <exponential_backoff>
        INITIAL_DELAY: 1 second
        BACKOFF_MULTIPLIER: 2.0
        MAXIMUM_DELAY: 30 seconds
        MAXIMUM_RETRIES: 3
        
        ALGORITHM:
          retry_delay = initial_delay * (multiplier ^ retry_attempt)
          wait(min(retry_delay, maximum_delay))
          attempt_operation()
      </exponential_backoff>
      
      <retry_conditions>
        NETWORK_ERRORS: retry up to 3 times with exponential backoff
        FILE_LOCKS: retry up to 5 times with linear backoff (2 seconds)
        COMMAND_TIMEOUTS: retry up to 2 times with doubled timeout
        
        SUCCESS_CONDITION: git command returns 0 exit code
        FAILURE_ESCALATION: permanent error handling if all retries fail
      </retry_conditions>
      
      <state_preservation_during_retry>
        MAINTAIN: NATS state consistency during retry attempts
        RECORD: retry attempts and outcomes in execution log
        PRESERVE: user context and execution progress
        UPDATE: retry status without losing primary state
      </state_preservation_during_retry>
    </retry_strategy>
    
  </step>
  
  <step number="2" name="monitor_retry_patterns">
    
    ### Step 2: Monitor Retry Patterns
    
    <retry_monitoring>
      <pattern_detection>
        TRACK: repeated failures for same operations
        IDENTIFY: systematic issues vs random failures
        ANALYZE: failure frequency and timing patterns
        ESCALATE: patterns suggesting permanent issues
      </pattern_detection>
      
      <adaptive_retry_adjustment>
        INCREASE: retry delays for repeatedly failing operations
        REDUCE: retry counts for consistently fast failures
        OPTIMIZE: timeout values based on operation history
        LEARN: from success/failure patterns for efficiency
      </adaptive_retry_adjustment>
      
      <escalation_triggers>
        TRIGGER permanent error handling when:
          - Same operation fails 3 times consecutively
          - Multiple different operations fail within short timeframe
          - Retry delays exceed reasonable execution timeframes
          - System resource constraints detected during retries
      </escalation_triggers>
    </retry_monitoring>
    
  </step>
  
</transient_error_workflow>

## Permanent Error Recovery

<permanent_error_workflow>
  
  <step number="1" name="conflict_resolution_workflow">
    
    ### Step 1: Handle Merge Conflicts
    
    <conflict_resolution>
      <conflict_state_transition>
        IMMEDIATELY: stop current execution flow
        PRESERVE: working directory state through stashing
        UPDATE: NATS state to "paused_for_conflict"
        RECORD: detailed conflict context information
      </conflict_state_transition>
      
      <stash_creation_with_context>
        <stash_naming>
          FORMAT: "PEER-git-commit: remaining files from [branch-name]"
          INCLUDE: timestamp and conflict context
          EXAMPLE: "PEER-git-commit: remaining files from feature/auth (conflict at 2025-08-13 17:30)"
        </stash_naming>
        
        <stash_operation>
          COMMAND: git stash push -m "[stash_message]" --include-untracked
          VERIFY: stash creation successful
          RECORD: stash reference and message in conflict_context
          VALIDATE: working directory is clean after stashing
        </stash_operation>
      </stash_creation_with_context>
      
      <conflict_analysis_and_guidance>
        ANALYZE: conflicted files and conflict types
        IDENTIFY: complexity level of conflicts
        GENERATE: specific resolution guidance for each conflict type
        PROVIDE: step-by-step user instructions with context
      </conflict_analysis_and_guidance>
    </conflict_resolution>
    
  </step>
  
  <step number="2" name="repository_integrity_recovery">
    
    ### Step 2: Handle Repository Corruption
    
    <integrity_recovery>
      <corruption_assessment>
        DETECT: type and extent of repository corruption
        ANALYZE: whether corruption affects execution state
        DETERMINE: recovery feasibility vs manual intervention need
        PRESERVE: execution state before any repair attempts
      </corruption_assessment>
      
      <automated_repair_attempts>
        <git_fsck_repair>
          COMMAND: git fsck --full --strict
          CAPTURE: fsck output for analysis
          ATTEMPT: git gc --aggressive if fsck succeeds
          VALIDATE: repository integrity after repair
        </git_fsck_repair>
        
        <index_reconstruction>
          IF index corruption detected:
            BACKUP: current index if possible
            COMMAND: git reset --hard HEAD
            COMMAND: git read-tree HEAD
            VERIFY: index reconstruction successful
        </index_reconstruction>
        
        <recovery_validation>
          TEST: basic git operations after repair
          VERIFY: repository history is intact
          CHECK: working directory consistency
          CONFIRM: execution can be safely resumed
        </recovery_validation>
      </automated_repair_attempts>
      
      <manual_intervention_guidance>
        IF automated repair fails:
          PRESERVE: complete execution state in NATS
          DOCUMENT: corruption details and attempted repairs
          PROVIDE: specific manual repair instructions
          OFFER: resume capability after manual fixes
      </manual_intervention_guidance>
    </integrity_recovery>
    
  </step>
  
  <step number="3" name="permission_and_access_recovery">
    
    ### Step 3: Handle Permission and Access Issues
    
    <access_recovery>
      <permission_analysis>
        IDENTIFY: specific files or directories with permission issues
        ANALYZE: whether permissions changed during execution
        DETERMINE: minimal permission changes needed for continuation
        ASSESS: security implications of permission modifications
      </permission_analysis>
      
      <user_guided_permission_resolution>
        <permission_diagnosis>
          DISPLAY: specific permission issues found
          EXPLAIN: why permissions are needed for git operations
          IDENTIFY: exact files/directories needing permission changes
          PROVIDE: safe permission change commands
        </permission_diagnosis>
        
        <resolution_guidance>
          OFFER: specific command suggestions:
            - "chmod +w [file]" for write permission issues
            - "chown [user] [file]" for ownership issues  
            - "chmod -R u+rwx [directory]" for directory access
          
          WARN: about security implications
          SUGGEST: minimal permission changes for safety
          PROVIDE: verification commands to test fixes
        </resolution_guidance>
        
        <resume_preparation>
          GUIDE: user through permission verification
          TEST: git operations with new permissions
          CONFIRM: execution can resume safely
          RESTORE: execution context for continuation
        </resume_preparation>
      </user_guided_permission_resolution>
    </access_recovery>
    
  </step>
  
</permanent_error_workflow>

## State Preservation During Errors

<state_preservation_workflow>
  
  <step number="1" name="capture_error_context">
    
    ### Step 1: Capture Complete Error Context
    
    <context_capture>
      <execution_state_snapshot>
        RECORD: current execution progress
        CAPTURE: commit plan position and remaining steps
        PRESERVE: branch context and file staging state
        DOCUMENT: user decisions made up to error point
      </execution_state_snapshot>
      
      <repository_state_snapshot>
        RECORD: current branch and HEAD position
        CAPTURE: working directory file status
        PRESERVE: staged changes information
        DOCUMENT: any stashes or temporary state
      </repository_state_snapshot>
      
      <error_details_recording>
        TIMESTAMP: exact error occurrence time
        RECORD: failed command and its arguments
        CAPTURE: complete error output (stdout/stderr)
        DOCUMENT: error classification and recovery attempts
      </error_details_recording>
    </context_capture>
    
  </step>
  
  <step number="2" name="update_nats_error_state">
    
    ### Step 2: Update NATS State for Error Conditions
    
    <error_state_update>
      <status_transition>
        UPDATE: .status based on error type:
          - "paused_for_conflict" for merge conflicts
          - "paused_for_intervention" for permission issues
          - "error_recovery" for corruption or system errors
          - "failed" for unrecoverable errors
      </status_transition>
      
      <error_context_storage>
        CREATE: .error_context object with:
          - error_type: classification of error
          - error_message: original git error message
          - failed_operation: specific operation that failed
          - retry_count: number of retry attempts made
          - recovery_attempts: list of recovery actions tried
          - resolution_guidance: user instructions provided
      </error_context_storage>
      
      <preservation_references>
        RECORD: any preservation actions taken:
          - stash_refs: stashes created for preservation
          - backup_refs: any backups or snapshots
          - temp_files: temporary files containing state
          - recovery_info: information needed for restoration
      </preservation_references>
    </error_state_update>
    
  </step>
  
</state_preservation_workflow>

## Recovery Verification and Validation

<recovery_validation_workflow>
  
  <step number="1" name="validate_recovery_readiness">
    
    ### Step 1: Validate Recovery Readiness
    
    <readiness_validation>
      <repository_state_validation>
        VERIFY: git repository is in consistent state
        CHECK: working directory matches expected state
        VALIDATE: no conflicted files remain
        CONFIRM: staging area is appropriate for continuation
      </repository_state_validation>
      
      <execution_context_validation>
        VERIFY: NATS state contains valid execution context
        CHECK: commit plan integrity after error handling
        VALIDATE: branch context matches repository state
        CONFIRM: file lists are accurate and accessible
      </execution_context_validation>
      
      <dependency_validation>
        CHECK: required files and branches are available
        VERIFY: no new conflicts introduced during recovery
        VALIDATE: user decisions are still applicable
        CONFIRM: execution preconditions are satisfied
      </dependency_validation>
    </readiness_validation>
    
  </step>
  
  <step number="2" name="test_critical_operations">
    
    ### Step 2: Test Critical Operations Before Resume
    
    <operation_testing>
      <basic_git_operations>
        TEST: git status (should work without errors)
        TEST: git add [safe_file] (test staging capability)
        TEST: git reset [safe_file] (test unstaging capability)
        VERIFY: all basic operations function correctly
      </basic_git_operations>
      
      <branch_operation_testing>
        TEST: git branch --list (verify branch access)
        TEST: git show-branch (verify branch relationships)
        IF branch switches needed:
          TEST: git checkout [target_branch] --dry-run
        VERIFY: branch operations are safe to execute
      </branch_operation_testing>
      
      <file_operation_testing>
        FOR critical files in execution plan:
          TEST: file existence and readability
          TEST: git ls-files [file] (verify git tracking)
          VERIFY: files are in expected state for operations
      </file_operation_testing>
    </operation_testing>
    
  </step>
  
  <step number="3" name="confirm_resume_safety">
    
    ### Step 3: Confirm Resume Safety
    
    <safety_confirmation>
      <risk_assessment>
        ANALYZE: potential risks of resuming execution
        EVALUATE: likelihood of recurring errors
        ASSESS: impact of partial execution completion
        DETERMINE: safest approach for continuation
      </risk_assessment>
      
      <user_confirmation>
        IF significant risks detected:
          PRESENT: risk summary to user
          EXPLAIN: potential consequences of resuming
          OFFER: alternative approaches or manual completion
          REQUIRE: explicit user confirmation to proceed
      </user_confirmation>
      
      <resume_preparation>
        PREPARE: execution context for safe resumption
        RESTORE: any stashed or preserved state
        UPDATE: progress tracking to reflect recovery
        ENABLE: normal execution flow continuation
      </resume_preparation>
    </safety_confirmation>
    
  </step>
  
</recovery_validation_workflow>

## Error Reporting and User Communication

<error_reporting_workflow>
  
  <step number="1" name="generate_comprehensive_error_reports">
    
    ### Step 1: Generate Comprehensive Error Reports
    
    <error_reporting>
      <executive_summary>
        TITLE: "[ERROR_TYPE] During Git Commit Execution"
        SUMMARY: brief description of what went wrong
        STATUS: current execution state and next steps
        TIMELINE: when error occurred and recovery time estimate
      </executive_summary>
      
      <technical_details>
        SECTION: "Error Details"
        INCLUDE: 
          - Failed git command and arguments
          - Complete error output from git
          - Repository state at time of failure
          - Execution context and progress information
        
        SECTION: "Recovery Actions Taken"
        INCLUDE:
          - Automatic recovery attempts and results
          - State preservation actions performed
          - Current repository and execution state
      </technical_details>
      
      <user_action_guidance>
        SECTION: "Required Actions"
        PROVIDE: step-by-step instructions for resolution
        INCLUDE: specific commands with explanations
        OFFER: alternative approaches if applicable
        ESTIMATE: time and complexity of manual intervention
      </user_action_guidance>
    </error_reporting>
    
  </step>
  
  <step number="2" name="provide_context_sensitive_guidance">
    
    ### Step 2: Provide Context-Sensitive Guidance
    
    <contextual_guidance>
      <beginner_friendly_explanations>
        EXPLAIN: git concepts in accessible terms
        PROVIDE: background on why error occurred
        CLARIFY: normal vs exceptional conditions
        DEMYSTIFY: git terminology and operations
      </beginner_friendly_explanations>
      
      <advanced_user_shortcuts>
        DETECT: user experience level from interaction history
        OFFER: direct command sequences for experienced users
        PROVIDE: detailed technical context for debugging
        SUGGEST: efficiency optimizations for recovery
      </advanced_user_shortcuts>
      
      <situation_specific_advice>
        TAILOR: guidance to specific error and context
        CONSIDER: execution progress and remaining work
        ADAPT: instructions to repository state and user setup
        OPTIMIZE: recovery path for minimal disruption
      </situation_specific_advice>
    </contextual_guidance>
    
  </step>
  
</error_reporting_workflow>

## Integration Points

<integration>
  <with_multi_branch_execution>
    HANDLES: errors during branch operations and commit creation
    COORDINATES: with execution workflows for error state transitions
    PROVIDES: recovery validation before execution continuation
  </with_multi_branch_execution>
  
  <with_state_management>
    USES: git-commit-state-management.md for error state persistence
    MAINTAINS: consistent state structure during error conditions
    COORDINATES: state recovery and validation processes
  </with_state_management>
  
  <with_user_interaction>
    TRIGGERS: user-interaction-workflows.md for manual intervention
    PROVIDES: error context for user decision workflows
    COORDINATES: user guidance and confirmation processes
  </with_user_interaction>
</integration>

## Performance Considerations

<performance>
  <error_detection_optimization>
    MINIMIZE: overhead of error monitoring during normal operations
    OPTIMIZE: error classification algorithms for speed
    CACHE: common error patterns for faster recognition
    BATCH: related error handling operations
  </error_detection_optimization>
  
  <recovery_efficiency>
    PRIORITIZE: fastest recovery methods for transient errors
    OPTIMIZE: retry timing for different error types
    MINIMIZE: data loss during error preservation
    STREAMLINE: recovery validation processes
  </recovery_efficiency>
  
  <state_preservation_efficiency>
    OPTIMIZE: NATS state updates during error conditions
    MINIMIZE: storage overhead for error context
    COMPRESS: large error outputs for efficient storage
    BATCH: related preservation operations
  </state_preservation_efficiency>
</performance>

## Notes

- Error recovery workflows maintain complete audit trail through NATS state
- Transient error handling uses exponential backoff to prevent system overload
- Permanent error recovery preserves user work through careful stashing
- State preservation enables resume capability across all error types
- User guidance adapts to error complexity and user experience level
- Recovery validation ensures safe execution continuation after intervention
- Integration points maintain clean separation with other workflow components