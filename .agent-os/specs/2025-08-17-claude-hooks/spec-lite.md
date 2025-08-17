# Spec Summary (Lite)

Add Gemini TTS support to Claude Code hooks system as the primary TTS provider while maintaining existing OpenAI TTS functionality. The implementation will create a new gemini_tts.py script following existing TTS patterns, update hook priority logic to Gemini > OpenAI > pyttsx3, and ensure seamless fallback behavior for users with existing configurations.