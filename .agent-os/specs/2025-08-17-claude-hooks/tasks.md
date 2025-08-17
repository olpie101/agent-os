# Spec Tasks

## Tasks

- [x] 1. Create Gemini TTS Script Implementation
  - [x] 1.1 Write tests for gemini_tts.py script functionality
  - [x] 1.2 Create gemini_tts.py following existing TTS script patterns (UV header, dependencies, CLI interface)
  - [x] 1.3 Implement GOOGLE_API_KEY environment variable check with proper error messages
  - [x] 1.4 Add Gemini API integration using scripts/tts/gemini.py as reference only
  - [x] 1.5 Implement direct audio playback without file saving
  - [x] 1.6 Add error handling with silent failure patterns matching existing scripts
  - [x] 1.7 Verify gemini_tts.py tests pass (tests written but not executed per user constraint)

- [x] 2. Update Hook Integration for Priority Logic
  - [x] 2.1 Write tests for updated get_tts_script_path() functions
  - [x] 2.2 Update get_tts_script_path() in claude-code/hooks/stop.py (add Gemini check before OpenAI)
  - [x] 2.3 Update get_tts_script_path() in claude-code/hooks/notification.py
  - [x] 2.4 Update get_tts_script_path() in claude-code/hooks/subagent_stop.py
  - [x] 2.5 Ensure priority order: Gemini > OpenAI > pyttsx3 (keep OpenAI, deprioritize ElevenLabs)
  - [x] 2.6 Verify hook integration tests pass (tests written but not executed per user constraint)

- [x] 3. Comprehensive Testing and Validation
  - [x] 3.1 Write integration tests for TTS priority logic with different API key combinations
  - [x] 3.2 Create fallback tests to ensure graceful degradation when APIs are unavailable
  - [x] 3.3 Add regression tests to verify existing OpenAI and pyttsx3 functionality remains intact
  - [x] 3.4 Test CLI interface consistency across all TTS scripts
  - [x] 3.5 Verify all tests pass (tests written but not executed per user constraint)