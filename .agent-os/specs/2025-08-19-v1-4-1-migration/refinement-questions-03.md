1. Extension Loader Mechanism

  The spec mentions an "extension loader" but doesn't detail how extensions determine if they're enabled. Should:
  - Each extension's install.sh check the config files directly?
  I guess this might be slightly misleading when we were considering and automatic loader. Since we are using the `.agent-os.yaml` config file this could now cause confusion possibly. But this raises something in that the name of extension must either closely align with the respective directory name or the config must allow the directory to be configurable. Configurability is solely specifying the name of the directory within the extensions directory, not a path.
  - Or should base-extensions.sh and project-extensions.sh check configs and only call enabled extensions?
  This is the general approach

  2. Sandbox Profile Location

  Currently, the sandbox profile is at claude-code-sandbox.sb in the repo root. Should this:
  - Move to extensions/sandbox/profiles/claude-code-sandbox.sb?
  Yes.
  - Or stay in the root and be referenced from there?
  See above

  3. Hook Files Location

  The existing hook files (pre_*.py, post_*.py, stop.py) - where are they currently located? Should they:
  - Move from their current location to extensions/hooks/?
  Thanks for bringing this up. The current structure of the hooks directory should not change. The hooks must remain with thier current structer. Document this. But the files can move.
  - Be copied to extensions/hooks/?
  Can be moved.

  Additionally. I beleive we need a way to explicitly declare that certain hooks are agent specifc. For example, the hooks are claude specific. Upon reflection. The hooks directory can actually stay where it is. And the hooks extension will simply reference them from the claude-code directory. This keeps agent specific code together. Thoughts?

  4. PEER Scripts Location

  The PEER scripts in scripts/peer/ - should they:
  - Move to extensions/peer/scripts/?
  I think this can be moved to where you have suggested.
  - Be copied there?

  5. Configuration Loading

  For the configuration hierarchy (base → .agent-os.yaml → env vars), do the extension install.sh scripts need to:
  - Implement this loading logic themselves?
  Not sure.
  - Or will this be handled by the extension loader scripts?
  Let's start with an initial attempt with the logic in the install.sh script. as we progress if we start to see patterns we can reassess.

  6. PR Strategy

  Since we're doing two PRs, should:
  - PR 1 include a basic version of project-extensions.sh (even if empty)?
  I defer this to you. Provide rationale of you decision. Make sure it doesn't conflict with the task list
  - Or should PR 1 only have base-extensions.sh?
