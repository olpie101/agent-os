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
        
      STORE parsed values for use in workflow
    </argument_parsing>
    
  </step>
  
  <step number="2" name="detect_execution_context">
    
    ### Step 2: Detect Execution Context
    
    <context_detection>
      DETERMINE execution context:
        IF invoked through PEER pattern:
          SET enhanced_mode = true
          NOTE: PEER executor will handle MCP validation
        ELSE:
          SET enhanced_mode = false
          PROCEED directly to git operations
    </context_detection>
    
  </step>
  
  <step number="3" name="delegate_to_git_workflow">
    
    ### Step 3: Delegate to Git Workflow
    
    <delegation>
      USE Task tool to invoke git-workflow agent:
        
      <Task>
        description: "Execute git commit workflow"
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
    </delegation>
    
  </step>
  
  <step number="4" name="completion_summary">
    
    ### Step 4: Completion Summary
    
    <summary>
      DISPLAY completion status:
        - Commit created successfully
        - Branch and commit details
        - Pull request URL if created
        
      IF enhanced_mode AND MCP was used:
        NOTE: Validation details available in PEER cycle output
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

## Error Handling

<error_patterns>
  <git_errors>
    - No changes to commit: Inform user no changes detected
    - Uncommitted changes: Let git-workflow handle staging
    - Push failures: Delegate to git-workflow error handling
  </git_errors>
  
  <validation_errors>
    - MCP validation failures: Handled by PEER executor
    - User cancellation: Exit gracefully with status message
  </validation_errors>
</error_patterns>

## Notes

- This instruction acts as a thin wrapper for git-workflow
- MCP validation only occurs when executed through PEER
- Direct execution provides standard git workflow without validation
- All git operations are handled by the git-workflow agent