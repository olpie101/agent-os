# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/spec.md

## Cross-References

This technical specification references and works with:
- **Main Spec:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/spec.md
- **Tasks:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/tasks.md
- **Commit Plan Schema:** @~/.agent-os/instructions/meta/commit-plan-schema.md
- **XML Workflow Instructions:**
  - @~/.agent-os/instructions/meta/git-commit-state-management.md (state operations)
  - @~/.agent-os/instructions/meta/commit-plan-validation.md (plan validation)
  - @~/.agent-os/instructions/meta/multi-branch-execution.md (git operations)
  - @~/.agent-os/instructions/meta/user-interaction-workflows.md (decision points)
  - @~/.agent-os/instructions/meta/git-error-recovery.md (error handling)
- **Best Practices:** @.agent-os/product/dev-best-practices.md (XML declarative patterns)
- **PEER Pattern:** @~/.agent-os/instructions/core/peer.md (state management)

## Technical Requirements

### Input Format Detection and Processing

The system supports both JSON and Markdown commit plan formats with automatic detection and conversion using XML declarative patterns.

**Format Detection Workflow (XML Declarative Pattern):**

<format_detection_workflow>
  <input_validation>
    <action>READ file content from specified path</action>
    <validation>verify file exists and is readable</validation>
    <cleanup>trim whitespace from content</cleanup>
  </input_validation>
  
  <format_identification>
    <json_detection>
      <condition>content starts with '{' AND ends with '}'</condition>
      <verification>
        <action>ATTEMPT JSON parsing of content</action>
        <on_success>SET format = 'json'</on_success>
        <on_failure>SET format = 'markdown' (malformed JSON)</on_failure>
      </verification>
    </json_detection>
    
    <markdown_detection>
      <condition>format not yet determined</condition>
      <pattern_matching>
        <header_patterns>
          - "# Multi-Commit Plan" (markdown header)
          - "## Commit Groups" (section header)
        </header_patterns>
        <on_match>SET format = 'markdown'</on_match>
      </pattern_matching>
    </markdown_detection>
    
    <default_handling>
      <condition>no format detected</condition>
      <action>SET format = 'markdown' (safe default)</action>
    </default_handling>
  </format_identification>
</format_detection_workflow>

**Markdown to JSON Conversion Workflow (XML Declarative Pattern):**

The system parses Markdown commit plans structured like the sample at `.agent-os/commit-plan/2025-08-13-19-00-plan.md` and converts them to the internal JSON format.

<markdown_conversion_workflow>
  <parsing_initialization>
    <action>SPLIT markdown content by newline characters</action>
    <state_variables>
      - commit_groups: empty array
      - current_branch: null
      - current_commit: null
    </state_variables>
  </parsing_initialization>
  
  <line_processing_loop>
    <for_each_line>
      <branch_header_detection>
        <pattern>"### Branch: [branch-name]"</pattern>
        <action>SET current_branch = extracted branch name</action>
        <flow>CONTINUE to next line</flow>
      </branch_header_detection>
      
      <commit_header_detection>
        <pattern>"#### Commit N: [emoji] [message]"</pattern>
        <action>
          IF current_commit exists:
            ADD current_commit to commit_groups
          CREATE new current_commit with:
            - branch: current_branch
            - message: extracted message
            - files: empty array
            - requires_branches: empty array
        </action>
        <flow>CONTINUE to next line</flow>
      </commit_header_detection>
      
      <file_entry_detection>
        <pattern>"- [filepath] (optional operation)"</pattern>
        <condition>current_commit exists</condition>
        <processing>
          EXTRACT filepath and operation (default: 'ADD')
          IF operation == 'DELETE':
            CREATE deletions array if not exists
            ADD filepath to current_commit.deletions
          ELSE:
            ADD filepath to current_commit.files
        </processing>
        <flow>CONTINUE to next line</flow>
      </file_entry_detection>
    </for_each_line>
  </line_processing_loop>
  
  <finalization>
    <final_commit_handling>
      <condition>current_commit exists after loop</condition>
      <action>ADD current_commit to commit_groups</action>
    </final_commit_handling>
    
    <timestamp_generation>
      <source_extraction>
        <pattern>extract "YYYY-MM-DD-HH-MM" from plan filename</pattern>
        <fallback>use current timestamp if extraction fails</fallback>
      </source_extraction>
      <format_conversion>
        <action>CONVERT to ISO 8601 format</action>
        <example>"2025-08-13T17:30:00Z"</example>
      </format_conversion>
    </timestamp_generation>
    
    <json_structure_creation>
      <root_object>
        - version: 1
        - plan_id: "git-commit-[timestamp]Z"
        - metadata: object with created_at, instruction, user_intent, source_format
        - execution_plan: object containing commits array
      </root_object>
    </json_structure_creation>
  </finalization>
