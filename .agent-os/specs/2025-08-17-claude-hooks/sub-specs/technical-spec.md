# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-17-claude-hooks/spec.md

## Technical Requirements

### New Gemini TTS Script Implementation

- **File Location:** `claude-code/hooks/utils/tts/gemini_tts.py`
- **Pattern Compliance:** Must follow existing TTS script structure (UV script header, dependency block, CLI interface)
- **Environment Variable:** Check `GOOGLE_API_KEY` for API authentication
- **Command Line Interface:** Accept text input via `sys.argv` arguments like other TTS scripts
- **Error Handling:** Silent failure patterns with graceful degradation
- **Output Format:** User feedback with emoji status indicators matching existing scripts

### Hook Integration Updates

- **Target Files:** 
  - `claude-code/hooks/stop.py` (lines 36-62: `get_tts_script_path()`)
  - `claude-code/hooks/notification.py` (similar function)
  - `claude-code/hooks/subagent_stop.py` (similar function)
- **Priority Logic:** Update from `ElevenLabs > OpenAI > pyttsx3` to `Gemini > OpenAI > pyttsx3`
- **Implementation Pattern:** Add Gemini check before existing OpenAI check
- **Backward Compatibility:** Preserve existing OpenAI and pyttsx3 fallback logic

### Gemini TTS Script Structure

- **UV Header:** `#!/usr/bin/env -S uv run --script`
- **Dependencies:** `google-genai`, `python-dotenv` in script comment block
- **API Integration:** Use scripts/tts/gemini.py as API reference only (not template)
- **Interface Consistency:** Match CLI argument handling from openai_tts.py and pyttsx3_tts.py
- **Audio Playback:** Implement direct audio playback without file saving
- **Voice Configuration:** Use appropriate Gemini voice settings for completion messages

### Testing Strategy

- **Unit Tests:** Test gemini_tts.py script independently with mock API responses
- **Integration Tests:** Test get_tts_script_path() priority logic with different environment configurations
- **Fallback Tests:** Verify graceful degradation when Gemini API is unavailable
- **Environment Tests:** Test all combinations of API key availability
- **Regression Tests:** Ensure existing OpenAI and pyttsx3 functionality remains intact

### Example Test Cases

```python
# Test priority logic
def test_gemini_priority_with_all_keys():
    """Test that Gemini is selected when all API keys are available"""
    # Mock environment with GOOGLE_API_KEY, OPENAI_API_KEY, ELEVENLABS_API_KEY
    # Assert get_tts_script_path() returns gemini_tts.py path

def test_openai_fallback_without_gemini():
    """Test OpenAI fallback when only OPENAI_API_KEY is available"""
    # Mock environment with only OPENAI_API_KEY
    # Assert get_tts_script_path() returns openai_tts.py path

def test_pyttsx3_final_fallback():
    """Test pyttsx3 fallback when no API keys are available"""
    # Mock environment with no API keys
    # Assert get_tts_script_path() returns pyttsx3_tts.py path

def test_gemini_script_cli_interface():
    """Test gemini_tts.py accepts text via command line arguments"""
    # Test script with various text inputs
    # Verify proper argument parsing and text handling
```

## External Dependencies

- **google-genai** - Google's Generative AI SDK for Gemini TTS functionality
  - **Justification:** Required for Gemini TTS API integration
  - **Version:** Latest stable version compatible with Python 3.8+

## Implementation Notes

- **Scripts/tts/gemini.py Usage:** Reference for API calls only - do NOT copy structure
- **Pattern Following:** Study openai_tts.py and pyttsx3_tts.py for proper script structure
- **Error Handling:** Match existing silent failure patterns to avoid disrupting Claude Code workflow
- **Audio Format:** Use appropriate format for direct playback (likely MP3 with local audio handling)
- **Voice Selection:** Choose appropriate Gemini voice for completion announcements