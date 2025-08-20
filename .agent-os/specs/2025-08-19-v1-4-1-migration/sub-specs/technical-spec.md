# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-19-v1-4-1-migration/spec.md

## Technical Requirements

### BASE_URL Override Mechanism
- Modify all BASE_URL definitions in setup scripts to support environment variable override
- Changes required:
  - `base.sh` line 16: `BASE_URL="${AGENT_OS_BASE_URL:-https://raw.githubusercontent.com/buildermethods/agent-os/main}"`
  - `functions.sh` line 7: `BASE_URL="${AGENT_OS_BASE_URL:-https://raw.githubusercontent.com/buildermethods/agent-os/main}"`
  - `project.sh` line 83: `BASE_URL="${AGENT_OS_BASE_URL:-https://raw.githubusercontent.com/buildermethods/agent-os/main}"`
- Provides consistency across all setup scripts
- Allows testing with fork: `AGENT_OS_BASE_URL=https://raw.githubusercontent.com/yourusername/agent-os/branch`
- Falls back to upstream if not set
- Ensures all download scenarios (base install, project install, --no-base) use the override

### Local Development Support
- Create `setup/sync-local.sh` script for copying local files to base installation
- Enables rapid testing without GitHub commits
- Syncs: instructions/, standards/, commands/, config.yml, claude-code/, setup/
- Usage: `./setup/sync-local.sh [BASE_INSTALL_PATH]`

### Merge Strategy & PR Approach
- Use git merge strategy to integrate upstream v1.4.1
- Resolve conflicts by preserving custom setup scripts temporarily
- Maintain git history for both upstream and custom changes
- Two-PR approach:
  - **PR 1**: Merge upstream + extension architecture + sandbox migration
  - **PR 2**: Hooks + PEER migration (dependent on PR 1)
- Both PRs created together, merged only when both are ready

### Repository File Structure

```
agent-os/                        # This repository (development)
├── extensions/                  # Extension management files
│   ├── sandbox/                # Global extension
│   │   ├── install.sh         # Installs to ~/.claude-code-sandbox/
│   │   ├── launcher.sh        # Claude Code sandbox launcher script
│   │   └── profiles/          # Sandbox profiles
│   │       └── claude-code-sandbox.sb
│   ├── hooks/                  # Hooks extension (references claude-code/hooks/)
│   │   └── install.sh         # Copies claude-code/hooks/ to ~/.claude/hooks/
│   └── peer/                   # PEER extension
│       ├── install.sh         # Sets up PEER scripts in .agent-os/scripts/peer/
│       └── scripts/           # PEER bash scripts (moved from scripts/peer/)
├── claude-code/                 # Claude Code specific files
│   ├── hooks/                  # Hook files (remain here, agent-specific)
│   │   ├── pre_*.py
│   │   ├── post_*.py
│   │   └── stop.py
│   └── agents/                  # Agent templates
├── setup/                       # Setup scripts
│   ├── base.sh                 # Upstream script (minimal changes)
│   ├── project.sh              # Upstream script (minimal changes)
│   ├── functions.sh            # Upstream script (minimal changes)
│   ├── base-extensions.sh     # Custom extension handler for base
│   ├── project-extensions.sh  # Custom extension handler for projects
│   └── sync-local.sh           # Local development helper
├── instructions/                # Agent OS instructions
├── standards/                   # Development standards
├── commands/                    # Command templates
├── config.yml                   # Base configuration template
└── .agent-os/                   # Agent OS working directory (DO NOT MODIFY)
    └── specs/                   # Specifications only
```

### Two-Tier Extension Architecture

#### Global Extensions (installed to ~/.agent-os/)
- **Sandbox**: Security-critical, system-wide installation
- Cannot be disabled per-project
- Final installation location: `~/.claude-code-sandbox/`
- Source location: `extensions/sandbox/` in this repo
- Copied to: `~/.agent-os/extensions/sandbox/` during base installation
- Each extension has its own `install.sh` script
- Install script supports overrides:
  - `SANDBOX_INSTALL_DIR="${SANDBOX_INSTALL_DIR:-$HOME/.claude-code-sandbox}"`
  - `BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"` for symlink location
- Creates symlink: `~/.local/bin/claude-code-sandbox` → `~/.claude-code-sandbox/launcher.sh`

#### Project Extensions (installed to .agent-os/)
- **Hooks**: References existing claude-code/hooks/ files
  - Source files remain in: `claude-code/hooks/` (agent-specific code)
  - Extension config in: `extensions/hooks/` (install.sh only)
  - Final installation: `~/.claude/hooks/` (global for all projects)
- **PEER**: Project-specific with base defaults
  - Source location: `extensions/peer/` with scripts moved from `scripts/peer/`
  - Installation: `.agent-os/scripts/peer/` per project
- Can be enabled/disabled per-project via `.agent-os.yaml`

