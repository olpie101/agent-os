# Spec Tasks

## Tasks

- [x] 1. Create Gemini TTS Script Implementation
  - [x] 1.1 Write tests for gemini_tts.py script functionality (with UV script headers)
  - [x] 1.2 Create gemini_tts.py following existing TTS script patterns (UV header, dependencies, CLI interface)
  - [x] 1.3 Implement GOOGLE_API_KEY environment variable check with proper error messages
  - [x] 1.4 Add Gemini API integration using scripts/tts/gemini.py as reference only
  - [x] 1.5 Implement direct audio playback without file saving
  - [x] 1.6 Add error handling with silent failure patterns matching existing scripts
  - [x] 1.7 Verify gemini_tts.py tests pass (tests written but not executed per user constraint)

- [x] 2. Update Hook Integration for Priority Logic
  - [x] 2.1 Write tests for updated get_tts_script_path() functions (with UV script headers)
  - [x] 2.2 Update get_tts_script_path() in claude-code/hooks/stop.py (add Gemini check before OpenAI)
  - [x] 2.3 Update get_tts_script_path() in claude-code/hooks/notification.py
  - [x] 2.4 Update get_tts_script_path() in claude-code/hooks/subagent_stop.py
  - [x] 2.5 Ensure priority order: Gemini > OpenAI > pyttsx3 (keep OpenAI, deprioritize ElevenLabs)
  - [x] 2.6 Verify hook integration tests pass (tests written but not executed per user constraint)

- [x] 3. Comprehensive Testing and Validation
  - [x] 3.1 Write integration tests for TTS priority logic with different API key combinations (with UV script headers)
  - [x] 3.2 Create fallback tests to ensure graceful degradation when APIs are unavailable (with UV script headers)
  - [x] 3.3 Add regression tests to verify existing OpenAI and pyttsx3 functionality remains intact (with UV script headers)
  - [x] 3.4 Test CLI interface consistency across all TTS scripts (with UV script headers)
  - [x] 3.5 Verify all tests pass (tests written but not executed per user constraint)

- [x] 4. Create Gemini LLM Script Implementation
  - [x] 4.1 Write tests for gemini.py script functionality (with UV script headers including google-genai dependency)
  - [x] 4.2 Create gemini.py in claude-code/hooks/utils/llm/ following anth.py and oai.py patterns exactly
  - [x] 4.3 Implement prompt_llm() function with identical signature and behavior as existing LLM scripts
  - [x] 4.4 Implement generate_completion_message() function with ENGINEER_NAME personalization matching existing patterns
  - [x] 4.5 Add CLI interface with --completion flag support and direct prompt testing
  - [x] 4.6 Implement GOOGLE_API_KEY environment variable authentication with fallback to GEMINI_API_KEY
  - [x] 4.7 Add google-genai API integration using gemini-2.0-flash-001 model with temperature=0.7 and max_tokens=100
  - [x] 4.8 Implement error handling with silent failure patterns (return None on exceptions)
  - [x] 4.9 Add response cleaning logic (strip quotes, take first line) matching existing LLM scripts
  - [x] 4.10 Verify gemini.py tests pass and interface compliance with anth.py/oai.py (tests written but not executed per user constraint)

- [x] 5. LLM Integration Testing and Validation
  - [x] 5.1 Write unit tests for prompt_llm() function with various input scenarios (with UV script headers)
  - [x] 5.2 Write unit tests for generate_completion_message() with and without ENGINEER_NAME (with UV script headers)
  - [x] 5.3 Write CLI interface tests for --completion flag and direct prompting (with UV script headers)
  - [x] 5.4 Write error handling tests for missing API keys and API failures (with UV script headers)
  - [x] 5.5 Write interface compliance tests comparing gemini.py outputs with anth.py/oai.py patterns (with UV script headers)
  - [x] 5.6 Add integration tests for google-genai package functionality (with UV script headers)
  - [x] 5.7 Verify all LLM tests pass and gemini.py provides identical interface to existing LLM scripts (tests written but not executed per user constraint)

- [x] 6. Implement LLM Priority Order in Hooks
  - [x] 6.1 Create get_llm_script_path() function in relevant hook files
  - [x] 6.2 Implement priority logic: Gemini > OpenAI > Anthropic
  - [x] 6.3 Check GOOGLE_API_KEY and GEMINI_API_KEY for Gemini selection
  - [x] 6.4 Fall back to OPENAI_API_KEY for OpenAI selection
  - [x] 6.5 Fall back to ANTHROPIC_API_KEY for Anthropic selection
  - [x] 6.6 Update hooks that use LLM functionality to use get_llm_script_path()
  - [x] 6.7 Write tests for LLM priority selection logic (with UV script headers)
  - [x] 6.8 Verify priority order works correctly in all API key combinations (tests written but not executed per user constraint)

- [x] 7. Update Installation Script for Hook Deployment
  - [x] 7.1 Add hooks directory copying to setup-claude-code.sh (excluding test files)
  - [x] 7.2 Implement rsync or find command to exclude test*.py files during copy
  - [x] 7.3 Preserve directory structure (utils/llm/, utils/tts/, instructions/)
  - [x] 7.4 Add jq dependency check and installation guidance
  - [x] 7.5 Implement settings.json merge using jq to add hooks configuration
  - [x] 7.6 Handle case where ~/.claude/settings.json doesn't exist (create with defaults)
  - [x] 7.7 Backup existing settings.json before modification
  - [x] 7.8 Add --overwrite-hooks flag to control hook file overwrites (default: false)
  - [x] 7.9 Add --update-settings flag to control settings.json updates (default: false)
  - [x] 7.10 Update help message with new flags documentation
  - [x] 7.11 Implement conditional logic for hook installation based on --overwrite-hooks flag
  - [x] 7.12 Implement conditional logic for settings update based on --update-settings flag
  - [ ] 7.13 Test installation process with various flag combinations

- [ ] 8. Fix Environment File Loading in Hooks
  - [ ] 8.1 Update claude-code/hooks/stop.py to check CCAOS_ENV_FILE environment variable
  - [ ] 8.2 Update claude-code/hooks/notification.py with custom env file support
  - [ ] 8.3 Update claude-code/hooks/subagent_stop.py with custom env file support
  - [ ] 8.4 Update claude-code/hooks/user_prompt_submit.py with custom env file support
  - [ ] 8.5 Update claude-code/hooks/session_start.py with custom env file support
  - [ ] 8.6 Update claude-code/hooks/pre_compact.py with custom env file support
  - [ ] 8.7 Update claude-code/hooks/utils/llm/anth.py with custom env file support
  - [ ] 8.8 Update claude-code/hooks/utils/llm/gemini.py with custom env file support
  - [ ] 8.9 Update claude-code/hooks/utils/llm/oai.py with custom env file support
  - [ ] 8.10 Update claude-code/hooks/utils/tts/elevenlabs_tts.py with custom env file support
  - [ ] 8.11 Update claude-code/hooks/utils/tts/gemini_tts.py with custom env file support
  - [ ] 8.12 Update claude-code/hooks/utils/tts/openai_tts.py with custom env file support
  - [ ] 8.13 Update claude-code-sandbox-launcher.sh to set CCAOS_ENV_FILE with default location
  - [ ] 8.14 Ensure sandbox launcher creates default .env file at ~/.config/.ccaos/.env if not exists
  - [ ] 8.15 Test environment file loading with various CCAOS_ENV_FILE paths