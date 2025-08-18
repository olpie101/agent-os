# Claude-Hooks Spec Refinement Log

> Refinement Date: 2025-08-17
> PEER Cycle: 3
> Refinement Type: Critical corrections based on comprehensive codebase analysis

## Critical Corrections Applied

### 1. Gemini API Reference Usage Correction
**Original Issue:** Risk of copying scripts/tts/gemini.py as a template
**Correction Applied:**
- Explicitly documented that scripts/tts/gemini.py is API reference only
- Technical spec specifies "Use scripts/tts/gemini.py as API reference only (not template)"
- Implementation must follow existing TTS patterns from openai_tts.py and pyttsx3_tts.py
- New gemini_tts.py must match UV script structure, CLI interface, and error handling patterns

### 2. OpenAI TTS Retention Correction
**Original Issue:** Risk of removing OpenAI TTS when updating priority
**Correction Applied:**
- Spec scope explicitly states "Maintained Fallback Support" for existing OpenAI users
- Out of scope section clarifies "Changes to existing OpenAI TTS implementation" are excluded
- Priority updated from "ElevenLabs > OpenAI > pyttsx3" to "Gemini > OpenAI > pyttsx3"
- Technical spec emphasizes "Preserve existing OpenAI and pyttsx3 fallback logic"

### 3. Priority Order Specification
**Original Issue:** Incomplete priority specification missing OpenAI retention
**Correction Applied:**
- Updated to explicit "Gemini > OpenAI > pyttsx3" throughout all documentation
- ElevenLabs deprioritized but not removed (kept for backward compatibility)
- Hook integration updates target exact files and line numbers for get_tts_script_path()
- Implementation pattern specified: "Add Gemini check before existing OpenAI check"

### 4. Comprehensive Testing Strategy Addition
**Original Issue:** Missing specific testing strategy with practical examples
**Correction Applied:**
- Added detailed testing strategy section in technical-spec.md
- Included specific test case examples with function signatures and assertions
- Covered unit tests, integration tests, fallback tests, environment tests, and regression tests
- Tasks.md includes comprehensive testing as major task with detailed subtasks

### 5. Existing Pattern Compliance
**Original Issue:** Risk of not following established TTS script patterns
**Correction Applied:**
- Technical spec mandates UV script header compliance
- CLI interface must match existing sys.argv argument handling
- Error handling must use silent failure patterns from existing scripts
- Audio playback implementation must avoid file saving (direct playback only)

## Codebase Analysis Results

### TTS Script Patterns Identified
- **UV Header Pattern:** `#!/usr/bin/env -S uv run --script` with dependency block
- **CLI Interface:** Text input via `sys.argv` with default fallback messages
- **Environment Checks:** API key validation with user-friendly error messages
- **Error Handling:** Silent failures with multiple exception types to avoid workflow disruption
- **Status Output:** Emoji-based status indicators for user feedback

### Hook Integration Patterns Identified
- **Selection Functions:** get_tts_script_path() in stop.py, notification.py, subagent_stop.py
- **Priority Logic:** Environment variable checks determine provider priority order
- **Subprocess Calls:** "uv run [script] [text]" pattern with 10-second timeouts
- **Silent Failures:** All TTS failures handled gracefully without user interruption

### Current Implementation Status
- **File Locations:** TTS scripts in claude-code/hooks/utils/tts/
- **Existing Scripts:** openai_tts.py, pyttsx3_tts.py, elevenlabs_tts.py all following consistent patterns
- **Hook Files:** Three hook files implement identical get_tts_script_path() logic
- **Current Priority:** ElevenLabs > OpenAI > pyttsx3 (to be updated to Gemini > OpenAI > pyttsx3)

## Files Created/Modified in Refinement

### New Spec Structure Created
- `.agent-os/specs/2025-08-17-claude-hooks/spec.md` - Main specification with corrected scope
- `.agent-os/specs/2025-08-17-claude-hooks/spec-lite.md` - Condensed specification
- `.agent-os/specs/2025-08-17-claude-hooks/sub-specs/technical-spec.md` - Technical implementation details
- `.agent-os/specs/2025-08-17-claude-hooks/tasks.md` - Implementation task breakdown
- `.agent-os/specs/2025-08-17-claude-hooks/refinement-log.md` - This refinement documentation

