# Spec Requirements Document

> Spec: Agent OS v1.4.1 Migration and Extension Modularization
> Created: 2025-08-19
> Updated: 2025-08-19

## Overview

Merge upstream Agent OS v1.4.1 changes while preserving all custom functionality through a modular extension architecture. This migration will prevent future merge conflicts and improve maintainability by separating custom features into a two-tier extension system with global and project-level components.

## User Stories

### Agent OS Maintainer Story

As an Agent OS maintainer, I want to merge upstream v1.4.1 changes seamlessly, so that I can benefit from upstream improvements while preserving all custom functionality and preventing future merge conflicts.

**Detailed Workflow:**
1. Merge upstream changes with conflict resolution strategy
2. Implement two-tier extension architecture (global and project)
3. Refactor custom code into appropriate extension modules
4. Update configuration hierarchy with base and project overrides
5. Validate all existing functionality continues working
6. Remove deprecated setup scripts
7. Document the new extension architecture for future development

### Agent OS User Story

As an Agent OS user, I want all existing functionality to continue working after the migration, so that my workflows remain uninterrupted while benefiting from upstream improvements.

### Extension Developer Story

As a future extension developer, I want a clear modular architecture with distinction between global and project extensions, so that I can add new features without conflicts and understand how to integrate with the system.

## Spec Scope

1. **Upstream Merge** - Complete merge of Agent OS v1.4.1 with conflict resolution preserving custom setup scripts temporarily
2. **Two-Tier Extension Architecture** - Create global extensions in ~/.agent-os/ and project extensions in .agent-os/ with appropriate separation
3. **Path Migration** - Update all references from ~/.agent-os to .agent-os for project-local configuration where appropriate
4. **Configuration Hierarchy** - Implement base config.yml with project override capability and extension enable/disable controls
5. **Compatibility Preservation** - Ensure sandbox (global), hooks (global), and PEER pattern (project) functionality works
6. **Script Deprecation** - Refactor old setup scripts to use extensions, then delete them

## Out of Scope

- Breaking changes to user-facing APIs
- Removal of any existing custom functionality
- Major refactoring beyond what's necessary for modularization
- Changes to core Agent OS behavior beyond v1.4.1 updates
- New feature development unrelated to migration
- Project-specific hooks (keeping hooks global for now)
- Extension versioning system (future roadmap item)
- Third-party extension support (future consideration)

## Expected Deliverable

1. **Successfully merged codebase** with v1.4.1 upstream changes via two-PR strategy
2. **Two-tier extension system** with global (sandbox) and project (hooks, PEER) extensions
3. **Configuration hierarchy** with base defaults and per-project overrides
4. **Updated paths** with appropriate global/project separation
5. **Validated functionality** with all existing features working correctly
6. **Removed legacy scripts** after successful migration
7. **MIGRATION.md documentation** explaining changes and new architecture