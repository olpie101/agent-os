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
│   │   ├── install.py         # Installs to ~/.claude-code-sandbox/
│   │   ├── launcher.sh        # Claude Code sandbox launcher script
│   │   ├── sandbox-audit-logger.sh  # Audit logging functionality
│   │   ├── sandbox-audit-rotate.sh  # Log rotation management
│   │   ├── extension.yaml     # Extension metadata and config schema
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
2. `base.sh` loads and sources `config-loader.sh` which:
   - Exports configuration functions (`get_config_value`, `validate_required_extensions`)
   - Makes these functions available to all subsequent scripts via `export -f`
3. `base.sh` calls `base-extensions.sh` with command-line arguments (not sourced)
4. `base-extensions.sh` delegates to Python extension manager (`manage_extensions.py`) which:
   - Uses `ConfigManager` to load and merge configuration hierarchy
   - Uses `ExtensionManager` to process enabled extensions
   - Validates extension metadata from `extension.yaml` files
   - Calls `extension_installer.py` for each extension
5. For each enabled extension, `extension_installer.py`:
   - Validates configuration against the extension's schema
   - Copies extension directory to `~/.agent-os/extensions/[name]/`
   - Copies `claude-code/hooks/` to `~/.agent-os/claude-code/hooks/` (if hooks enabled)
   - Runs extension's `install.py` script with standardized arguments
6. `sandbox/install.py` performs:
   - Copies `launcher.sh` to `~/.claude-code-sandbox/launcher.sh`
   - Copies `profiles/claude-code-sandbox.sb` to `~/.claude-code-sandbox/`
   - Copies `sandbox-audit-logger.sh` to `~/.claude-code-sandbox/`
   - Copies `sandbox-audit-rotate.sh` to `~/.claude-code-sandbox/`
   - Makes all scripts executable
   - Creates symlink in `~/.local/bin/claude-code-sandbox`
   - Creates configuration file with installation metadata

#### Phase 2: Project Installation (project.sh + project-extensions.sh)
1. `project.sh` runs core project setup
2. `project.sh` checks for and sources `project-extensions.sh` if present
3. `project-extensions.sh` performs:
   - Copies `extensions/hooks/` to `.agent-os/extensions/hooks/` (install.sh only)
   - Copies `extensions/peer/` to `.agent-os/extensions/peer/` (includes scripts)
   - Creates `.agent-os.yaml` in project root with extension configuration
   - Runs `.agent-os/extensions/hooks/install.sh` which:
     - Reads configuration for source directory (defaults to ~/.agent-os/claude-code/hooks/)
     - Copies hook files from base installation to target directory (configurable via HOOKS_TARGET_DIR, defaults to ~/.claude/hooks/)
     - Updates ~/.claude/settings.json to register the hooks with proper paths
   - Runs `.agent-os/extensions/peer/install.sh` to set up PEER scripts

#### Configuration Propagation Pattern
**CRITICAL**: Configuration must flow through the installation process:

1. **base.sh loads config-loader.sh**:
   - Sources the script and calls `apply_config_hierarchy`
   - Functions are exported via `export -f` making them available to child processes
   
2. **base-extensions.sh MUST use configuration**:
   - MUST check each extension's enabled status using `get_config_value`
   - MUST NOT hardcode which extensions to install
   - MUST respect configuration from config.yml and environment variables
   - Example: `enabled=$(get_config_value "EXTENSIONS_SANDBOX_ENABLED" "true")`

3. **project-extensions.sh MUST use configuration**:
   - MUST check each extension's enabled status
   - MUST respect .agent-os.yaml overrides
   - MUST use same pattern as base-extensions.sh

4. **Extension install.sh scripts MAY use configuration**:
   - CAN use `get_config_value` if config-loader.sh functions are available
   - CAN read environment variables directly for overrides
   - SHOULD check their own enabled status as a safety check

#### Extension Loader Pattern
Each extension's `install.sh` script:
- MAY load configuration if needed (functions should be available from parent)
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
- Base installation includes claude-code/hooks directory with default hooks
- Hooks copied to base installation directory (~/.agent-os/claude-code/hooks/)
- Install globally to ~/.claude/hooks/ (maintain Claude Code compatibility)
- Update ~/.claude/settings.json to register hooks using jq
- Extension metadata defined in `extension.yaml` with config schema
- Python-based installer (`install.py`) handles all installation logic
- Configuration through extension config schema:
  - `enabled`: Whether the extension is enabled
  - `required`: Whether the extension is required
  - `install_dir`: Installation directory for Claude Code (defaults to ~/.claude)
  - `source_dir`: Source directory for hook files
  - `auto_update`: Automatically update hooks when source changes
  - `update_settings`: Update settings.json with hooks configuration
- Support environment variables for testing (passed through config):
  - HOOKS_SOURCE_DIR: Override source directory (defaults to ~/.agent-os/claude-code/hooks)
  - HOOKS_TARGET_DIR: Override target directory (defaults to ~/.claude/hooks)
  - CLAUDE_SETTINGS_PATH: Override settings.json path (defaults to ~/.claude/settings.json)

### Extension Script Architecture

#### Python-Based Extension Management
Extension management has been refactored to use Python for better reliability, maintainability, and cross-platform compatibility.

**Architecture Components**:
1. **Shell Wrappers** (base-extensions.sh, project-extensions.sh):
   - Minimal bash scripts that validate arguments and delegate to Python
   - Accept command-line arguments and pass them to Python scripts
   - Handle basic error checking and usage display

