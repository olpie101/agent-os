# Spec Requirements Document

> Spec: PEER Git Commit Plan Execution
> Created: 2025-08-13

## Cross-References

This spec is supported by:
- **Technical Specification:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/sub-specs/technical-spec.md
- **Implementation Tasks:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/tasks.md
- **Commit Plan Schema:** @~/.agent-os/instructions/meta/commit-plan-schema.md
- **XML Workflow Instructions:**
  - @~/.agent-os/instructions/meta/git-commit-state-management.md
  - @~/.agent-os/instructions/meta/commit-plan-validation.md
  - @~/.agent-os/instructions/meta/multi-branch-execution.md
  - @~/.agent-os/instructions/meta/user-interaction-workflows.md
  - @~/.agent-os/instructions/meta/git-error-recovery.md
- **Best Practices:** @.agent-os/product/dev-best-practices.md (XML declarative instruction patterns)

## Overview

Implement a comprehensive git commit plan execution system that manages complex multi-branch commit operations through pure XML declarative workflows and NATS KV state management. This feature enables agents to execute commit plans from both JSON and Markdown formats with conflict handling, branch management, and resume capability after interruptions. The system implements all functionality through XML declarative patterns defined in instructions/meta/, ensuring agents can read and execute specifications without any procedural scripts or brittle automation dependencies.

## User Stories

### Agent Executes Commit Plan with State Persistence

As a development agent, I want to execute a git commit plan while maintaining execution state in NATS KV using XML declarative patterns, so that I can track progress, handle conflicts, and resume interrupted operations without relying on brittle scripting.

The agent reads a commit plan file from `.agent-os/commit-plan/` (supporting both JSON and Markdown formats) using XML declarative file processing workflows, automatically detects and converts Markdown to JSON format through XML conversion patterns, creates state in NATS KV with key `peer.commit.yyyy.mm.dd.hh.mm` (matching the plan filename) using XML state management workflows, and systematically executes each commit according to XML workflow specifications while tracking progress through declarative state updates.

### User Handles Merge Conflicts with Continue Pattern

As a user, I want to resolve merge conflicts and resume commit plan execution using `/peer --instruction=git-commit --continue`, so that I can maintain workflow continuity after manual conflict resolution.

When conflicts occur during execution, the system uses XML declarative conflict handling workflows to stash remaining files with clear labels like "PEER-git-commit: remaining files from [branch-name]" and transitions to paused state. The user resolves conflicts manually, then uses the continue command to resume from the saved state using XML-based resume workflows.

### Agent Manages Multi-Branch Dependencies

As a development agent, I want to handle files required by multiple branches through user-guided decisions using XML declarative user interaction patterns, so that commit plans can accommodate complex branching strategies without manual intervention or brittle scripting.

When a file is needed for commits on multiple branches, the agent uses XML-based user interaction workflows to prompt the user to either merge the dependent branch first or create a new branch from the dependency. This ensures clean commit histories while maintaining flexibility through declarative decision workflows.

## Spec Scope

1. **Dual Format Support** - XML declarative workflows to automatically detect and process both JSON and Markdown commit plan formats
2. **Format Conversion Logic** - XML-based Markdown parsing and conversion workflows to internal JSON format for consistent processing
3. **NATS KV State Management** - XML declarative state management workflows with timestamped keys for persistence and resume capability
4. **Commit Plan File Processing** - XML-based file reading and parsing workflows from .agent-os/commit-plan/ directory
5. **Multi-Branch Execution Logic** - XML declarative workflows to handle commits across multiple branches with dependency tracking
6. **Conflict Detection and Handling** - XML-based conflict detection and structured recovery workflows
7. **Stash Management** - XML declarative stash creation and management workflows with specific labels for clarity
8. **Continue Pattern Implementation** - XML-based resume capability workflows through --continue argument
9. **Branch Strategy Support** - XML declarative workflows supporting both new branch creation and current branch commits
10. **User Decision Points** - XML-based user interaction workflows for merge vs branch-off decisions for multi-branch file dependencies

## Out of Scope

- Automatic conflict resolution (user must resolve manually)
- Complex merge strategies beyond standard git merging
- Integration with external CI/CD systems
- Automatic rollback of partially completed plans
- Multi-repository support (single repository only)
- Plan generation or editing (execution only)

## Expected Deliverable

1. **Dual Format Processing**: XML declarative workflows automatically detect JSON vs Markdown format and process both correctly without JavaScript scripting
2. **Functional PEER Git Commit Execution**: `/peer --instruction=git-commit --plan=<filename>` successfully executes commit plans through XML declarative patterns with state persistence
3. **Resume Capability**: `/peer --instruction=git-commit --continue` resumes interrupted executions from NATS KV state using XML-based resume workflows
4. **Clear Conflict Handling**: XML declarative workflows stash files with descriptive labels and provide clear instructions for manual resolution
5. **Branch Management**: XML-based user interaction workflows for dependency resolution work correctly for multi-branch scenarios
6. **State Transparency**: NATS KV keys contain complete execution state allowing for external monitoring and debugging through XML state schemas
7. **Backward Compatibility**: Existing JSON plans continue to work without modification through XML compatibility patterns
8. **Agent Readability**: All processing logic expressed in XML declarative patterns that agents can read and convert to JSON execution plans without complex scripting