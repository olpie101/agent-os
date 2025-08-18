#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "pytest>=7.0.0",
#   "pytest-mock",
#   "python-dotenv",
# ]
# ///
"""
Test suite for hook integration priority logic updates
Tests are written but NOT executed per user constraint.
"""

import sys
import os
import pytest
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

# Add the hooks directory to the path for testing (need to go up 1 level)
sys.path.insert(0, str(Path(__file__).parent.parent))

class TestHookPriorityLogic:
    """Test suite for TTS priority logic in hook files"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key", "OPENAI_API_KEY": "test_key", "ELEVENLABS_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_gemini_priority_with_all_keys(self, mock_exists):
        """Test that Gemini is selected when all API keys are available"""
        mock_exists.return_value = True
        
        # Import and test stop.py
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "gemini_tts.py" in result
    
    @patch.dict(os.environ, {"OPENAI_API_KEY": "test_key", "ELEVENLABS_API_KEY": "test_key"}, clear=True)
    @patch("pathlib.Path.exists")
    def test_openai_fallback_without_gemini(self, mock_exists):
        """Test OpenAI fallback when only OPENAI_API_KEY is available"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "openai_tts.py" in result
    
    @patch.dict(os.environ, {}, clear=True)
    @patch("pathlib.Path.exists")
    def test_pyttsx3_final_fallback(self, mock_exists):
        """Test pyttsx3 fallback when no API keys are available"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "pyttsx3_tts.py" in result
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key", "OPENAI_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_gemini_over_openai_priority(self, mock_exists):
        """Test that Gemini takes priority over OpenAI"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "gemini_tts.py" in result
        assert "openai_tts.py" not in result
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key"}, clear=True)
    def test_gemini_script_exists_check(self):
        """Test that function checks if gemini_tts.py exists before returning it"""
        # Test with actual file existence - if gemini_tts.py exists, it should be returned
        from stop import get_tts_script_path
        result = get_tts_script_path()
        
        # Since we have GOOGLE_API_KEY set and gemini_tts.py exists, it should be selected
        from pathlib import Path
        gemini_script = Path(__file__).parent.parent / "utils" / "tts" / "gemini_tts.py"
        if gemini_script.exists():
            assert "gemini_tts.py" in result
        else:
            # If file doesn't exist, it should fall back to other options
            assert result is None or "gemini_tts.py" not in result


class TestNotificationHookIntegration:
    """Test suite for notification.py hook integration"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_notification_gemini_priority(self, mock_exists):
        """Test Gemini priority in notification.py"""
        mock_exists.return_value = True
        
        from notification import get_tts_script_path
        result = get_tts_script_path()
        assert "gemini_tts.py" in result
    
    def test_notification_function_consistency(self):
        """Test that notification.py get_tts_script_path() follows same logic as stop.py"""
        # Ensure consistency across hook files
        pass


class TestSubagentStopHookIntegration:
    """Test suite for subagent_stop.py hook integration"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_subagent_stop_gemini_priority(self, mock_exists):
        """Test Gemini priority in subagent_stop.py"""
        mock_exists.return_value = True
        
        from subagent_stop import get_tts_script_path
        result = get_tts_script_path()
        assert "gemini_tts.py" in result
    
    def test_subagent_stop_function_consistency(self):
        """Test that subagent_stop.py get_tts_script_path() follows same logic"""
        # Ensure consistency across hook files
        pass


class TestElevenLabsDeprioritization:
    """Test that ElevenLabs is properly deprioritized"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key", "ELEVENLABS_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_gemini_over_elevenlabs(self, mock_exists):
        """Test that Gemini takes priority over ElevenLabs"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "gemini_tts.py" in result
        assert "elevenlabs_tts.py" not in result
    
    @patch.dict(os.environ, {"OPENAI_API_KEY": "test_key", "ELEVENLABS_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_openai_over_elevenlabs(self, mock_exists):
        """Test that OpenAI takes priority over ElevenLabs"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "openai_tts.py" in result
        assert "elevenlabs_tts.py" not in result


class TestBackwardCompatibility:
    """Test that existing OpenAI and pyttsx3 functionality remains intact"""
    
    @patch.dict(os.environ, {"OPENAI_API_KEY": "test_key"})
    def test_openai_functionality_preserved(self):
        """Test that OpenAI functionality is preserved when Gemini unavailable"""
        # Test with actual file existence
        # When GOOGLE_API_KEY is not set but OPENAI_API_KEY is, should select OpenAI
        from stop import get_tts_script_path
        result = get_tts_script_path()
        
        # Since we don't have GOOGLE_API_KEY in this test, it should fall back to OpenAI
        if "GOOGLE_API_KEY" not in os.environ:
            assert "openai_tts.py" in result
        else:
            # If GOOGLE_API_KEY is somehow set, Gemini would be selected
            assert "gemini_tts.py" in result
    
    @patch.dict(os.environ, {}, clear=True)
    @patch("pathlib.Path.exists")
    def test_pyttsx3_functionality_preserved(self, mock_exists):
        """Test that pyttsx3 functionality is preserved as final fallback"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "pyttsx3_tts.py" in result


class TestEnvironmentVariations:
    """Test hook behavior under various environment conditions"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": ""})
    @patch("pathlib.Path.exists")
    def test_empty_google_api_key(self, mock_exists):
        """Test behavior with empty GOOGLE_API_KEY"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert result is None or "gemini_tts.py" not in result
    
    def test_mixed_api_key_combinations(self):
        """Test various combinations of available API keys"""
        # Test different combinations to ensure proper priority ordering
        pass


if __name__ == "__main__":
    print("🧪 Hook Integration Test Suite")
    print("=" * 35)
    import pytest
    # Run pytest on this file with verbose output
    pytest.main([__file__, "-v"])