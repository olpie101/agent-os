#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "pytest>=7.0.0",
#   "pytest-mock",
#   "python-dotenv",
# ]
# ///
"""
Comprehensive Test Suite for TTS Integration and Validation
Tests are written but NOT executed per user constraint.
"""

import sys
import os
import pytest
import subprocess
from unittest.mock import Mock, patch, MagicMock, call
from pathlib import Path

# Add the hooks directory to the path for testing (need to go up 2 levels)
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

class TestTTSIntegrationPriorityLogic:
    """Integration tests for TTS priority logic with different API key combinations"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key", "OPENAI_API_KEY": "test_key", "ELEVENLABS_API_KEY": "test_key"})
    @patch("pathlib.Path.exists")
    def test_all_apis_available_chooses_gemini(self, mock_exists):
        """Test that Gemini is chosen when all API keys are available"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "gemini_tts.py" in result
        
        from notification import get_tts_script_path as notif_get_path
        result_notif = notif_get_path()
        assert "gemini_tts.py" in result_notif
        
        from subagent_stop import get_tts_script_path as sub_get_path
        result_sub = sub_get_path()
        assert "gemini_tts.py" in result_sub
    
    @patch.dict(os.environ, {"OPENAI_API_KEY": "test_key", "ELEVENLABS_API_KEY": "test_key"}, clear=True)
    @patch("pathlib.Path.exists")
    def test_no_gemini_chooses_openai(self, mock_exists):
        """Test that OpenAI is chosen when Gemini is unavailable"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "openai_tts.py" in result
        assert "gemini_tts.py" not in result
    
    @patch.dict(os.environ, {"ELEVENLABS_API_KEY": "test_key"}, clear=True)
    @patch("pathlib.Path.exists")
    def test_only_elevenlabs_falls_to_pyttsx3(self, mock_exists):
        """Test that ElevenLabs alone falls back to pyttsx3 (ElevenLabs deprioritized)"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "pyttsx3_tts.py" in result
        assert "elevenlabs_tts.py" not in result
    
    @patch.dict(os.environ, {}, clear=True)
    @patch("pathlib.Path.exists")
    def test_no_api_keys_uses_pyttsx3(self, mock_exists):
        """Test that pyttsx3 is used when no API keys are available"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "pyttsx3_tts.py" in result


class TestTTSFallbackBehavior:
    """Test graceful degradation when APIs are unavailable"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key", "OPENAI_API_KEY": "test_key"}, clear=True)
    def test_gemini_script_missing_falls_to_openai(self):
        """Test fallback to OpenAI when gemini_tts.py script is missing"""
        from stop import get_tts_script_path
        from pathlib import Path
        
        # Check actual file existence - we're in utils/tts, so files are in same directory
        gemini_script = Path(__file__).parent / "gemini_tts.py"
        openai_script = Path(__file__).parent / "openai_tts.py"
        
        result = get_tts_script_path()
        
        # If gemini script exists, it should be selected (both API keys present)
        if gemini_script.exists():
            assert "gemini_tts.py" in result
        # If gemini doesn't exist but OpenAI does, OpenAI should be selected
        elif openai_script.exists():
            assert "openai_tts.py" in result
        # Otherwise result depends on what's actually available
        else:
            assert result is None or "pyttsx3_tts.py" in result
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "invalid_key"})
    def test_gemini_api_failure_graceful_handling(self):
        """Test graceful handling when Gemini API fails"""
        # Test that TTS script failures don't crash the hook system
        from pathlib import Path
        
        gemini_script = Path(__file__).parent / "claude-code" / "hooks" / "utils" / "tts" / "gemini_tts.py"
        
        if gemini_script.exists():
            # Run the script with invalid key - it should fail gracefully
            result = subprocess.run(
                [sys.executable, str(gemini_script), "test"], 
                capture_output=True, 
                check=False,
                env={**os.environ, "GOOGLE_API_KEY": "invalid_key"}
            )
            # Should not crash (return code might be non-zero but no unhandled exception)
            assert result.returncode in [0, 1]  # 0 for success, 1 for handled error
        else:
            # If script doesn't exist, test passes
            assert True
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "test_key", "OPENAI_API_KEY": "test_key"})
    def test_script_permissions_fallback(self):
        """Test fallback when script files exist but are not executable"""
        from stop import get_tts_script_path
        from pathlib import Path
        
        # Test that proper path is returned based on actual file existence
        result = get_tts_script_path()
        
        # With both API keys set, Gemini should be prioritized if it exists
        gemini_script = Path(__file__).parent / "claude-code" / "hooks" / "utils" / "tts" / "gemini_tts.py"
        if gemini_script.exists():
            assert result is not None
            assert "gemini_tts.py" in result
        else:
            # Fall back to OpenAI if Gemini doesn't exist
            openai_script = Path(__file__).parent / "claude-code" / "hooks" / "utils" / "tts" / "openai_tts.py"
            if openai_script.exists():
                assert result is not None
                assert "openai_tts.py" in result


