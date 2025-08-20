🔍 Clarifications & Recommendations

  2.1 Extension Loading Strategy

  Let me clarify the three approaches:

  Option A - Auto-load if present: Extensions in setup/extensions/ automatically load during installation/runtime if the directory exists.

  Option B - Config.yml controlled: Each extension has an enabled flag in config.yml:
  extensions:
    hooks:
      enabled: true
    peer:
      enabled: false  # Can disable even if files exist
    sandbox:
      enabled: true

  Option C - Command-line: During installation, specify which extensions to activate:
  ./setup/project.sh --extensions=hooks,sandbox

  Recommendation: Config.yml approach (Option B) - provides persistent per-project control with ability to enable/disable features as needed.

  RESPONSE: OPTION B is good. But it would be good to have a base config similar to how agent os is now setup. This would allow configuring a base set of extensions with defaults allowing each project to override. The base installation should also allow for specific extensions to not be disabled. In this case is the sandbox considered an extension? If so, then some extensions would be global such as the sandbox.

  2.2 Hooks Structure Suggestion

  Based on your current implementation, I suggest:
  extensions/hooks/
  ├── install.sh           # Main installer
  ├── core/               # Core hook files
  │   ├── pre_*.py
  │   ├── post_*.py
  │   └── stop.py
  ├── features/           # Optional features
  │   ├── gemini_tts.sh   # Gemini TTS setup
  │   └── ccaos_env.sh    # CCAOS environment setup
  └── config.sh           # Hook configuration

  RESPONSE: I might be missing something but why are you trying to split gemini and ccaos for the hooks. These are now part of the implementation. Based on this suggestion, how is gemini and different from the other tts implementations?

  3.2 Symlinks Explanation

  Symlinks would mean creating links from old paths to new ones:
  ~/.agent-os/scripts/peer/ -> .agent-os/scripts/peer/
  This allows old references to work temporarily. Based on your "no" answer, we'll do direct path updates instead.

  7.2 Merge Strategy Recommendation

  Given priorities (Sandbox → Hooks → PEER), I recommend:

  Incremental Merge Approach:
  1. Phase 1: Merge upstream + basic extension structure + sandbox (Priority 1)
  2. Phase 2: Migrate hooks system (Priority 2)
  3. Phase 3: Migrate PEER pattern (Priority 3)
  4. Phase 4: Cleanup and remove old scripts

  Each phase can be a separate PR to main, allowing testing between phases.

  Should one be a single phase as is or make the sandbox a separate PR? Pro is that we have some initial feedback on whether the extension works. Con is that we might be doing too much in a single PR. A middle ground would be to split it into 2 phases and create 2 PRs one dependent on the other, and both are only merged once we have both ready.

  8.1 Rollback Mechanism

  For Claude Code context, rollback would mean:
  - If an extension fails during installation, the installer continues but logs the failure
  - Creates an installation.log with status of each extension
  - User can re-run specific extension installers manually

  Example implementation:
  # In extension loader
  for extension in $ENABLED_EXTENSIONS; do
      if ! ./extensions/$extension/install.sh; then
          echo "WARNING: Extension $extension failed to install" >> installation.log
          if [ "$extension" = "required" ]; then
              echo "ERROR: Required extension failed. Aborting."
              exit 1
          fi
      fi
  done

  RESPONSE: Makes sense. But is this actually a rollback or a notification.

  10.1 Hooks Installation Recommendation

  Given the new Agent OS structure and your responses:

  Hybrid Approach:
  - Global hooks (~/.claude/hooks/): Core functionality that applies to all projects
  - Project hooks (.claude/hooks/): Project-specific overrides or additions
  - Detection mechanism: Check for updates via version file or hash comparison

  RESPONSE: What would be global hooks and what would be project specific hooks? Currently this is how claude hooks work. Currently the hooks I have are not project specific.

  📝 Should I update the spec with these refinements?

  Based on your answers and these clarifications, I should update the spec to include:

  1. Config.yml controlled extension loading with per-project enable/disable
  2. Incremental merge strategy with 4 phases based on priorities
  3. Direct path updates (no symlinks)
  4. NATS configuration in config.yml with env var override
  5. Sandbox stays global in home directory
  6. Extension error handling with required flag support
  7. Hybrid hooks approach for global/project balance
  8. Per-project NATS KV buckets
  9. MIGRATION.md documentation
  10. Delete old setup scripts as final task