</markdown_conversion_workflow>

### NATS KV State Schema

**State Key Format:** `peer.commit.yyyy.mm.dd.hh.mm` (matches commit plan filename using dots for NATS compatibility)

**State Object Structure:**
```json
{
  "version": 1,
  "plan_file": "2025-08-13-19-00-plan.md",
  "plan_format": "markdown|json",
  "execution_id": "peer.commit.2025.08.13.17.30",
  "status": "in_progress|completed|failed|paused_for_conflict",
  "created_at": "2025-08-13T17:30:00Z",
  "updated_at": "2025-08-13T17:35:00Z",
  "current_branch": "main",
  "original_branch": "main",
  "plan": {
    "expected_branches": ["main", "feature/auth", "feature/ui"],
    "total_commits": 5,
    "commits_per_branch": {"main": 2, "feature/auth": 2, "feature/ui": 1},
    "source_format": "markdown"
  },
  "progress": {
    "current_step": 3,
    "total_steps": 5,
    "completed_commits": ["abc123", "def456"],
    "current_commit_files": ["src/auth.js", "src/ui.js"],
    "remaining_commits": 2
  },
  "conflict_context": {
    "conflicted_files": ["src/auth.js"],
    "stash_ref": "stash@{0}",
    "stash_message": "PEER-git-commit: remaining files from feature/auth",
    "resolution_branch": "feature/auth"
  },
  "branch_dependencies": {
    "files_needing_merge": ["src/shared.js"],
    "dependent_branches": ["feature/auth", "feature/ui"],
    "user_decision": null
  }
}
```

### Commit Plan File Structure

**Schema Reference:** @~/.agent-os/instructions/meta/commit-plan-schema.md

**Location:** `.agent-os/commit-plan/` (supports both `.json` and `.md` files)

**Supported Formats:**

1. **JSON Format** - Direct structured data
2. **Markdown Format** - Human-readable format with structured headings (like `2025-08-13-19-00-plan.md`)

**JSON Format Structure (with version field):**
```json
{
  "version": 1,
  "plan_id": "git-commit-20250813T173000Z",
  "metadata": {
    "created_at": "2025-08-13T17:30:00Z",
    "instruction": "git-commit",
    "user_intent": "Multi-feature commit plan"
  },
  "execution_plan": {
    "commits": [
      {
        "branch": "main",
        "files": ["README.md"],
        "message": "docs: update README with new features",
        "requires_branches": []
      },
      {
        "branch": "feature/auth",
        "files": ["src/auth.js", "src/shared.js"],
        "message": "feat: implement authentication system",
        "requires_branches": ["main"]
      }
    ]
  }
}
```

**Markdown Format Structure:**

Markdown plans follow the structure pattern shown in `.agent-os/commit-plan/2025-08-13-19-00-plan.md`:

```markdown
# Multi-Commit Plan
Generated: 2025-08-13 19:00
Repository: /path/to/repo
Current Branch: current-branch

## Branch Strategy
Description of branching approach...

## Commit Groups

### Branch: branch-name
Base: base-branch

#### Commit 1: 🎯 Commit message here
**Files:**
- path/to/file1.js
- path/to/file2.md (DELETE)

**Rationale:** Explanation of why this commit exists.

#### Commit 2: 📝 Another commit message
**Files:**  
- path/to/file3.js
- path/to/file4.md

**Rationale:** Another explanation.
```

**Markdown Parsing Rules:**
- Branch headers: `### Branch: <branch-name>`  
- Commit headers: `#### Commit N: <emoji> <message>`
- File lists: Lines starting with `- <filepath>` under **Files:** sections
- DELETE operations: `(DELETE)` suffix on file lines
- Rationale sections are informational only (not processed)

**Format Detection Logic (XML Declarative Pattern):**

<format_detection_logic>
  <extension_based_detection>
    <json_extension>
      <condition>file extension equals '.json'</condition>
      <action>SET processing_mode = 'json'</action>
    </json_extension>
    
    <markdown_extension>
      <condition>file extension equals '.md'</condition>
      <action>SET processing_mode = 'markdown'</action>
    </markdown_extension>
  </extension_based_detection>
  
  <content_based_detection>
    <condition>no file extension present</condition>
    <workflow>USE format_detection_workflow from above</workflow>
    <result>SET processing_mode based on content analysis</result>
  </content_based_detection>
  
  <conversion_requirement>
    <condition>processing_mode = 'markdown'</condition>
    <action>APPLY markdown_conversion_workflow to generate JSON</action>
    <purpose>ensure consistent processing format</purpose>
  </conversion_requirement>