### Implementation Files to be Created/Modified
- **New:** `claude-code/hooks/utils/tts/gemini_tts.py` - Following existing TTS patterns
- **Update:** `claude-code/hooks/stop.py` - get_tts_script_path() function
- **Update:** `claude-code/hooks/notification.py` - get_tts_script_path() function  
- **Update:** `claude-code/hooks/subagent_stop.py` - get_tts_script_path() function

## Quality Assurance Measures

### Pattern Compliance Verification
- ✅ gemini_tts.py structure must match openai_tts.py and pyttsx3_tts.py patterns
- ✅ UV script headers and dependency blocks required
- ✅ CLI interface consistency across all TTS scripts
- ✅ Silent failure error handling patterns maintained

### Backward Compatibility Assurance
- ✅ Existing OpenAI TTS functionality preserved
- ✅ pyttsx3 fallback functionality maintained
- ✅ ElevenLabs script kept (deprioritized but not removed)
- ✅ Existing environment variable configurations work unchanged

### Testing Coverage Requirements
- ✅ Unit tests for new gemini_tts.py script
- ✅ Integration tests for priority logic updates
- ✅ Fallback tests for API unavailability scenarios
- ✅ Regression tests for existing TTS functionality
- ✅ Environment combination tests for all API key scenarios

## Refinement Success Criteria

1. **Scope Accuracy:** Spec reflects actual codebase patterns and constraints
2. **Implementation Clarity:** Technical specifications provide clear, actionable guidance
3. **Backward Compatibility:** Existing TTS functionality explicitly preserved
4. **Testing Completeness:** Comprehensive test strategy with specific examples
5. **Pattern Consistency:** New implementation follows established TTS script patterns

## Next Steps

1. Review refined specification for accuracy and completeness
2. Proceed with implementation following task breakdown in tasks.md
3. Execute comprehensive testing strategy as outlined
4. Validate against all critical corrections listed above

## Post-Execution Refinement (2025-08-17)

### UV Script Header Requirement for Tests
**Issue Identified:** Test files created during execution lacked UV script headers
**Correction Applied:**
- Updated technical-spec.md to specify all test files must include UV script headers
- Added "Test File Requirements" section with example UV header for test files
- Modified tasks.md to explicitly note "(with UV script headers)" for all test-related tasks
- Test files must be self-contained executable scripts with dependencies declared

**UV Header Template for Tests:**
```python
#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "pytest>=7.0.0",
#   "pytest-mock",
#   "python-dotenv",
# ]
# ///
```

This ensures test files can be executed with `uv run` and have access to required testing dependencies.

## Installation Script Requirements (2025-08-18)

### Hook Files Installation Requirement
**Issue Identified:** setup-claude-code.sh needs to install hooks to user's ~/.claude/hooks directory
**Correction Applied:**
- Script must copy claude-code/hooks files to ~/.claude/hooks (excluding test files)
- Test files (test*.py) in any subdirectory must be excluded from installation
- Instructions directory (instructions/reminder.md) must be included
- All Python scripts and utilities must be preserved with directory structure

### Settings Configuration Merge Requirement
**Issue Identified:** Hooks configuration needs to be merged into ~/.claude/settings.json
**Correction Applied:**
- Script must use jq to merge hooks configuration from settings_hooks.json
- Merge operation must preserve existing settings while adding hooks key
- JQ command pattern validated: `jq -s '.[0] * {"hooks": .[1].hooks}' settings.json settings_hooks.json`
- Must handle case where settings.json doesn't exist (create with defaults)

**Files to Copy:**
```
claude-code/hooks/
├── notification.py
├── post_tool_use.py
├── pre_compact.py
├── pre_tool_use.py
├── session_start.py
├── stop.py
├── subagent_stop.py
├── user_prompt_submit.py
├── instructions/
│   └── reminder.md
└── utils/
    ├── llm/
    │   ├── anth.py
    │   ├── gemini.py
    │   └── oai.py
    └── tts/
        ├── elevenlabs_tts.py
        ├── gemini_tts.py
        ├── openai_tts.py
        └── pyttsx3_tts.py
```

**Files to Exclude:**
- All test*.py files in any directory
- test_hook_integration.py, test_llm_priority.py in tests/
- test_gemini.py, test_llm_integration.py in utils/llm/
- test_gemini_tts.py, test_tts_integration.py in utils/tts/

