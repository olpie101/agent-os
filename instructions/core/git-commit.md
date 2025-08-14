---
description: Git commit workflow with optional MCP precommit validation
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Git Commit Workflow

Execute git commit operations with optional Zen MCP precommit validation when executed through PEER.

## Overview

<purpose>
  - Provide a git commit workflow that can be enhanced with MCP validation
  - Enable precommit checks when executed through PEER pattern
  - Maintain backwards compatibility with direct execution
</purpose>

<context>
  - Part of Agent OS git workflow enhancement
  - Works with existing git-workflow agent
  - Integrates with PEER pattern for MCP validation
</context>

## Usage Examples

### Through PEER (recommended for MCP validation):
```bash
# PEER will check MCP availability and run precommit if available
/peer --instruction=git-commit

# With specific commit message
/peer --instruction=git-commit --message="feat: implement user authentication"

# Skip MCP check even if available
/peer --instruction=git-commit --skip-precommit

# Execute a commit plan file
/peer --instruction=git-commit --plan=commit-plan-2025-08-13-17-30.json

# Resume incomplete commit execution
/peer --instruction=git-commit --continue
```

### Direct execution (bypasses MCP check):
```bash
# Direct execution always skips MCP precommit
/git-commit --message="fix: resolve login issue"
```

## Process Flow

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>
  
  <step number="1" name="parse_arguments">
    
    ### Step 1: Parse Arguments
    
    <argument_parsing>
      PARSE command arguments:
        - --message=<text>: Commit message (optional)
        - --skip-precommit: Skip MCP validation even if available
        - --plan=<filename>: Execute commit plan file (optional)
        - --continue: Resume incomplete execution from NATS KV state (optional)
        
      VALIDATE arguments:
        - --plan and --continue are mutually exclusive
        - If --plan provided, file must exist in .agent-os/commit-plan/
        
      STORE parsed values for use in workflow
    </argument_parsing>
    
  </step>
  
  <step number="2" name="detect_execution_context">
    
    ### Step 2: Detect Execution Context and Mode
    
    <execution_mode_determination>
      <mode_detection>
        <plan_execution_mode>
          <condition>--plan argument provided</condition>
          <actions>
            - SET: MODE = plan_execution
            - LOAD: plan file from .agent-os/commit-plan/${plan}
            - VALIDATE: plan file structure against @~/.agent-os/instructions/meta/commit-plan-schema.md
            - CREATE: NATS KV state with timestamped key pattern peer.commit.yyyy.mm.dd.hh.mm
          </actions>
        </plan_execution_mode>
        
        <resume_execution_mode>
          <condition>--continue argument provided</condition>
          <actions>
            - SET: MODE = resume_execution
            - FIND: latest incomplete state in NATS KV matching peer.commit.* pattern
            - LOAD: saved execution state
            - RESUME: from saved progress
          </actions>
        </resume_execution_mode>
        
        <standard_mode>
          <condition>neither --plan nor --continue provided</condition>
          <actions>
            - SET: MODE = standard_commit (existing behavior)
            - DETERMINE: execution context for PEER vs direct
            - PROCEED: with existing workflow
          </actions>
        </standard_mode>
      </mode_detection>
    </execution_mode_determination>
    
  </step>
  
  <step number="3" name="plan_file_handling" conditional="true">
    
    ### Step 3: Plan File Handling (Conditional)
    
    <conditional_execution>
      IF MODE != plan_execution:
        SKIP this entire step
        PROCEED to step 4
    </conditional_execution>
    
    <plan_file_operations>
      <file_loading>
        <action>READ plan file from .agent-os/commit-plan/${plan_filename}</action>
        <validation>
          - File exists and is readable
          - Valid JSON structure
          - Contains required fields per commit-plan-schema.md
          - Version field equals 1
        </validation>
        <error_handling>
          IF file not found:
            ERROR: "Commit plan file '${plan_filename}' not found in .agent-os/commit-plan/"
            PROVIDE: "Available files: [list .agent-os/commit-plan/*.json]"
            STOP execution
          IF invalid JSON or missing required fields:
            ERROR: "Invalid commit plan file structure"
            REFERENCE: "@~/.agent-os/instructions/meta/commit-plan-schema.md for valid format"
            STOP execution
        </error_handling>
      </file_loading>
      
      <state_initialization>
        <generate_timestamp>
          SET current_timestamp = current datetime in format yyyy.mm.dd.hh.mm
        </generate_timestamp>
        <create_nats_state>
          <key_format>peer.commit.${timestamp}</key_format>
          <initial_state>
            {
              "version": 1,
              "plan_file": "${plan_filename}",
              "execution_id": "peer.commit.${timestamp}",
              "status": "initialized",
              "created_at": "${iso_timestamp}",
              "updated_at": "${iso_timestamp}",
              "current_branch": "${current_git_branch}",
              "original_branch": "${current_git_branch}",
              "plan": {
                "expected_branches": ${extract_branches_from_plan},
                "total_commits": ${count_commits_in_plan},
                "commits_per_branch": ${group_commits_by_branch}
              },
              "progress": {
                "current_step": 0,
                "total_steps": ${total_commits},
                "completed_commits": [],
                "current_commit_files": [],
                "remaining_commits": ${total_commits}
              }
            }
          </initial_state>
          <storage_command>echo "${initial_state}" | nats kv put agent-os-peer-state "peer.commit.${timestamp}"</storage_command>
        </create_nats_state>
      </state_initialization>
    </plan_file_operations>
    
  </step>
  
  <step number="4" name="resume_state_discovery" conditional="true">
    
    ### Step 4: Resume State Discovery (Conditional)
    
    <conditional_execution>
      IF MODE != resume_execution:
        SKIP this entire step
        PROCEED to step 5
    </conditional_execution>
    
    <state_discovery>
      <find_incomplete_executions>
        <action>SEARCH NATS KV for keys matching pattern "peer.commit.*"</action>
        <command>nats kv ls agent-os-peer-state | grep "peer.commit"</command>
        <filter_criteria>
          FOR each found key:
            READ state object from key
            CHECK status field
            IF status IN ["initialized", "in_progress", "paused_for_conflict"]:
              ADD key to resumable_executions list
        </filter_criteria>
      </find_incomplete_executions>
      
      <user_selection>
        IF resumable_executions is empty:
          ERROR: "No incomplete git commit executions found"
          PROVIDE: "Start a new execution with --plan argument"
          STOP execution
        ELSE IF resumable_executions has 1 item:
          SET selected_execution = resumable_executions[0]
          NOTIFY: "Resuming execution: ${selected_execution}"
        ELSE:
          PROMPT user to select from resumable_executions list
          DISPLAY each execution with:
            - Execution ID
            - Creation timestamp  
            - Current status
            - Progress summary
          WAIT for user selection
          SET selected_execution = user_choice
      </user_selection>
      
      <state_restoration>
        <load_state>
          READ complete state from NATS KV using selected_execution key
          PARSE state object to restore execution context
        </load_state>
        <conflict_handling>
          IF state.status == "paused_for_conflict":
            CHECK if stash exists with stash_ref from state
            IF stash exists:
              NOTIFY: "Conflict resolution required. Stash available: ${state.conflict_context.stash_ref}"
              PREPARE for stash restoration
            ELSE:
              ERROR: "Stash reference not found. Manual cleanup may be needed."
              STOP execution
        </conflict_handling>
      </state_restoration>
    </state_discovery>
    
  </step>
  
  <step number="5" name="multi_branch_execution" conditional="true">
    
    ### Step 5: Multi-Branch Execution Engine (Conditional)
    
    <conditional_execution>
      IF MODE NOT IN [plan_execution, resume_execution]:
        SKIP this entire step
        PROCEED to step 6
    </conditional_execution>
    
    <execution_engine>
      <branch_dependency_analysis>
        <analyze_dependencies>
          FOR each commit in execution plan:
            IDENTIFY files that overlap between commits
            CHECK branch dependencies in requires_branches field
            DETECT potential conflicts
        </analyze_dependencies>
        <dependency_resolution>
          IF file dependencies detected between branches:
            TRIGGER user decision workflow
            PRESENT visual decision tree from technical-spec.md
            OPTIONS: merge_dependency | create_new_branch | skip_file
            WAIT for user decision
            EXECUTE chosen strategy
            UPDATE NATS KV state with decision and reasoning
        </dependency_resolution>
      </branch_dependency_analysis>
      
      <commit_execution_loop>
        FOR each commit in execution plan:
          <branch_operations>
            IF commit.branch != current_branch:
              CHECK if branch exists
              IF branch does not exist:
                CREATE branch: git checkout -b ${commit.branch}
              ELSE:
                SWITCH to branch: git checkout ${commit.branch}
              UPDATE current_branch in NATS KV state
          </branch_operations>
          
          <file_staging>
            FOR each file in commit.files:
              CHECK if file exists and has changes
              IF file exists:
                STAGE file: git add ${file}
                ADD to current_commit_files in state
              ELSE:
                WARN: "File ${file} not found or unchanged"
                RECORD warning in state
          </file_staging>
          
          <commit_creation>
            <conflict_detection>
              TRY to create commit with message: git commit -m "${commit.message}"
              IF merge conflicts detected:
                CREATE descriptive stash: git stash push -m "PEER-git-commit: remaining files from ${current_branch}"
                UPDATE NATS KV state to "paused_for_conflict"
                STORE conflict context: {
                  "conflicted_files": ${get_conflicted_files},
                  "stash_ref": ${get_stash_ref},
                  "stash_message": "PEER-git-commit: remaining files from ${current_branch}",
                  "resolution_branch": ${current_branch}
                }
                PROVIDE user with resolution instructions
                STOP execution with resume instructions
              ELSE:
                RECORD successful commit hash
                INCREMENT progress.current_step
                ADD commit hash to progress.completed_commits
                UPDATE NATS KV state with progress
            </conflict_detection>
          </commit_creation>
        END FOR
        
        UPDATE final state to "completed" with completion timestamp
      </commit_execution_loop>
    </execution_engine>
    
  </step>
  
  <step number="6" name="delegate_to_git_workflow">
    
    ### Step 6: Delegate to Git Workflow
    
    <delegation>
      <conditional_delegation>
        <standard_mode_execution>
          <condition>MODE == standard_commit</condition>
          <action>
            USE Task tool to invoke git-workflow agent:
              
            <Task>
              description: "Execute standard git commit workflow"
              prompt: |
                Complete git workflow with these parameters:
                ${message ? `- Commit message: ${message}` : '- Prompt for commit message'}
                ${enhanced_mode ? '- Execution context: PEER-enhanced' : '- Execution context: Direct'}
                ${skip_precommit ? '- Precommit: Skipped by user request' : ''}
                
                Perform the following:
                1. Check git status and identify changed files
                2. Stage appropriate files for commit
                3. Create commit with provided or prompted message
                4. Push to remote repository
                5. Create pull request if appropriate
                
                Use the git-workflow agent to handle all git operations.
              subagent_type: git-workflow
            </Task>
          </action>
        </standard_mode_execution>
        
        <enhanced_mode_execution>
          <condition>MODE IN [plan_execution, resume_execution]</condition>
          <action>
            USE Task tool to invoke git-workflow agent:
              
            <Task>
              description: "Execute enhanced git commit workflow with NATS KV state management"
              prompt: |
                Complete enhanced git workflow with multi-branch support:
                - Execution mode: ${MODE}
                ${MODE == 'plan_execution' ? '- Plan file: ' + plan_filename : ''}
                ${MODE == 'resume_execution' ? '- Resuming from: ' + selected_execution : ''}
                - NATS KV state key: ${execution_state_key}
                
                Enhanced operations completed in previous steps:
                1. Plan file loaded and validated (if applicable)
                2. NATS KV state initialized/resumed
                3. Multi-branch execution engine processed commits
                4. File staging and conflict detection handled
                5. User decision prompts completed (if applicable)
                
                Final git operations needed:
                1. Verify all commits were created successfully
                2. Push branches to remote repository
                3. Create pull requests as appropriate
                4. Update NATS KV state to final completion
                5. Clean up any temporary state
                
                Use the git-workflow agent for standard git operations.
                Report final status back for NATS KV state completion.
              subagent_type: git-workflow
            </Task>
          </action>
        </enhanced_mode_execution>
      </conditional_delegation>
    </delegation>
    
  </step>
  
  <step number="7" name="completion_summary">
    
    ### Step 7: Completion Summary
    
    <summary>
      <standard_completion>
        <condition>MODE == standard_commit</condition>
        <display>
          DISPLAY completion status:
            - Commit created successfully
            - Branch and commit details
            - Pull request URL if created
            
          IF enhanced_mode AND MCP was used:
            NOTE: Validation details available in PEER cycle output
        </display>
      </standard_completion>
      
      <enhanced_completion>
        <condition>MODE IN [plan_execution, resume_execution]</condition>
        <display>
          DISPLAY enhanced completion status:
            - Execution mode: ${MODE}
            - Total commits processed: ${total_commits}
            - Branches created/updated: ${branches_list}
            - NATS KV state: ${execution_state_key}
            - Final status: ${final_status}
            
          IF conflicts encountered:
            NOTE: Conflict resolution details in NATS KV state
            
          IF pull requests created:
            LIST: Pull request URLs for each branch
            
          PROVIDE: Instructions for cleanup if needed
          REMIND: NATS KV state preserved for audit trail
        </display>
      </enhanced_completion>
    </summary>
    
  </step>
  