</format_detection_logic>

### Git Commit Integration

**Enhanced git-commit.md Arguments:**
- `--plan=<filename>`: Specify commit plan file to execute
- `--continue`: Resume from NATS KV state after conflict resolution

**Execution Context Detection (XML Declarative Pattern):**

<execution_context_determination>
  <mode_detection>
    <plan_execution_mode>
      <condition>--plan argument provided</condition>
      <actions>
        - SET: MODE = plan_execution
        - LOAD: plan file from .agent-os/commit-plan/${plan}
        - DETECT: file format (JSON vs Markdown)
        - CONVERT: Markdown to JSON if needed
        - VALIDATE: converted plan structure
        - CREATE: NATS KV state with timestamped key
      </actions>
    </plan_execution_mode>
    
    <resume_execution_mode>
      <condition>--continue argument provided</condition>
      <actions>
        - SET: MODE = resume_execution
        - FIND: latest incomplete state in NATS KV
        - RESUME: from saved progress
      </actions>
    </resume_execution_mode>
    
    <standard_mode>
      <condition>neither --plan nor --continue provided</condition>
      <actions>
        - SET: MODE = standard_commit (existing behavior)
      </actions>
    </standard_mode>
  </mode_detection>
</execution_context_determination>

### Conflict Resolution Workflow

**Stash Naming Convention:**
- Format: `PEER-git-commit: remaining files from [branch-name]`
- Examples: 
  - `PEER-git-commit: remaining files from feature/auth`
  - `PEER-git-commit: remaining files from main`

**Resolution Process:**
1. Detect merge conflict during commit
2. Stash uncommitted files with descriptive message
3. Update NATS KV state to `paused_for_conflict`
4. Provide user with clear resolution instructions
5. User resolves conflicts manually
6. User runs `/peer --instruction=git-commit --continue`
7. System restores stashed files and resumes execution

### Multi-Branch Dependency Handling

**Decision Points with Visual Guidance:**

When a file is required by multiple branches, present user with visual decision tree:

