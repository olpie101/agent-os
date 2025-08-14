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


# Execute only a specific branch from plan (partial execution)
/peer --instruction=git-commit --plan=commit-plan-2025-08-13-17-30.json --branch=feature/auth

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
        - --branch=<branch-name>: Execute only specified branch from plan (optional)
        
      VALIDATE arguments:
        - --plan and --continue are mutually exclusive
        - If --plan provided, file must exist in .agent-os/commit-plan/
        - If --branch provided, --plan must also be provided
        - --branch and --continue are mutually exclusive
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
    
    <mcp_context_isolation>
      IF execution through PEER AND MCP validation requested:
        FOR each commit in plan (if plan_execution mode):
          ISOLATE MCP context to ONLY files in current commit:
            - Extract file list from current commit specification
            - Provide ONLY those files to MCP validation
            - Do NOT include files from other commits in plan
            - Do NOT include full project context
            - PREVENT MCP from seeing entire plan structure
          VALIDATE each commit independently with isolated context
        
        IF standard_commit mode:
          ISOLATE MCP context to currently staged files only:
            - Identify files staged for commit
            - Provide ONLY staged files to MCP validation
            - Do NOT include unstaged or unrelated files
      
      STORE: isolated_context_per_commit for use in execution steps
    </mcp_context_isolation>
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
        <action>
          DELEGATE: plan file validation to commit-plan-validation.md
          
          REFERENCE: @~/.agent-os/instructions/meta/commit-plan-validation.md
          EXECUTE: Complete plan validation workflow:
            1. File Location and Format Detection workflow
            2. JSON Plan Validation workflow (if JSON format)
            3. Markdown Plan Validation workflow (if Markdown format)  
            4. Cross-Format Validation workflow
            5. Conversion Validation workflow (if Markdown to JSON conversion needed)
          
          CAPTURE: validated plan structure and format information
          HANDLE: all error conditions through commit-plan-validation.md error patterns
          RETURN: format-normalized plan data ready for execution
        </action>
      </file_loading>
      
      <state_initialization>
        <action>
          DELEGATE: state creation to git-commit-state-management.md
          
          REFERENCE: @~/.agent-os/instructions/meta/git-commit-state-management.md
          EXECUTE: State Creation Workflow:
            1. Extract Timestamp from Plan Filename workflow
            2. Initialize State Object workflow
            3. Store Initial State in NATS KV workflow
          
          PROVIDE: validated plan data and execution context
          INCLUDE: --branch flag information for partial execution support
          CAPTURE: generated state key for subsequent operations
          HANDLE: state creation errors through git-error-recovery.md patterns
          RETURN: execution state key and initial progress context
        </action>
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
      <action>
        DELEGATE: resume state discovery to git-commit-state-management.md
        
        REFERENCE: @~/.agent-os/instructions/meta/git-commit-state-management.md
        EXECUTE: Resume State Discovery workflow:
          1. Search for Incomplete Executions workflow
          2. Present Resumable Options workflow  
          3. Restore Execution Context workflow
        
        COORDINATE: with user-interaction-workflows.md for multi-option selection
        HANDLE: conflict state validation and stash verification
        CAPTURE: restored execution context and continuation point
        VALIDATE: execution environment readiness through recovery workflows
        RETURN: selected execution state and resume preparation status
      </action>
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
      <action>
        DELEGATE: multi-branch execution to multi-branch-execution.md
        
        REFERENCE: @~/.agent-os/instructions/meta/multi-branch-execution.md
        EXECUTE: Complete multi-branch execution workflow:
          1. Execution Context Initialization workflow
          2. Initial Stash Operations workflow (preserve uncommitted changes)  
          3. Partial Execution Support workflow (--branch flag handling)
          4. Branch Management Operations workflow
          5. File Staging and Commit Operations workflow
          6. Conflict Detection and Recovery workflow
          7. Resume and Recovery Operations workflow
          8. Execution Progress Tracking throughout
        
        COORDINATE: with user-interaction-workflows.md for dependency decisions
        INTEGRATE: with git-commit-state-management.md for progress tracking
        HANDLE: all error conditions through git-error-recovery.md workflows
        SUPPORT: both full execution and partial execution (--branch flag) modes
        PRESERVE: initial stash management for file restoration
        RETURN: execution completion status and branch operation results
      </action>
    </execution_engine>
    
  </step>
  
  <step number="5.5" name="plan_deviation_detection" conditional="true">
    
    ### Step 5.5: Plan Deviation Detection and User Confirmation (Conditional)
    
    <conditional_execution>
      IF MODE != plan_execution:
        SKIP this entire step
        PROCEED to step 6
    </conditional_execution>
    
    <deviation_detection>
      <action>
        DELEGATE: plan deviation handling to user-interaction-workflows.md
        
        REFERENCE: @~/.agent-os/instructions/meta/user-interaction-workflows.md
        EXECUTE: Plan deviation detection and user confirmation workflow:
          1. Detect deviation conditions (plan vs actual state comparison)
          2. Present deviation report with visual decision tree
          3. Capture user decision with consequence explanation
          4. Execute chosen strategy (cancel/update-plan/proceed)
        
        INTEGRATE: with git-commit-state-management.md for deviation logging
        HANDLE: user decision timeout and invalid responses
        ENFORCE: plan adherence requirements and deviation documentation
        COORDINATE: with git-error-recovery.md if execution halts
        RETURN: user decision and execution continuation authorization
      </action>
    </deviation_detection>
    
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
                
                EXPLICIT CONSTRAINTS FOR SUBAGENTS:
                - Do NOT modify any files beyond git operations
                - Do NOT make autonomous decisions about staging or commit content
                - Do NOT deviate from specified parameters
                - Follow EXACTLY the workflow steps provided
                - Report any unexpected conditions instead of making assumptions

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
                

                CRITICAL PLAN ADHERENCE CONSTRAINTS:
                - EXECUTE ONLY the operations specified in the loaded plan
                - Do NOT make autonomous modifications to plan steps
                - Do NOT stage files beyond those specified in plan
                - Do NOT modify commit messages from plan specifications
                - Do NOT create additional branches beyond plan requirements
                - HALT execution and request user confirmation if deviations are detected
                - ISOLATE MCP context to current commit files only (not entire plan)
                - Follow plan branch sequencing EXACTLY as specified
                - Report ANY discrepancies between plan and actual state immediately

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