### Configuration Hierarchy
- **Base config.yml** (in ~/.agent-os/): System defaults copied from repo during base installation
- **Project config: `.agent-os.yaml`** (in project root): Project-specific overrides
  - Located in project root directory, NOT in .agent-os/ working directory
  - Avoids conflicts with Agent OS working directory
  - Created by project-extensions.sh during project setup
- Environment variable overrides for runtime values

### Minimizing Upstream Changes Strategy

To minimize merge conflicts with future upstream updates, extension functionality will be isolated in separate scripts that are called by upstream scripts with minimal modifications.

#### Upstream Scripts (from upstream Agent OS)
These scripts should receive minimal modifications:
- `setup/base.sh` - Base installation script
- `setup/project.sh` - Project installation script  
- `setup/functions.sh` - Shared functions library

#### Extension Scripts (custom to this fork)
New scripts that contain all extension logic:
- `setup/base-extensions.sh` - Handles global extension installation
  - Called by base.sh after core installation
  - Copies extensions to ~/.agent-os/extensions/
  - Runs sandbox extension installer
  - Updates base config.yml with extension defaults
  
- `setup/project-extensions.sh` - Handles project extension installation
  - Called by project.sh after core project setup
  - Copies extensions to .agent-os/extensions/
  - Creates `.agent-os.yaml` in project root
  - Runs hooks and PEER extension installers
  
- `setup/sync-local.sh` - Local development helper
  - Standalone script for development
  - Not called by upstream scripts

#### Upstream Modification Pattern
Each upstream script receives only minimal additions:
```bash
# In base.sh, after core installation:
if [ -f "$SCRIPT_DIR/base-extensions.sh" ]; then
    source "$SCRIPT_DIR/base-extensions.sh"
fi

# In project.sh, after core project setup:
if [ -f "$SCRIPT_DIR/project-extensions.sh" ]; then
    source "$SCRIPT_DIR/project-extensions.sh"
fi
```

This pattern ensures:
- Upstream changes can be merged with minimal conflicts
- Extension logic remains isolated and maintainable
- Easy to disable extensions by removing the extension scripts
- Clear separation between upstream and custom code

#### Base Configuration Structure
```yaml
agent_os_version: 1.4.1
agents:
  claude_code:
    enabled: true
  cursor:
    enabled: false

extensions:
  sandbox:
    enabled: true
    required: true        # Cannot be disabled
    profile: "claude-code-sandbox.sb"
  hooks:
    enabled: true         # Default for projects
    source_dir: "claude-code/hooks"  # Location of hook files
    install_dir: "~/.claude/hooks"   # Installation target
  peer:
    enabled: true         # Default for projects
    nats_url: "nats://localhost:4222"
    project_buckets: true # Per-project KV buckets
```

#### Extension Naming Convention
- Extension directory name MUST match config key (e.g., `extensions/hooks/` → `extensions.hooks`)
- Or config can specify `directory` field to override:
  ```yaml
  extensions:
    my_custom_hook:
      directory: "hooks"  # Uses extensions/hooks/ directory
      enabled: true
  ```

#### Project Configuration Override (.agent-os.yaml)
```yaml
# Located in project root directory (NOT in .agent-os/)
# Projects can override extension settings
extensions:
  hooks:
    enabled: false        # Disable hooks for this project
  peer:
    nats_url: "nats://custom:4222"  # Override NATS URL
    bucket_prefix: "myproject"      # Project-specific KV bucket
```

### Path Migration Strategy
- **Global paths remain**: ~/.agent-os/ for system-wide components
- **Project paths updated**: ~/.agent-os/ → .agent-os/ for project-local
- **PEER scripts**: Move to .agent-os/scripts/peer/ per project
- **No symlinks**: Direct path updates only

Files requiring updates:
- Custom instruction files referencing ~/.agent-os/instructions/
- PEER pattern scripts referencing ~/.agent-os/scripts/peer/
- Command reference files
- Hook installation paths (if any)

### Extension Installation Process

#### Phase 1: Base Installation (base.sh + base-extensions.sh)
1. `base.sh` runs core Agent OS installation
2. `base.sh` checks for and sources `base-extensions.sh` if present
3. `base-extensions.sh` performs:
   - Copies `extensions/sandbox/` to `~/.agent-os/extensions/sandbox/`
   - Runs `~/.agent-os/extensions/sandbox/install.sh` to install to `~/.claude-code-sandbox/`
   - Updates `~/.agent-os/config.yml` with extension defaults
4. `sandbox/install.sh` performs:
   - Copies `launcher.sh` to `~/.claude-code-sandbox/launcher.sh`
   - Copies `profiles/claude-code-sandbox.sb` to `~/.claude-code-sandbox/`
   - Makes launcher executable
   - Creates symlink in `~/.local/bin/claude-code-sandbox`
   - Optionally creates README.md for user reference