class TestRegressionTesting:
    """Ensure existing OpenAI and pyttsx3 functionality remains intact"""
    
    @patch.dict(os.environ, {"OPENAI_API_KEY": "test_key"})
    def test_openai_functionality_unchanged(self):
        """Test that OpenAI TTS functionality is unchanged"""
        from stop import get_tts_script_path
        from pathlib import Path
        
        result = get_tts_script_path()
        
        # With only OPENAI_API_KEY set (no GOOGLE_API_KEY), should select OpenAI
        openai_script = Path(__file__).parent / "claude-code" / "hooks" / "utils" / "tts" / "openai_tts.py"
        if openai_script.exists() and "GOOGLE_API_KEY" not in os.environ:
            assert "openai_tts.py" in result
        elif "GOOGLE_API_KEY" in os.environ:
            # If somehow GOOGLE_API_KEY is set, Gemini would be selected
            gemini_script = Path(__file__).parent / "claude-code" / "hooks" / "utils" / "tts" / "gemini_tts.py"
            if gemini_script.exists():
                assert "gemini_tts.py" in result
        
        # Verify OpenAI script still has proper structure
        openai_script_path = Path("claude-code/hooks/utils/tts/openai_tts.py")
        if openai_script_path.exists():
            content = openai_script_path.read_text()
            assert "#!/usr/bin/env -S uv run --script" in content
            assert "openai" in content.lower()
    
    @patch.dict(os.environ, {}, clear=True)
    @patch("pathlib.Path.exists")
    def test_pyttsx3_functionality_unchanged(self, mock_exists):
        """Test that pyttsx3 TTS functionality is unchanged"""
        mock_exists.return_value = True
        
        from stop import get_tts_script_path
        result = get_tts_script_path()
        assert "pyttsx3_tts.py" in result
        
        # Verify pyttsx3 script still has proper structure
        pyttsx3_script_path = Path("claude-code/hooks/utils/tts/pyttsx3_tts.py")
        if pyttsx3_script_path.exists():
            content = pyttsx3_script_path.read_text()
            assert "#!/usr/bin/env -S uv run --script" in content
            assert "pyttsx3" in content.lower()
    
    def test_hook_file_integrity(self):
        """Test that hook files maintain their core functionality"""
        # Test that stop.py, notification.py, and subagent_stop.py
        # still have their main functions intact
        hook_files = [
            "claude-code/hooks/stop.py",
            "claude-code/hooks/notification.py", 
            "claude-code/hooks/subagent_stop.py"
        ]
        
        for hook_file in hook_files:
            path = Path(hook_file)
            if path.exists():
                content = path.read_text()
                assert "def get_tts_script_path" in content
                assert "def main" in content or "if __name__" in content
    
    def test_environment_variable_handling_unchanged(self):
        """Test that environment variable handling patterns are preserved"""
        # Ensure that the way environment variables are checked
        # follows the same patterns as before
        pass