</process_flow>

## Integration with PEER

When executed through PEER (`/peer --instruction=git-commit`), the PEER executor adds:

1. **Pre-execution Phase**: 
   - Checks for mcp__zen tools availability
   - Runs mcp__zen__precommit if available
   - Shows validation results to user
   - Awaits user decision to proceed

2. **Execution Phase**:
   - Delegates to this instruction
   - Passes validation context
   - Handles user interactions

3. **Review Phase**:
   - Captures validation patterns
   - Documents any issues for future reference

## Arguments Reference

### --message
- **Type**: String
- **Required**: No
- **Description**: Commit message to use. If not provided, git-workflow will prompt
- **Example**: `--message="feat: add user authentication"`

### --skip-precommit
- **Type**: Boolean flag
- **Required**: No
- **Description**: Skip MCP precommit validation even when available through PEER
- **Example**: `--skip-precommit`

### --plan
- **Type**: String (filename)
- **Required**: No (mutually exclusive with --continue)
- **Description**: Execute commit plan file from .agent-os/commit-plan/ directory
- **Validation**: File must exist and conform to commit-plan-schema.md
- **Example**: `--plan=commit-plan-2025-08-13-17-30.json`

### --continue
- **Type**: Boolean flag
- **Required**: No (mutually exclusive with --plan)
- **Description**: Resume incomplete git commit execution from NATS KV state
- **Behavior**: Searches for incomplete executions and prompts user to select
- **Example**: `--continue`

