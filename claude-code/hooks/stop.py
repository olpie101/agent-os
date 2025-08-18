#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pyttsx3==2.90",
#     "python-dotenv",
# ]
# ///

import argparse
import json
import os
import sys
import random
import subprocess
from pathlib import Path
from datetime import datetime

try:
    from dotenv import load_dotenv
    # Load dotenv from custom path if specified
    env_file = os.getenv("CCAOS_ENV_FILE")
    if env_file:
        load_dotenv(dotenv_path=env_file)
    else:
        load_dotenv()
except ImportError:
    pass  # dotenv is optional


def get_completion_messages():
    """Return list of friendly completion messages."""
    return [
        "Work complete!",
        "All done!",
        "Task finished!",
        "Job complete!",
        "Ready for next task!"
    ]


def get_tts_script_path():
    """
    Determine which TTS script to use based on available API keys.
    Priority order: Gemini > OpenAI > pyttsx3
    """
    # Get current script directory and construct utils/tts path
    script_dir = Path(__file__).parent
    tts_dir = script_dir / "utils" / "tts"
    
    # Check for Gemini API key (highest priority)
    if os.getenv('GOOGLE_API_KEY'):
        gemini_script = tts_dir / "gemini_tts.py"
        if gemini_script.exists():
            return str(gemini_script)
    
    # Check for OpenAI API key (second priority)
    if os.getenv('OPENAI_API_KEY'):
        openai_script = tts_dir / "openai_tts.py"
        if openai_script.exists():
            return str(openai_script)
    
    # Fall back to pyttsx3 (no API key required)
    pyttsx3_script = tts_dir / "pyttsx3_tts.py"
    if pyttsx3_script.exists():
        return str(pyttsx3_script)
    
    return None


def get_llm_script_path():
    """
    Determine which LLM script to use based on available API keys.
    Priority order: Gemini > OpenAI > Anthropic
    """
    # Get current script directory and construct utils/llm path
    script_dir = Path(__file__).parent
    llm_dir = script_dir / "utils" / "llm"
    
    # Check for Gemini API keys (highest priority)
    if os.getenv('GOOGLE_API_KEY') or os.getenv('GEMINI_API_KEY'):
        gemini_script = llm_dir / "gemini.py"
        if gemini_script.exists():
            return str(gemini_script)
    
    # Check for OpenAI API key (second priority)
    if os.getenv('OPENAI_API_KEY'):
        openai_script = llm_dir / "oai.py"
        if openai_script.exists():
            return str(openai_script)
    
    # Check for Anthropic API key (third priority)
    if os.getenv('ANTHROPIC_API_KEY'):
        anth_script = llm_dir / "anth.py"
        if anth_script.exists():
            return str(anth_script)
    
    return None


def get_llm_completion_message():
    """
    Generate completion message using available LLM services.
    Priority order: Gemini > OpenAI > Anthropic > fallback to random message
    
    Returns:
        str: Generated or fallback completion message
    """
    llm_script = get_llm_script_path()
    
    if llm_script:
        try:
            result = subprocess.run([
                "uv", "run", llm_script, "--completion"
            ], 
            capture_output=True,
            text=True,
            timeout=10
            )
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, subprocess.SubprocessError):
            pass
    
    # Fallback to random predefined message
    messages = get_completion_messages()
    return random.choice(messages)

def announce_completion():
    """Announce completion using the best available TTS service."""
    try:
        tts_script = get_tts_script_path()
        if not tts_script:
            return  # No TTS scripts available
        
        # Get completion message (LLM-generated or fallback)
        completion_message = get_llm_completion_message()
        
        # Call the TTS script with the completion message
        subprocess.run([
            "uv", "run", tts_script, completion_message
        ])
    except Exception:
        pass  # Silently fail if TTS doesn't work


def log_stop_event(session_id):
    """Log the stop event."""
    # Ensure logs directory exists
    log_dir = Path("logs")
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / 'stop.json'
    
    # Read existing log data or initialize empty list
    if log_file.exists():
        with open(log_file, 'r') as f:
            try:
                log_data = json.load(f)
            except (json.JSONDecodeError, ValueError):
                log_data = []
    else:
        log_data = []
    
    # Append new event
    log_data.append({
        'session_id': session_id,
        'timestamp': datetime.now().isoformat()
    })
    
    # Write back to file with formatting
    with open(log_file, 'w') as f:
        json.dump(log_data, f, indent=2)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--announce', action='store_true',
                      help='Announce completion via TTS')
    args = parser.parse_args()
    
    try:
        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())
        
        # Extract session_id
        session_id = input_data.get('session_id', 'unknown')
        
        # Log the stop event
        log_stop_event(session_id)
        
        # Announce completion if requested
        if args.announce:
            announce_completion()
        
        # Exit successfully
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Handle JSON decode errors gracefully
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)


if __name__ == '__main__':
    main()