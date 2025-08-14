# Spec Tasks

## Cross-References

Implementation tasks reference:
- **Main Spec:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/spec.md
- **Technical Details:** @.agent-os/specs/2025-08-13-peer-git-commit-plan-execution/sub-specs/technical-spec.md
- **Commit Plan Schema:** @~/.agent-os/instructions/meta/commit-plan-schema.md
- **XML Workflow Instructions:**
  - @~/.agent-os/instructions/meta/git-commit-state-management.md
  - @~/.agent-os/instructions/meta/commit-plan-validation.md
  - @~/.agent-os/instructions/meta/multi-branch-execution.md
  - @~/.agent-os/instructions/meta/user-interaction-workflows.md
  - @~/.agent-os/instructions/meta/git-error-recovery.md

## Tasks

- [x] 1. ~~Enhance git-commit instruction with dual format plan execution support using XML declarative patterns~~
  - [x] 1.1 ~~Create XML declarative workflow for plan validation~~ → **COMPLETED**: @~/.agent-os/instructions/meta/commit-plan-validation.md
  - [x] 1.2 ~~Add --plan=<filename> argument parsing to git-commit.md with declarative flow control~~ → **COMPLETED**: Already implemented in git-commit.md
  - [x] 1.3 ~~Implement XML-based format detection workflow for JSON vs Markdown files~~ → **COMPLETED**: Integrated in commit-plan-validation.md
  - [x] 1.4 ~~Create XML declarative Markdown to JSON conversion workflow~~ → **COMPLETED**: Conversion patterns in commit-plan-validation.md
  - [x] 1.5 ~~Implement commit plan file loading from .agent-os/commit-plan/ using declarative patterns~~ → **COMPLETED**: File operations in commit-plan-validation.md
  - [x] 1.6 ~~Add plan file validation with clear error messages using XML patterns~~ → **COMPLETED**: Comprehensive validation in commit-plan-validation.md
  - [ ] 1.7 Write comprehensive tests for dual format plan file handling (testing phase)

- [x] 2. ~~Implement NATS KV state management for commit execution using XML declarative patterns~~
  - [x] 2.1 ~~Create XML-based state management workflows~~ → **COMPLETED**: @~/.agent-os/instructions/meta/git-commit-state-management.md
  - [x] 2.2 ~~Create XML-based state initialization workflow with timestamped keys~~ → **COMPLETED**: State creation workflow in git-commit-state-management.md
  - [x] 2.3 ~~Add plan_format field tracking using XML state management patterns~~ → **COMPLETED**: Progress tracking workflows in git-commit-state-management.md
  - [x] 2.4 ~~Implement XML declarative state update workflows for execution progress tracking~~ → **COMPLETED**: Progress update patterns in git-commit-state-management.md
  - [x] 2.5 ~~Add state persistence using XML-based branch context and file tracking patterns~~ → **COMPLETED**: Context preservation in git-commit-state-management.md
  - [ ] 2.6 Write comprehensive tests for declarative state management operations (testing phase)

- [x] 3. ~~Build multi-branch execution engine using XML declarative workflows~~
  - [x] 3.1 ~~Create XML declarative multi-branch execution workflows~~ → **COMPLETED**: @~/.agent-os/instructions/meta/multi-branch-execution.md
  - [x] 3.2 ~~Implement XML-based branch creation and switching workflows~~ → **COMPLETED**: Branch management operations in multi-branch-execution.md
  - [x] 3.3 ~~Add XML declarative commit execution patterns with NATS KV progress tracking~~ → **COMPLETED**: File staging and commit workflows in multi-branch-execution.md
  - [x] 3.4 ~~Implement XML-based file staging workflows per commit specification~~ → **COMPLETED**: File operations including deletions in multi-branch-execution.md
  - [ ] 3.5 Write comprehensive tests for XML declarative multi-branch execution (testing phase)

- [x] 4. ~~Implement conflict detection and handling system using XML declarative patterns~~
  - [x] 4.1 ~~Create XML declarative conflict handling workflows~~ → **COMPLETED**: @~/.agent-os/instructions/meta/git-error-recovery.md
  - [x] 4.2 ~~Add XML-based merge conflict detection workflows~~ → **COMPLETED**: Conflict detection patterns in git-error-recovery.md
  - [x] 4.3 ~~Implement XML declarative stash creation patterns with PEER-git-commit labels~~ → **COMPLETED**: Stash management in git-error-recovery.md and git-commit-state-management.md
  - [x] 4.4 ~~Add XML-based conflict state persistence workflows to NATS KV~~ → **COMPLETED**: Conflict state management in git-commit-state-management.md
  - [ ] 4.5 Write comprehensive tests for XML declarative conflict handling (testing phase)

