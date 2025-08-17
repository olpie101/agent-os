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