```
Current Situation:
┌─────────────────────────────────────────────────┐
│ File "src/shared.js" needed by multiple branches│
│                                                 │
│  main     ──●──●                               │
│              \                                  │
│  feature/auth ●──●  (needs shared.js)         │
│              \                                  │
│  feature/ui   ●  (also needs shared.js)       │
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

**User Prompt Structure (XML Declarative Pattern):**

<user_interaction_workflow>
  <trigger_condition>file required by multiple branches</trigger_condition>
  
  <presentation_flow>
    <display_step>
      <action>DISPLAY visual decision tree</action>
      <content>ASCII diagram from visual_guide section above</content>
    </display_step>
    
    <user_prompt>
      <option id="merge_dependency">
        <label>Merge branch [dependency] into [current] first</label>
        <consequences>
          <immediate>Merges dependency branch content</immediate>
          <future>Single unified branch with all changes</future>
          <risks>Potential conflicts, larger changeset</risks>
          <benefits>Simplified workflow, related changes together</benefits>
        </consequences>
      </option>
      
      <option id="create_new_branch">
        <label>Create new branch from [dependency] for this work</label>
        <consequences>
          <immediate>Creates isolated branch for new work</immediate>
          <future>Separate pull requests for each feature</future>
          <risks>More complex merge process, potential conflicts</risks>
          <benefits>Smaller focused commits, easier review</benefits>
        </consequences>
      </option>
      
      <option id="skip_file">
        <label>Skip this file for now (manual handling required)</label>
        <consequences>
          <immediate>File excluded from current commit</immediate>
          <future>Manual resolution required later</future>
          <risks>Incomplete implementation, manual work needed</risks>
          <benefits>Avoids complex branching decisions now</benefits>
        </consequences>
      </option>
    </user_prompt>
    
    <execution_flow>
      <wait_step>
        <action>WAIT for user selection</action>
        <validation>ensure valid option selected</validation>
      </wait_step>
      
      <execution_step>
        <action>EXECUTE chosen strategy with confirmation</action>
        <confirmation>display strategy summary before proceeding</confirmation>
      </execution_step>
      
      <state_update_step>
        <action>UPDATE NATS KV state with decision and reasoning</action>
        <fields>user_choice, reasoning, execution_timestamp</fields>
      </state_update_step>
    </execution_flow>
  </presentation_flow>
</user_interaction_workflow>

**Branch Strategy Support:**
- **New Branch Mode**: Creates branches per commit plan specification
- **Current Branch Mode**: Commits to existing branch without switching
- **Hybrid Mode**: Mixes strategies based on plan requirements

### State Management Operations

**All state management operations are implemented through XML declarative workflows defined in:**
- @~/.agent-os/instructions/meta/git-commit-state-management.md

**State Operations Overview:**

<state_operations_reference>
  <state_creation>
    WORKFLOW: State Creation Workflow in git-commit-state-management.md
    PURPOSE: Initialize execution state with timestamped NATS KV keys
    KEY_FORMAT: peer.commit.yyyy.mm.dd.hh.mm (extracted from plan filename)
    VALIDATION: Complete state structure validation before storage
  </state_creation>
  
  <progress_updates>
    WORKFLOW: Progress Update Workflow in git-commit-state-management.md
    PURPOSE: Track execution progress through commit completion
    OPERATIONS: Increment counters, record commit hashes, update file contexts
    VALIDATION: State integrity maintained through wrapper scripts
  </progress_updates>
  
  <conflict_management>
    WORKFLOW: Conflict State Management in git-commit-state-management.md
    PURPOSE: Handle merge conflicts with descriptive stashing and user guidance
    STATE_TRANSITIONS: "in_progress" → "paused_for_conflict" → resume capability
    PRESERVATION: User work protected through labeled git stashes
  </conflict_management>
  
  <resume_operations>
    WORKFLOW: Resume State Discovery in git-commit-state-management.md
    PURPOSE: Enable continuation after interruptions or conflicts
    DISCOVERY: Search NATS KV for incomplete executions
    USER_INTERACTION: Selection menu for multiple resumable executions
  </resume_operations>
</state_operations_reference>

**Integration with NATS KV Operations:**

All state operations strictly follow @~/.agent-os/instructions/meta/nats-kv-operations.md patterns using wrapper scripts for data integrity and validation.

### Error Handling Strategies

**All error handling and recovery operations are implemented through XML declarative workflows defined in:**
- @~/.agent-os/instructions/meta/git-error-recovery.md

**Error Handling Overview:**

<error_handling_reference>
  <error_classification>
    WORKFLOW: Error Classification and Detection in git-error-recovery.md
    PURPOSE: Systematic identification and categorization of git operation failures
    CATEGORIES: Transient (network, locks, timeouts), Permanent (conflicts, corruption), Critical (system failures)
    MONITORING: Command exit codes, error message parsing, repository state analysis
  </error_classification>
  
  <transient_error_handling>
    WORKFLOW: Transient Error Handling in git-error-recovery.md
    STRATEGIES: Exponential backoff retry, adaptive timeout adjustment, pattern detection
    ESCALATION: Automatic promotion to permanent error handling after retry exhaustion
    OPTIMIZATION: Learning from success/failure patterns for efficiency
  </transient_error_handling>
  
  <permanent_error_recovery>
    WORKFLOW: Permanent Error Recovery in git-error-recovery.md
    CONFLICT_RESOLUTION: Merge conflict detection, descriptive stashing, user guidance workflows
    CORRUPTION_REPAIR: Repository integrity assessment, automated repair attempts, manual intervention guidance
    PERMISSION_RESOLUTION: Access issue diagnosis, safe permission change suggestions, resume preparation
  </permanent_error_recovery>
  
  <state_preservation>
    WORKFLOW: State Preservation During Errors in git-error-recovery.md
    PURPOSE: Maintain execution context and user work during error conditions
    OPERATIONS: Error context capture, NATS state updates, recovery validation
    INTEGRATION: Seamless coordination with state management and user interaction workflows
  </state_preservation>
</error_handling_reference>

**Recovery Validation:**

All recovery operations include comprehensive validation through git-error-recovery.md workflows to ensure safe execution continuation after intervention.

### Integration Points

**With Existing git-commit.md:**
- Extends current functionality without breaking changes
- Uses existing git-workflow agent for git operations
- Maintains backward compatibility for standard commits

**With PEER Pattern:**
- Leverages PEER state management for persistence
- Integrates with PEER continue pattern
- Uses PEER validation for commit plan integrity

**With Agent OS Standards:**
- Follows Agent OS file naming conventions
- Uses standard directory structures
- Integrates with existing workflow patterns

### Explicitly Excluded Features

The following features are intentionally **NOT** included in this implementation:

**Performance Optimization:**
- Commit plan files are expected to be under 50KB
- No special optimization strategies implemented
- Simple file I/O operations sufficient for current scope

**Rollback Procedures:**
- Automatic rollback mechanisms deferred to future iteration
- Users expected to handle git rollbacks manually if needed
- NATS state provides audit trail but no automatic recovery

**Rationale:**
- Performance optimization not needed for small plan files (confirmed during review)
- Rollback procedures add complexity without immediate necessity
- Focus maintained on core functionality and user decision guidance