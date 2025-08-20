📋 Spec Refinement Questions

  1. Merge Strategy & Conflict Resolution

     1.1. For the three setup scripts (setup.sh, setup-claude-code.sh, setup-cursor.sh), should we:
         - Keep them as-is temporarily and deprecate them later?
         Keep them for now. The objective is to delete them by the end of this process
         - Immediately refactor them to call the new extension modules?
         Yes
         - Maintain them permanently for backward compatibility?
         No. They are to be deleted in the end

     1.2. Should we preserve the exact git history or is it acceptable to squash the merge commit?
     I will defer judgement to you. Try yo keep things as simple as possible.

  2. Extension Architecture Design

     2.1. Should extensions be:
         - Always loaded automatically if present?
         I will need more clafication for this.
         - Controlled by config.yml flags?
         Would this be on a per project basis? Do you mean that config could be changed and have features enabled and disabled as needed?
         - Loaded based on command-line arguments?
         Clarify. Would this mean on a per session basis?

     2.2. For the hooks extension specifically, should we:
         - Keep all hooks in one module?
         Depends on your answer to the follow up question below
         - Separate them by type (pre/post, tool-specific, session)?
         How would you suggest struturing this
         - Create sub-modules for Gemini TTS and CCAOS environment features?
         Gemini TTS was just an extension of the hooks. The CCAOS environment var was to facilitate the use in the sandbox.

     2.3. Should extensions have a versioning system independent of Agent OS core?
     Not for now. We can work on this later. Could be added a nice to have to the roadmap

  3. Path Migration Specifics

     3.1. For the PEER pattern instructions that reference ~/.agent-os/scripts/peer/, should these:
         - Move to .agent-os/scripts/peer/ in each project?
         Yes. Keep this in mind when updating files.
         - Stay in ~/.agent-os/ as they're system-wide utilities?
         They are currently system wide, but the 1.4.1 update to agent-os makes it so that agent os is installed in base and then installed per project. You need to fully understand how the new agent os installation process works to ensure how to best fit into it's process
         - Have a hybrid approach with some scripts local and some global?
         Let's stick to the updated agent-os installation process

     3.2. Should we maintain symlinks for backward compatibility during a transition period?
     No. But explain what this would mean so I fully understand

  4. Configuration & Feature Flags

     4.1. Should the NATS server URL for PEER pattern be:
         - Hardcoded in scripts?
         Since we are likely moving to a configuration file approach this could be part of the base configuration, overwritable by per project config.
         - Configurable in config.yml?
         Yes
         - Environment variable based?
         config overridable by env var

     4.2. For the sandbox security profiles, should they:
         - Live in the project directory?
         No. For now. It would be great to be able to extend the sandbox on a per project basis. But that is a nice to have that can be added to the roadmap.
         - Stay in the home directory for security?
         Yes
         - Be configurable per project?
         Not for now.

  5. Testing & Validation

     5.1. Should we create automated tests for:
         - Extension loading mechanism?
         Yes. But I think we need a have method for extension loading first
         - Each individual extension?
         This might get large, but would be the most ideal
         - Integration between extensions?
         Which extensions would require integration between each other.

     5.2. What's the minimum acceptable test coverage before considering the migration complete?
     ¯\_(ツ)_/¯

  6. Documentation & Communication

     6.1. Should we maintain a MIGRATION.md file documenting:
         - What changed from your custom version?
         For now. But we will likely then collate these into something else later.
         - How to use the new extension system?
         Yes.
         - Troubleshooting common issues?
         Yes

     6.2. Should extension modules have their own README files?
     Likely but we need to first flesh out this approach

  7. Priority & Phasing

     7.1. Which functionality is most critical to have working first:
         - Hooks system?
         2
         - PEER pattern?
         3
         - Sandbox security?
         1
         - All equally important?

     7.2. Should we complete all tasks before merging to main, or can we merge incrementally?
     Suggest the best approach

  8. Error Handling & Rollback

     8.1. Should we implement a rollback mechanism if an extension fails to load?
     How would this work? Keep in mind that most of this would be used within claude code and not cursor. This could likely be updated to work with other terminal based agents

     8.2. How should the system behave if a required extension is missing:
         - Fail with error?
         I guess this depends on the importance of the extension. We could possible have a "required" flag on extensions
         - Warn and continue?
         Possibility
         - Silently skip?
         Never.

  9. Future Considerations

     9.1. Should the extension architecture support:
         - Third-party extensions?
         I don't know if this approach will work yet but we can keep this in mind for our implementation
         - Extension dependencies?
         Not for now. Possibly another roadmap item. This requires clarity after initial implementation. I belive this is partly dependant on the above question.
         - Extension conflicts detection?
         Not for now.

     9.2. Should we design for eventual upstream contribution of some extensions?
     Extensions are still an experiment on my fork.

  10. Specific Functionality Questions

     10.1. The Claude hooks currently modify ~/.claude/ directly. Should they:
          - Continue modifying the global ~/.claude/?
          Possibly, refer to my response to the question below
          - Modify project-local .claude/?
          This depends on how easy it would be to update project-local installations and how easy it would be to detect updates.
          - Be configurable?
          Depends

     10.2. Should the PEER pattern's NATS KV bucket remain global or become project-specific?
      Would be good to have a per project. I am thinking that my current approach of the PEER pattern has some issues but that is to address later.

     10.3. Are there any custom features I haven't identified that need preservation?
      Not that I can think of