2. **Python Extension Manager** (manage_extensions.py):
   - Main entry point for extension management
   - Uses ConfigManager to handle configuration hierarchy
   - Uses ExtensionManager to process extensions
   - Validates extension metadata and configuration

3. **Extension Installer** (extension_installer.py):
   - Validates extension configuration against schema
   - Copies extension files to appropriate locations
   - Executes extension-specific install.py scripts
   - Handles error reporting and logging

4. **Extension Metadata** (extension.yaml):
   - Defines extension metadata (name, version, description)
   - Specifies configuration schema for validation
   - Declares dependencies (Python packages, system requirements)
   - Indicates extension type (global, project, or both)

**base-extensions.sh** accepts:
```bash
bash base-extensions.sh \
    --install-dir="/path/to/install" \
    --base-dir="/path/to/repo" \
    --script-dir="/path/to/scripts" \
    --config-file="/path/to/config.yml"
```

**project-extensions.sh** accepts:
```bash
bash project-extensions.sh \
    --project-dir="/path/to/project" \
    --base-install-dir="/path/to/base/.agent-os" \
    --script-dir="/path/to/scripts" \
    --config-file="/path/to/config.yml"
```

**Extension install.py** receives standardized arguments:
```bash
./install.py \
    --mode=<global|project> \
    --source-dir="/path/to/extension" \
    --extension-name="<name>" \
    --install-dir="/path/to/target" \
    --project-dir="/path/to/project" \
    --config-<key>=<value> ...
```

**Benefits**:
- Cross-platform compatibility (Python handles path resolution)
- Better error handling and validation
- Structured configuration management
- Schema-based configuration validation
- Consistent installation interface across extensions

### Extension Metadata Structure (extension.yaml)

Each extension MUST include an `extension.yaml` file that defines:

```yaml
# Extension metadata
name: <extension-name>
version: <semantic-version>
description: <brief-description>
author: <author-name>
license: <license-type>

# Extension type
type: <global|project|both>

# Configuration schema
config_schema:
  <config-key>:
    type: <boolean|string|number>
    default: <default-value>
    required: <true|false>
    description: <config-description>

# Dependencies (optional)
dependencies:
  python:
    - <package-name>
  system:
    - <system-requirement>
```

### Error Handling & Notifications
- Extension installation creates installation.log
- Failed extensions log warnings, continue installation
- Required extensions (sandbox) fail installation on error
- Schema validation failures prevent extension installation
- Python installer provides detailed error messages
- No rollback mechanism - notification and retry capability

### Local Development & Testing

#### sync-local.sh Requirements
The `setup/sync-local.sh` script is for local development testing and MUST:

1. **Replicate base.sh output, NOT copy installation scripts**:
   - MUST NOT copy base.sh, base-extensions.sh, or other setup scripts to target
   - MUST directly create the final directory structure that base.sh would produce
   - MUST copy files to their final locations as base.sh would

2. **Configuration support**:
   - MUST accept optional CONFIG_FILE environment variable for custom config.yml
   - MUST load and respect configuration using config-loader.sh
   - MUST check extension enabled status before copying/installing
   - Example: `CONFIG_FILE=./test-config.yml ./setup/sync-local.sh ./tmp/test`

3. **Final output structure** (what base.sh produces):
   ```
   TARGET_DIR/.agent-os/
   ├── instructions/          # Core and meta instructions
   ├── standards/            # Development standards
   ├── commands/             # Command templates
   ├── config.yml           # Configuration (from CONFIG_FILE or default)
   ├── setup/               # Only project.sh and supporting scripts
   │   ├── project.sh
   │   ├── functions.sh
   │   ├── project-extensions.sh
   │   └── config-loader.sh
   ├── claude-code/
   │   ├── agents/          # Agent templates
   │   └── hooks/           # Hooks from repository (if enabled)
   └── extensions/          # Only enabled extensions
       ├── sandbox/         # If enabled in config
       ├── hooks/          # If enabled in config
       └── installation.log
   ```

4. **Extension handling**:
   - MUST source config-loader.sh and use get_config_value
   - MUST only copy/install extensions that are enabled
   - MUST run extension install.sh scripts for enabled extensions
   - MUST respect environment variable overrides (SANDBOX_INSTALL_DIR, etc.)

5. **What NOT to include**:
   - No base.sh or base-extensions.sh in final output
   - No sync-local.sh in final output
   - No repository structure, only installation structure

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

## Configuration Loader Enhancement

### YAML Parsing Strategy
The config-loader.sh script MUST implement a dual-mode YAML parsing strategy:

**Primary Parser - yq**:
- Check for `yq` availability using `command -v yq`
- Use `yq` to parse YAML files when available
- Extract all key-value pairs and convert to environment variables
- Handle nested structures up to 3 levels deep

**Fallback Parser - Bash**:
- Use improved bash parsing when `yq` is not available
- MUST use regex-based indentation counting:
  ```bash
  if [[ "$line" =~ ^([[:space:]]*) ]]; then
      indent_count=${#BASH_REMATCH[1]}
  fi
  ```
- MUST NOT use iterative character removal for counting indentation

**Implementation requirements**:
- parse_yaml_to_env function MUST detect yq availability
- Both parsing methods MUST produce identical environment variable output
- MUST handle standard YAML constructs needed for Agent OS configuration

## External Dependencies

**No new external dependencies required** - this is a refactoring and migration project using existing tools and libraries.