## Plan Adherence Requirements

**CRITICAL**: When executing git-commit through PEER with commit plans, the following requirements are inviolable:

### Plan Immutability
- Commit plans represent approved execution sequences that MUST NOT be modified autonomously
- All plan steps, file specifications, commit messages, and branch targeting are binding
- Any deviations from the plan require explicit user confirmation
- Subagents MUST NOT make independent decisions about plan modifications

### Execution Constraints
- File staging MUST match exactly what is specified in the plan
- Commit messages MUST use the exact text from the plan specification
- Branch creation and switching MUST follow plan sequencing exactly
- No additional files may be staged beyond plan requirements
- No additional commits may be created beyond plan specifications

### Deviation Handling
- ALL deviations from the plan MUST trigger immediate execution halt
- Users MUST be presented with clear deviation details and impact assessment
- Execution may only continue after explicit user confirmation of deviation
- Deviations MUST be recorded in NATS KV state for audit purposes

### MCP Context Isolation
- MCP validation MUST receive only files relevant to the current commit
- MCP MUST NOT receive the entire plan context or unrelated files
- Each commit in a multi-commit plan MUST be validated independently
- MCP context isolation prevents over-validation and maintains plan integrity

### Subagent Constraints
- All delegated agents receive explicit constraints preventing autonomous plan modifications
- Subagents MUST report unexpected conditions rather than making assumptions
- No subagent may stage, commit, or branch beyond explicit plan specifications
- All subagent operations MUST align with plan adherence requirements

### Failure Recovery
- Plan execution failures MUST preserve partial progress in NATS KV state
- Resume functionality MUST maintain plan adherence for remaining steps
- Conflict resolution MUST not violate plan specifications
- Recovery operations MUST undergo deviation detection before proceeding

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
- **Required**: No (mutually exclusive with --plan and --branch)
- **Description**: Resume incomplete git commit execution from NATS KV state
- **Behavior**: Searches for incomplete executions and prompts user to select
- **Example**: `--continue`


### --branch
- **Type**: String (branch name)
- **Required**: No (requires --plan to be provided)
- **Description**: Execute only the specified branch from the commit plan (partial execution)
- **Validation**: Branch name must exist in the provided plan file
- **Behavior**: Sets execution to partial mode, restores original files after completion
- **Example**: `--branch=feature/authentication`

## Error Handling

<error_patterns>
  
  <action>
    DELEGATE: all error handling to git-error-recovery.md
    
    REFERENCE: @~/.agent-os/instructions/meta/git-error-recovery.md
    EXECUTE: Comprehensive error handling workflows:
      1. Error Classification and Detection workflow
      2. Transient Error Handling workflow (with retry strategies)
      3. Permanent Error Recovery workflow (conflicts, corruption, permissions)
      4. State Preservation During Errors workflow  
      5. Recovery Verification and Validation workflow
      6. Error Reporting and User Communication workflow
    
    COORDINATE: with user-interaction-workflows.md for user guidance
    INTEGRATE: with git-commit-state-management.md for error state persistence
    SUPPORT: all error types across git operations, validation, and state management
    PROVIDE: context-sensitive error reporting and recovery instructions
    MAINTAIN: execution state preservation and resume capability
  </action>

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