## Error Handling

<error_patterns>
  <git_errors>
    - No changes to commit: Inform user no changes detected
    - Uncommitted changes: Let git-workflow handle staging
    - Push failures: Delegate to git-workflow error handling
    - Branch switching failures: Log to NATS KV state and provide recovery
    - Merge conflicts: Create stash and transition to conflict resolution mode
  </git_errors>
  
  <validation_errors>
    - MCP validation failures: Handled by PEER executor
    - User cancellation: Exit gracefully with status message
  </validation_errors>
  
  <plan_execution_errors>
    - Plan file not found: List available files in .agent-os/commit-plan/
    - Invalid plan structure: Reference schema documentation for corrections
    - Plan validation failure: Provide specific validation errors
    - Missing plan directory: Create directory and inform user
  </plan_execution_errors>
  
  <state_management_errors>
    - NATS KV connection failure: Retry with exponential backoff
    - State corruption: Provide manual recovery instructions
    - Incomplete execution not found: Guide user to start new execution
    - Stash reference missing: Provide manual cleanup guidance
  </state_management_errors>
  
  <dependency_resolution_errors>
    - File conflict between branches: Trigger user decision workflow
    - Branch dependency cycle: Detect and report circular dependencies
    - User decision timeout: Prompt for explicit choice
  </dependency_resolution_errors>
</error_patterns>

## Notes

- This instruction provides both standard and enhanced git commit workflows
- **Standard Mode**: Acts as thin wrapper for git-workflow (existing behavior)
- **Enhanced Mode**: Supports commit plan execution and resume capability
- MCP validation only occurs when executed through PEER
- Direct execution provides standard git workflow without validation
- Plan execution uses NATS KV for state persistence and resume capability
- Multi-branch execution includes conflict detection and user decision prompts
- All git operations are ultimately handled by the git-workflow agent
- NATS KV state provides audit trail for complex commit workflows
- Enhanced features maintain backward compatibility with existing usage patterns