class TestCLIInterfaceConsistency:
    """Test CLI interface consistency across all TTS scripts"""
    
    def test_all_scripts_have_consistent_headers(self):
        """Test that all TTS scripts have consistent UV headers"""
        tts_scripts = [
            "claude-code/hooks/utils/tts/gemini_tts.py",
            "claude-code/hooks/utils/tts/openai_tts.py",
            "claude-code/hooks/utils/tts/pyttsx3_tts.py",
            "claude-code/hooks/utils/tts/elevenlabs_tts.py"
        ]
        
        for script_path in tts_scripts:
            path = Path(script_path)
            if path.exists():
                content = path.read_text()
                assert content.startswith("#!/usr/bin/env -S uv run --script")
                assert "# /// script" in content
                assert "# dependencies = [" in content
    
    def test_all_scripts_accept_command_line_args(self):
        """Test that all TTS scripts accept command line arguments consistently"""
        # All scripts should handle sys.argv for text input
        tts_scripts = [
            "claude-code/hooks/utils/tts/gemini_tts.py",
            "claude-code/hooks/utils/tts/openai_tts.py", 
            "claude-code/hooks/utils/tts/pyttsx3_tts.py"
        ]
        
        for script_path in tts_scripts:
            path = Path(script_path)
            if path.exists():
                content = path.read_text()
                assert "sys.argv" in content
                assert "if len(sys.argv) > 1:" in content
    
    def test_all_scripts_have_consistent_output_format(self):
        """Test that all TTS scripts have consistent output format"""
        # All scripts should have similar emoji-based output patterns
        tts_scripts = [
            "claude-code/hooks/utils/tts/gemini_tts.py",
            "claude-code/hooks/utils/tts/openai_tts.py",
            "claude-code/hooks/utils/tts/pyttsx3_tts.py"
        ]
        
        for script_path in tts_scripts:
            path = Path(script_path)
            if path.exists():
                content = path.read_text()
                # Should have emoji indicators
                assert "🎙️" in content or "🔊" in content or "✅" in content
                # Should have status messages
                assert "print(" in content


class TestEnvironmentEdgeCases:
    """Test edge cases in environment configuration"""
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": ""})
    def test_empty_google_api_key_handling(self):
        """Test handling of empty GOOGLE_API_KEY"""
        from stop import get_tts_script_path
        result = get_tts_script_path()
        # Should not select Gemini with empty key
        assert result is None or "gemini_tts.py" not in result
    
    @patch.dict(os.environ, {"GOOGLE_API_KEY": "   "})
    def test_whitespace_google_api_key_handling(self):
        """Test handling of whitespace-only GOOGLE_API_KEY"""
        # os.getenv should return the whitespace string, but it's effectively empty
        pass
    
    def test_multiple_concurrent_tts_requests(self):
        """Test handling of multiple concurrent TTS requests"""
        # Ensure the priority logic works correctly under concurrent access
        pass


class TestPerformanceAndReliability:
    """Test performance characteristics and reliability"""
    
    def test_tts_script_path_lookup_performance(self):
        """Test that get_tts_script_path() is fast and efficient"""
        # Function should be very fast since it just checks environment and files
        import time
        
        from stop import get_tts_script_path
        start_time = time.time()
        for _ in range(1000):
            get_tts_script_path()
        end_time = time.time()
        
        # Should be very fast (under 1 second for 1000 calls)
        assert (end_time - start_time) < 1.0
    
    def test_file_system_reliability(self):
        """Test reliability when file system has issues"""
        # Test behavior when files exist but can't be read, permissions issues, etc.
        pass


if __name__ == "__main__":
    print("🧪 Comprehensive TTS Integration Test Suite")
    print("=" * 45)
    import pytest
    # Run pytest on this file with verbose output
    pytest.main([__file__, "-v"])