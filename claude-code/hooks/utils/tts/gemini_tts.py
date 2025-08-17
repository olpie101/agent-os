#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "google-genai",
#     "python-dotenv",
# ]
# ///

import os
import sys
import io
import wave
import subprocess
from pathlib import Path
from dotenv import load_dotenv


def play_audio_data(audio_data):
    """Play audio data directly using system audio player"""
    try:
        # Try to use afplay on macOS
        if sys.platform == "darwin":
            process = subprocess.Popen(
                ["afplay", "-"],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            process.communicate(input=audio_data)
            return True
        
        # Try to use aplay on Linux
        elif sys.platform.startswith("linux"):
            process = subprocess.Popen(
                ["aplay", "-"],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            process.communicate(input=audio_data)
            return True
        
        # Fallback: create temporary file and play
        else:
            import tempfile
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
                tmp_file.write(audio_data)
                tmp_path = tmp_file.name
            
            try:
                if sys.platform == "win32":
                    os.system(f'start "" "{tmp_path}"')
                else:
                    subprocess.run(["open", tmp_path], check=False)
                return True
            finally:
                # Clean up temporary file after a delay
                try:
                    os.unlink(tmp_path)
                except:
                    pass
    except Exception:
        return False


def create_wave_data(pcm_data, channels=1, rate=24000, sample_width=2):
    """Convert PCM data to WAV format for playback"""
    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(sample_width)
        wf.setframerate(rate)
        wf.writeframes(pcm_data)
    return buffer.getvalue()


def main():
    """
    Gemini TTS Script

    Uses Google's Gemini AI for high-quality text-to-speech.
    Accepts optional text prompt as command-line argument.

    Usage:
    - ./gemini_tts.py                    # Uses default text
    - ./gemini_tts.py "Your custom text" # Uses provided text

    Features:
    - Gemini 2.5 Flash TTS model (latest)
    - Kore voice (natural and clear)
    - Direct audio playback without file saving
    - Environment variable configuration
    """

    # Load environment variables
    load_dotenv()

    # Get API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("❌ Error: GOOGLE_API_KEY not found in environment variables")
        print("Please add your Google API key to .env file:")
        print("GOOGLE_API_KEY=your_api_key_here")
        sys.exit(1)

    try:
        from google import genai
        from google.genai import types

        # Initialize Gemini client
        client = genai.Client(api_key=api_key)

        print("🎙️  Gemini TTS")
        print("=" * 15)

        # Get text from command line argument or use default
        if len(sys.argv) > 1:
            text = " ".join(sys.argv[1:])  # Join all arguments as text
        else:
            text = "Today is a wonderful day to build something people love!"

        print(f"🎯 Text: {text}")
        print("🔊 Generating and playing...")

        try:
            # Generate audio using Gemini TTS
            response = client.models.generate_content(
                model="gemini-2.5-flash-preview-tts",
                contents=f"Say cheerfully: {text}",
                config=types.GenerateContentConfig(
                    response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(
                        voice_config=types.VoiceConfig(
                            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                voice_name='Kore',
                            )
                        )
                    ),
                )
            )

            # Extract audio data
            audio_data = response.candidates[0].content.parts[0].inline_data.data
            
            # Convert to WAV format for better compatibility
            wav_data = create_wave_data(audio_data)
            
            # Play audio directly
            if play_audio_data(wav_data):
                print("✅ Playback complete!")
            else:
                print("⚠️  Audio generated but playback unavailable")

        except Exception as e:
            print(f"❌ Error: {e}")

    except ImportError as e:
        print("❌ Error: Required package not installed")
        print("This script uses UV to auto-install dependencies.")
        print("Make sure UV is installed: https://docs.astral.sh/uv/")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()