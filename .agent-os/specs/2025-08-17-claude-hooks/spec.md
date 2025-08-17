# Spec Requirements Document

> Spec: claude-hooks
> Created: 2025-08-17

## Overview

Add Gemini TTS support to Claude Code hooks system while maintaining existing OpenAI TTS functionality. This enhancement will provide users with a new high-quality TTS option while preserving the current fallback hierarchy and improving overall TTS availability.

## User Stories

### Enhanced TTS Options

As a Claude Code user, I want access to Gemini TTS as the primary TTS provider, so that I can have high-quality voice feedback when my API key is available.

**Detailed Workflow:**
- User configures GOOGLE_API_KEY in environment variables
- Claude Code hooks automatically detect Gemini TTS availability
- System prioritizes Gemini > OpenAI > pyttsx3 for TTS operations
- User receives consistent TTS feedback during completion events

### Maintained Fallback Support

As a Claude Code user, I want to keep my existing OpenAI TTS setup working, so that my current configuration continues to function seamlessly.

**Detailed Workflow:**
- User with existing OPENAI_API_KEY continues to receive TTS
- System gracefully falls back to OpenAI when Gemini is unavailable
- pyttsx3 remains as offline fallback option
- No disruption to existing TTS functionality

## Spec Scope

1. **Gemini TTS Implementation** - Create new gemini_tts.py following existing TTS script patterns
2. **Hook Integration** - Update get_tts_script_path() functions to include Gemini in priority order
3. **Priority Logic Update** - Change from ElevenLabs > OpenAI > pyttsx3 to Gemini > OpenAI > pyttsx3
4. **Pattern Consistency** - Ensure gemini_tts.py matches structure and interface of existing TTS scripts
5. **Testing Strategy** - Include comprehensive test coverage for new TTS integration

## Out of Scope

- Removal of pyttsx3 fallback functionality
- Changes to existing OpenAI TTS implementation
- Modifications to ElevenLabs script (will be deprioritized, not removed)
- Changes to TTS script interface or command-line argument structure
- Audio format or quality modifications to existing scripts

## Expected Deliverable

1. **Functional Gemini TTS Integration** - Users can use Gemini TTS by setting GOOGLE_API_KEY
2. **Preserved OpenAI Support** - Existing OpenAI TTS functionality remains unchanged
3. **Updated Priority Logic** - Hook functions correctly prioritize Gemini > OpenAI > pyttsx3
4. **Comprehensive Tests** - All TTS functionality covered by automated test suite