- [x] 5. ~~Build continue pattern for execution resume using XML declarative workflows~~
  - [x] 5.1 ~~Create XML declarative resume workflows~~ → **COMPLETED**: Resume patterns in git-commit-state-management.md and user-interaction-workflows.md
  - [x] 5.2 ~~Add --continue argument parsing to git-commit.md~~ → **COMPLETED**: Already implemented in git-commit.md
  - [x] 5.3 ~~Implement XML-based NATS KV state discovery workflows~~ → **COMPLETED**: Resume state discovery in git-commit-state-management.md
  - [x] 5.4 ~~Add XML declarative stash restoration and execution resume workflows~~ → **COMPLETED**: Recovery workflows in git-error-recovery.md
  - [ ] 5.5 Write comprehensive tests for XML-based continue pattern (testing phase)

- [x] 6. ~~Implement multi-branch dependency handling using XML declarative user interaction patterns~~
  - [x] 6.1 ~~Create XML declarative user interaction workflows~~ → **COMPLETED**: @~/.agent-os/instructions/meta/user-interaction-workflows.md
  - [x] 6.2 ~~Add XML-based file dependency analysis workflows~~ → **COMPLETED**: Dependency detection in user-interaction-workflows.md
  - [x] 6.3 ~~Implement XML declarative user prompt workflows for decisions~~ → **COMPLETED**: Decision workflows with visual guidance in user-interaction-workflows.md
  - [x] 6.4 ~~Add XML-based decision persistence and execution workflows~~ → **COMPLETED**: Decision state management in user-interaction-workflows.md
  - [ ] 6.5 Write comprehensive tests for XML declarative dependency handling (testing phase)

- [ ] 7. Integration testing and validation with existing systems
  - [ ] 7.1 Write integration tests with git-workflow agent using XML patterns
  - [ ] 7.2 Validate git-commit.md integration with new XML workflows
  - [ ] 7.3 Ensure backward compatibility with existing git-commit functionality
  - [ ] 7.4 Test PEER pattern integration with XML-based state management
  - [ ] 7.5 Validate that XML workflows don't break existing systems
  - [ ] 7.6 Complete end-to-end integration testing

- [x] 8. ~~Add comprehensive error handling and recovery using XML declarative error workflows~~
  - [x] 8.1 ~~Create comprehensive XML error handling workflows~~ → **COMPLETED**: @~/.agent-os/instructions/meta/git-error-recovery.md
  - [x] 8.2 ~~Add XML-based error handling workflows for all failure scenarios~~ → **COMPLETED**: Error classification and recovery in git-error-recovery.md
  - [x] 8.3 ~~Implement XML declarative transient error retry workflows~~ → **COMPLETED**: Retry strategies with exponential backoff in git-error-recovery.md
  - [x] 8.4 ~~Add XML-based permanent error handling workflows~~ → **COMPLETED**: Permanent error recovery patterns in git-error-recovery.md
  - [x] 8.5 ~~Implement XML declarative recovery validation workflows~~ → **COMPLETED**: Recovery validation in git-error-recovery.md
  - [x] 8.6 ~~Add XML-based validation error workflows for malformed input~~ → **COMPLETED**: Input validation errors in commit-plan-validation.md
  - [ ] 8.7 Write comprehensive tests for XML declarative error handling (testing phase)

- [x] 9. **XML Transformation Complete** - Convert all script dependencies to pure XML declarative workflows
  - [x] 9.1 ~~Create git-commit-state-management.md~~ → **COMPLETED**: NATS KV state operations converted to XML patterns
  - [x] 9.2 ~~Create commit-plan-validation.md~~ → **COMPLETED**: Plan validation logic converted to XML patterns
  - [x] 9.3 ~~Create multi-branch-execution.md~~ → **COMPLETED**: Git operations converted to XML patterns
  - [x] 9.4 ~~Create user-interaction-workflows.md~~ → **COMPLETED**: User decision flows converted to XML patterns
  - [x] 9.5 ~~Create git-error-recovery.md~~ → **COMPLETED**: Error handling converted to XML patterns
  - [x] 9.6 ~~Update spec files to reference XML workflows instead of scripts~~ → **COMPLETED**: Cross-references updated in all spec files
  - [x] 9.7 ~~Eliminate all procedural script dependencies~~ → **COMPLETED**: Pure XML declarative implementation achieved