#### Phase 2: Project Installation (project.sh + project-extensions.sh)
1. `project.sh` runs core project setup
2. `project.sh` checks for and sources `project-extensions.sh` if present
3. `project-extensions.sh` performs:
   - Copies `extensions/hooks/` to `.agent-os/extensions/hooks/` (install.sh only)
   - Copies `extensions/peer/` to `.agent-os/extensions/peer/` (includes scripts)
   - Creates `.agent-os.yaml` in project root with extension configuration
   - Runs `.agent-os/extensions/hooks/install.sh` which:
     - Reads config to find source_dir (claude-code/hooks/)
     - Copies hook files from source to ~/.claude/hooks/
   - Runs `.agent-os/extensions/peer/install.sh` to set up PEER scripts

#### Extension Loader Pattern
Each extension's `install.sh` script:
- Loads configuration hierarchy (base config.yml → .agent-os.yaml → env vars)
- Checks if extension is enabled
- Validates prerequisites
- Performs installation to final target location
- Logs results to installation.log
- Returns appropriate exit codes (0=success, 1=error)

Configuration loading in install.sh:
```bash
# Load base config
BASE_CONFIG="$HOME/.agent-os/config.yml"
# Load project config if exists
PROJECT_CONFIG=".agent-os.yaml"
# Check enabled status from configs and env vars
```

##### Future Enhancement: loader.sh
- Potential future requirement for centralized extension loading utilities
- Would provide shared functions for configuration hierarchy loading
- Could standardize extension enablement checking across all extensions

### Hooks Integration
- Remain unified system (all TTS providers, CCAOS included)
- Install globally to ~/.claude/hooks/ (maintain Claude Code compatibility)
- No project-specific hooks for now
- Configuration through extension config, not separation

### Error Handling & Notifications
- Extension installation creates installation.log
- Failed extensions log warnings, continue installation
- Required extensions (sandbox) fail installation on error
- No rollback mechanism - notification and retry capability

### Testing Requirements
Priority order validation:
1. **Sandbox extension installation process** (Priority 1)
   - Test the sandbox extension installation process, not the security isolation itself
   - Verify base.sh downloads and calls base-extensions.sh correctly
   - Verify base-extensions.sh copies sandbox extension to ~/.agent-os/extensions/
   - Verify sandbox install.sh executes and creates ~/.claude-code-sandbox/
   - Verify launcher.sh is copied to ~/.claude-code-sandbox/launcher.sh
   - Verify profile is copied to ~/.claude-code-sandbox/claude-code-sandbox.sb
   - Verify symlink created at ~/.local/bin/claude-code-sandbox
   - Test SANDBOX_INSTALL_DIR environment variable override
   - Test BIN_DIR environment variable override for symlink location
2. **Hooks extension installation process** (Priority 2)
   - Test the hooks extension installation process, not the hook functionality itself
   - Verify project.sh downloads and calls project-extensions.sh correctly
   - Verify project-extensions.sh copies hooks extension to .agent-os/extensions/
   - Verify hooks install.sh executes and references claude-code/hooks/ correctly
   - Verify hooks are copied to ~/.claude/hooks/
   - Test configuration in .agent-os.yaml
3. **PEER extension installation process** (Priority 3)
   - Test the PEER extension installation process, not the PEER pattern execution itself
   - Verify PEER extension copies to .agent-os/extensions/
   - Verify PEER install.sh executes correctly
   - Verify scripts are installed to .agent-os/scripts/peer/
   - Test path references are updated correctly

Test scenarios:
- Clean base installation with extension loading
- Project installation with extensions
- Extension enable/disable via config (respecting 'required' flag)
- Path resolution after migration
- Configuration override behavior
- Error handling for failed extensions (especially required ones)
- BASE_URL override with fork
- Local sync-local.sh functionality
- Extension install.sh environment variable overrides
- Installation logging and error reporting

### Implementation Phases

#### Phase 1: Foundation (PR 1)
1. Execute upstream merge preserving custom scripts
2. Add BASE_URL override to all setup scripts
3. Create extension directory structure
4. Move sandbox profile to extensions/sandbox/profiles/
5. Create base-extensions.sh and stub project-extensions.sh
6. Implement sandbox extension with install.sh
7. Update base config.yml with extension defaults

#### Phase 2: Migration (PR 2)
1. Implement full project-extensions.sh
2. Create hooks extension referencing claude-code/hooks/
3. Move PEER scripts to extensions/peer/scripts/
4. Implement PEER extension with install.sh
5. Create .agent-os.yaml template and generation
6. Update all path references for project-local components
7. Test hooks and PEER functionality
8. Remove deprecated setup scripts
9. Create MIGRATION.md documentation

### Legacy Script Deprecation
- Keep setup.sh, setup-claude-code.sh, setup-cursor.sh during migration
- Refactor them to use extension system
- Delete them after successful validation
- Update documentation to reference new installation methods

## External Dependencies

**No new external dependencies required** - this is a refactoring and migration project using existing tools and libraries.