# Spec Tasks

## Tasks

- [ ] 1. Phase 1: Foundation & Upstream Merge (PR 1)
  - [x] 1.1 Create merge branch from current state
  - [x] 1.2 Perform git merge upstream/main --no-commit
  - [x] 1.3 Preserve custom setup scripts during conflict resolution
  - [x] 1.4 Review and validate merge changes
  - [x] 1.5 Commit merge with detailed message
  - [x] 1.6 Add BASE_URL override to all setup scripts (base.sh, functions.sh, and project.sh)
  - [x] 1.7 Create extensions/ directory structure in this repository
  - [x] 1.8 Update config.yml template with extension configuration
  - [x] 1.9 Move sandbox profile to extensions/sandbox/profiles/
  - [x] 1.10 Create setup/base-extensions.sh script for global extensions
  - [x] 1.11 Create setup/project-extensions.sh stub for PR consistency
  - [x] 1.12 Add minimal call to base-extensions.sh in base.sh
  - [x] 1.13 Create sandbox extension in extensions/sandbox/ with install.sh
  - [x] 1.14 Add SANDBOX_INSTALL_DIR override to sandbox/install.sh
  - [x] 1.15 Configure base-extensions.sh to copy and install sandbox
  - [x] 1.16 Move claude-code-sandbox-launcher.sh to extensions/sandbox/launcher.sh
  - [x] 1.17 Update sandbox install.sh to install launcher script
  - [x] 1.18 Add BIN_DIR override to sandbox install.sh
  - [x] 1.19 Implement symlink creation in sandbox install.sh
  - [-] 1.20 Optionally add README.md creation to sandbox install.sh
  - [x] 1.21 Test sandbox extension installation process (Priority 1)
  - [x] 1.22 Verify extension loading framework works

- [ ] 2. Phase 2: Project Extensions Migration (PR 2 - dependent on PR 1)
  - [ ] 2.1 Implement full setup/project-extensions.sh (replace stub)
  - [ ] 2.2 Add minimal call to project-extensions.sh in project.sh
  - [ ] 2.3 Create hooks extension in extensions/hooks/ (install.sh and config.sh only)
  - [ ] 2.4 Configure hooks install.sh to reference claude-code/hooks/ source
  - [ ] 2.5 Configure hooks install.sh to copy to ~/.claude/hooks/
  - [-] 2.6 Move PEER scripts from scripts/peer/ to extensions/peer/scripts/
  - [-] 2.7 Create PEER extension in extensions/peer/ with install.sh
  - [-] 2.8 Update PEER scripts to reference .agent-os/scripts/peer/
  - [ ] 2.9 Configure project-extensions.sh to copy extensions and create .agent-os.yaml
  - [ ] 2.10 Add NATS configuration to .agent-os.yaml template
  - [ ] 2.11 Test hooks extension installation process (Priority 2)
  - [-] 2.12 Test PEER extension installation process (Priority 3)
  - [-] 2.13 Update all path references from ~/.agent-os to .agent-os for project-local components

- [ ] 3. Configuration System Integration
  - [x] 3.1 Update config.yml template in repo with extension defaults (completed in 1.8)
  - [ ] 3.2 Implement .agent-os.yaml creation in project-extensions.sh
  - [x] 3.3 Add extension enable/disable flags with "required" field for sandbox (completed in 1.8)
  - [ ] 3.4 Implement configuration hierarchy loading (base → .agent-os.yaml → env vars)
  - [ ] 3.5 Add NATS configuration with project-specific bucket support
  - [ ] 3.6 Test configuration override behavior
  - [ ] 3.7 Validate required extensions cannot be disabled
  - [ ] 3.8 Test .agent-os.yaml overrides work correctly

- [ ] 4. Error Handling & Logging
  - [ ] 4.1 Create installation.log for extension installation status
  - [ ] 4.2 Implement extension failure handling (warn for optional, fail for required)
  - [ ] 4.3 Add retry capability for failed extensions
  - [ ] 4.4 Create notification system for installation issues
  - [ ] 4.5 Test error scenarios with partial extension failures
  - [ ] 4.6 Verify required extension failures stop installation

- [ ] 5. Legacy Script Refactoring & Cleanup
  - [ ] 5.1 Refactor setup.sh to use extension system
  - [ ] 5.2 Refactor setup-claude-code.sh to use extension loader
  - [ ] 5.3 Test refactored scripts maintain functionality
  - [ ] 5.4 Delete original setup scripts after validation
  - [ ] 5.5 Update installation documentation

- [ ] 6. Local Development & Testing
  - [x] 6.1 Create setup/sync-local.sh for local development
  - [ ] 6.2 Test BASE_URL override with forked repository
  - [x] 6.3 Test local sync functionality
  - [x] 6.4 Test extension install.sh environment overrides
  - [x] 6.5 Verify sandbox SANDBOX_INSTALL_DIR override works
  - [x] 6.6 Verify sandbox BIN_DIR override works
  - [x] 6.7 Test symlink creation in ~/.local/bin/

- [ ] 7. Testing & Validation
  - [ ] 7.1 Test clean base installation with global extensions
  - [ ] 7.2 Test project installation with extension loading
  - [ ] 7.3 Test extension enable/disable via configuration
  - [ ] 7.4 Test path resolution after migration (global vs project)
  - [ ] 7.5 Test configuration override behavior (base → project → env)
  - [ ] 7.6 Test error handling for failed extensions
  - [ ] 7.7 Run full integration test suite
  - [ ] 7.8 Verify all tests pass before merging PRs

- [ ] 8. Documentation & Finalization
  - [ ] 8.1 Create MIGRATION.md explaining changes and new architecture
  - [ ] 8.2 Document two-tier extension system usage
  - [ ] 8.3 Document configuration hierarchy and override behavior
  - [ ] 8.4 Document BASE_URL override mechanism
  - [ ] 8.5 Document sync-local.sh usage for development
  - [ ] 8.6 Create troubleshooting guide for common issues
  - [ ] 8.7 Update project README with new installation process
  - [ ] 8.8 Document extension development guidelines with install.sh patterns
  - [ ] 8.9 Verify all functionality works before final merge
