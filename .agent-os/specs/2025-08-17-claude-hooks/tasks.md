# Spec Tasks

## Tasks

- [ ] 1. Create Gemini TTS Script Implementation
  - [ ] 1.1 Write tests for gemini_tts.py script functionality
  - [ ] 1.2 Create gemini_tts.py following existing TTS script patterns (UV header, dependencies, CLI interface)
  - [ ] 1.3 Implement GOOGLE_API_KEY environment variable check with proper error messages
  - [ ] 1.4 Add Gemini API integration using scripts/tts/gemini.py as reference only
  - [ ] 1.5 Implement direct audio playback without file saving
  - [ ] 1.6 Add error handling with silent failure patterns matching existing scripts
  - [ ] 1.7 Verify gemini_tts.py tests pass

- [ ] 2. Update Hook Integration for Priority Logic
  - [ ] 2.1 Write tests for updated get_tts_script_path() functions
  - [ ] 2.2 Update get_tts_script_path() in claude-code/hooks/stop.py (add Gemini check before OpenAI)
  - [ ] 2.3 Update get_tts_script_path() in claude-code/hooks/notification.py
  - [ ] 2.4 Update get_tts_script_path() in claude-code/hooks/subagent_stop.py
  - [ ] 2.5 Ensure priority order: Gemini > OpenAI > pyttsx3 (keep OpenAI, deprioritize ElevenLabs)
  - [ ] 2.6 Verify hook integration tests pass

- [ ] 3. Comprehensive Testing and Validation
  - [ ] 3.1 Write integration tests for TTS priority logic with different API key combinations
  - [ ] 3.2 Create fallback tests to ensure graceful degradation when APIs are unavailable
  - [ ] 3.3 Add regression tests to verify existing OpenAI and pyttsx3 functionality remains intact
  - [ ] 3.4 Test CLI interface consistency across all TTS scripts
  - [ ] 3.5 Verify all tests pass