## Installation Script Flag Requirements (2025-08-18)

### New Flags for Controlled Installation
**Issue Identified:** Installation script needs explicit control over hook files and settings updates
**Correction Applied:**
- Added `--overwrite-hooks` flag to control hook file overwrites (default: false)
- Added `--update-settings` flag to control settings.json modifications (default: false)
- Both flags default to false for safety and user control

### Flag Behavior Specifications

#### --overwrite-hooks Flag
- **Default:** false (preserve existing hook files)
- **Purpose:** Control whether existing files in ~/.claude/hooks/ are overwritten
- **Behavior when false:** Skip installation of hook files that already exist
- **Behavior when true:** Overwrite all hook files with fresh copies
- **Similar to:** --overwrite-commands and --overwrite-agents flags

#### --update-settings Flag
- **Default:** false (do not modify settings.json)
- **Purpose:** Control whether ~/.claude/settings.json is modified
- **Behavior when false:** 
  - Skip all settings.json modifications
  - Display message about manual configuration needed
  - Provide path to settings_hooks.json for reference
- **Behavior when true:**
  - Check for jq availability
  - Backup existing settings.json if it exists
  - Create new settings.json if none exists
  - Merge/override hooks field from settings_hooks.json
  - Preserve all other fields in settings.json
- **Safety:** Requires explicit opt-in to prevent unexpected settings changes

### Installation Scenarios

1. **Fresh Installation (no existing files)**
   ```bash
   ./setup-claude-code.sh --local --update-settings
   ```
   - Installs all hooks
   - Creates and configures settings.json

2. **Update Hooks Only (preserve settings)**
   ```bash
   ./setup-claude-code.sh --local --overwrite-hooks
   ```
   - Updates hook files
   - Leaves settings.json unchanged

3. **Update Settings Only (preserve hooks)**
   ```bash
   ./setup-claude-code.sh --local --update-settings
   ```
   - Skips existing hook files
   - Updates settings.json hooks configuration

4. **Full Update (overwrite everything)**
   ```bash
   ./setup-claude-code.sh --local --overwrite-hooks --update-settings
   ```
   - Overwrites all hook files
   - Updates settings.json configuration

## Environment File Loading Fix (2025-08-18)

### Custom .env File Path Support
**Issue Identified:** Hooks load .env from execution directory (~/.claude/hooks/) instead of project directory
**Correction Applied:**
- All hook files updated to check for `CCAOS_ENV_FILE` environment variable
- If `CCAOS_ENV_FILE` is set, use it as the path for `load_dotenv(dotenv_path=...)`
- If not set, fall back to default `load_dotenv()` behavior
- claude-code-sandbox-launcher.sh updated to require and set `CCAOS_ENV_FILE`
- Default location: `~/.config/.ccaos/.env` (must exist, can be empty)

### Implementation Pattern
```python
import os
from dotenv import load_dotenv

# Load dotenv from custom path if specified
env_file = os.getenv("CCAOS_ENV_FILE")
if env_file:
    load_dotenv(dotenv_path=env_file)
else:
    load_dotenv()
```

### Files Requiring Update
**Hook Files:**
- claude-code/hooks/stop.py
- claude-code/hooks/notification.py
- claude-code/hooks/subagent_stop.py
- claude-code/hooks/user_prompt_submit.py
- claude-code/hooks/session_start.py
- claude-code/hooks/pre_compact.py

**LLM Utilities:**
- claude-code/hooks/utils/llm/anth.py
- claude-code/hooks/utils/llm/gemini.py
- claude-code/hooks/utils/llm/oai.py

**TTS Utilities:**
- claude-code/hooks/utils/tts/elevenlabs_tts.py
- claude-code/hooks/utils/tts/gemini_tts.py
- claude-code/hooks/utils/tts/openai_tts.py

**Launcher Script:**
- claude-code-sandbox-launcher.sh - Updated to set and export `CCAOS_ENV_FILE`

### User Requirements
- Users can set `export CCAOS_ENV_FILE=/path/to/project/.env` in their shell
- The sandbox launcher creates default file at `~/.config/.ccaos/.env` if not exists
- This ensures hooks load environment variables from the correct project context
