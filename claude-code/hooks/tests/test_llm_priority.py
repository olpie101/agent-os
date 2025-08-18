#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "pytest",
#     "python-dotenv",
# ]
# ///

import os
import sys
import subprocess
import tempfile
import pytest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Add the hooks directory to path to import stop (need to go up 1 level)
sys.path.insert(0, str(Path(__file__).parent.parent))

import stop


class TestLLMPrioritySelection:
    """Test suite for LLM priority selection logic."""

    def test_get_llm_script_path_no_api_keys(self):
        """Test get_llm_script_path returns None when no API keys available."""
        with patch.dict(os.environ, {}, clear=True):
            result = stop.get_llm_script_path()
            assert result is None

    def test_get_llm_script_path_gemini_google_api_key_priority(self):
        """Test get_llm_script_path prioritizes Gemini with GOOGLE_API_KEY."""
        with patch.dict(os.environ, {
            'GOOGLE_API_KEY': 'test-google-key',
            'OPENAI_API_KEY': 'test-openai-key',
            'ANTHROPIC_API_KEY': 'test-anthropic-key'
        }):
            with patch('pathlib.Path.exists') as mock_exists:
                mock_exists.return_value = True
                
                result = stop.get_llm_script_path()
                
                # Should return Gemini script path
                assert result is not None
                assert 'gemini.py' in result
                assert 'utils/llm' in result

    def test_get_llm_script_path_gemini_gemini_api_key_fallback(self):
        """Test get_llm_script_path uses GEMINI_API_KEY when GOOGLE_API_KEY not available."""
        with patch.dict(os.environ, {
            'GEMINI_API_KEY': 'test-gemini-key',
            'OPENAI_API_KEY': 'test-openai-key',
            'ANTHROPIC_API_KEY': 'test-anthropic-key'
        }):
            with patch('pathlib.Path.exists') as mock_exists:
                mock_exists.return_value = True
                
                result = stop.get_llm_script_path()
                
                # Should return Gemini script path
                assert result is not None
                assert 'gemini.py' in result

    def test_get_llm_script_path_openai_second_priority(self):
        """Test get_llm_script_path falls back to OpenAI when Gemini not available."""
        with patch.dict(os.environ, {
            'OPENAI_API_KEY': 'test-openai-key',
            'ANTHROPIC_API_KEY': 'test-anthropic-key'
        }, clear=True):
            with patch('pathlib.Path.exists') as mock_exists:
                mock_exists.return_value = True
                
                result = stop.get_llm_script_path()
                
                # Should return OpenAI script path
                assert result is not None
                assert 'oai.py' in result
                assert 'utils/llm' in result

    def test_get_llm_script_path_anthropic_third_priority(self):
        """Test get_llm_script_path falls back to Anthropic when Gemini and OpenAI not available."""
        with patch.dict(os.environ, {'ANTHROPIC_API_KEY': 'test-anthropic-key'}, clear=True):
            with patch('pathlib.Path.exists') as mock_exists:
                mock_exists.return_value = True
                
                result = stop.get_llm_script_path()
                
                # Should return Anthropic script path
                assert result is not None
                assert 'anth.py' in result
                assert 'utils/llm' in result

    def test_get_llm_script_path_priority_order_with_all_keys(self):
        """Test get_llm_script_path priority: Gemini > OpenAI > Anthropic."""
        with patch.dict(os.environ, {
            'GOOGLE_API_KEY': 'test-google-key',
            'OPENAI_API_KEY': 'test-openai-key',
            'ANTHROPIC_API_KEY': 'test-anthropic-key'
        }):
            with patch('pathlib.Path.exists') as mock_exists:
                mock_exists.return_value = True
                
                result = stop.get_llm_script_path()
                
                # Should return Gemini script path (highest priority)
                assert 'gemini.py' in result

    def test_get_llm_script_path_missing_script_file(self):
        """Test get_llm_script_path returns None when script file doesn't exist."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'test-key'}):
            with patch('pathlib.Path.exists') as mock_exists:
                mock_exists.return_value = False  # Script file doesn't exist
                
                result = stop.get_llm_script_path()
                assert result is None

    def test_get_llm_script_path_fallback_through_priorities(self):
        """Test get_llm_script_path falls through priorities when scripts missing."""
        with patch.dict(os.environ, {
            'GOOGLE_API_KEY': 'test-google-key',
            'OPENAI_API_KEY': 'test-openai-key',
            'ANTHROPIC_API_KEY': 'test-anthropic-key'
        }, clear=True):
            # Create a mock that returns different values based on the path
            original_exists = Path.exists
            
            def mock_exists(self):
                # Gemini script doesn't exist, OpenAI does
                if 'gemini.py' in str(self):
                    return False
                elif 'oai.py' in str(self):
                    return True
                elif 'anth.py' in str(self):
                    return True
                return original_exists(self)
            
            with patch.object(Path, 'exists', mock_exists):
                result = stop.get_llm_script_path()
                
                # Should fall back to OpenAI (second priority)
                assert result is not None
                assert 'oai.py' in result

    def test_get_llm_completion_message_uses_priority_selection(self):
        """Test get_llm_completion_message uses get_llm_script_path."""
        mock_script_path = '/fake/path/to/gemini.py'
        
        with patch('stop.get_llm_script_path') as mock_get_path:
            mock_get_path.return_value = mock_script_path
            
            with patch('subprocess.run') as mock_run:
                # Mock successful subprocess run
                mock_result = MagicMock()
                mock_result.returncode = 0
                mock_result.stdout = "Task complete!\n"
                mock_run.return_value = mock_result
                
                result = stop.get_llm_completion_message()
                
                # Verify get_llm_script_path was called
                mock_get_path.assert_called_once()
                
                # Verify subprocess.run was called with correct script
                mock_run.assert_called_once_with([
                    "uv", "run", mock_script_path, "--completion"
                ], capture_output=True, text=True, timeout=10)
                
                # Verify result is cleaned
                assert result == "Task complete!"

    def test_get_llm_completion_message_fallback_on_no_script(self):
        """Test get_llm_completion_message falls back to random message when no LLM script available."""
        with patch('stop.get_llm_script_path') as mock_get_path:
            mock_get_path.return_value = None  # No LLM script available
            
            with patch('stop.get_completion_messages') as mock_messages:
                mock_messages.return_value = ["Fallback message"]
                
                with patch('random.choice') as mock_choice:
                    mock_choice.return_value = "Fallback message"
                    
                    result = stop.get_llm_completion_message()
                    
                    # Should return fallback message
                    assert result == "Fallback message"
                    mock_choice.assert_called_once_with(["Fallback message"])

    def test_get_llm_completion_message_fallback_on_subprocess_error(self):
        """Test get_llm_completion_message falls back on subprocess failure."""
        mock_script_path = '/fake/path/to/gemini.py'
        
        with patch('stop.get_llm_script_path') as mock_get_path:
            mock_get_path.return_value = mock_script_path
            
            with patch('subprocess.run') as mock_run:
                # Mock subprocess failure
                mock_run.side_effect = subprocess.SubprocessError("Failed")
                
                with patch('stop.get_completion_messages') as mock_messages:
                    mock_messages.return_value = ["Fallback message"]
                    
                    with patch('random.choice') as mock_choice:
                        mock_choice.return_value = "Fallback message"
                        
                        result = stop.get_llm_completion_message()
                        
                        # Should fall back to random message
                        assert result == "Fallback message"

    def test_get_llm_completion_message_fallback_on_empty_output(self):
        """Test get_llm_completion_message falls back when subprocess returns empty output."""
        mock_script_path = '/fake/path/to/gemini.py'
        
        with patch('stop.get_llm_script_path') as mock_get_path:
            mock_get_path.return_value = mock_script_path
            
            with patch('subprocess.run') as mock_run:
                # Mock subprocess with empty output
                mock_result = MagicMock()
                mock_result.returncode = 0
                mock_result.stdout = ""  # Empty output
                mock_run.return_value = mock_result
                
                with patch('stop.get_completion_messages') as mock_messages:
                    mock_messages.return_value = ["Fallback message"]
                    
                    with patch('random.choice') as mock_choice:
                        mock_choice.return_value = "Fallback message"
                        
                        result = stop.get_llm_completion_message()
                        
                        # Should fall back to random message
                        assert result == "Fallback message"

    def test_get_llm_completion_message_fallback_on_nonzero_exit(self):
        """Test get_llm_completion_message falls back when subprocess returns non-zero exit code."""
        mock_script_path = '/fake/path/to/gemini.py'
        
        with patch('stop.get_llm_script_path') as mock_get_path:
            mock_get_path.return_value = mock_script_path
            
            with patch('subprocess.run') as mock_run:
                # Mock subprocess with error exit code
                mock_result = MagicMock()
                mock_result.returncode = 1  # Error exit code
                mock_result.stdout = "Error output"
                mock_run.return_value = mock_result
                
                with patch('stop.get_completion_messages') as mock_messages:
                    mock_messages.return_value = ["Fallback message"]
                    
                    with patch('random.choice') as mock_choice:
                        mock_choice.return_value = "Fallback message"
                        
                        result = stop.get_llm_completion_message()
                        
                        # Should fall back to random message
                        assert result == "Fallback message"


class TestAPIKeyPriorityCombinations:
    """Test all combinations of API key availability."""

    def test_only_google_api_key(self):
        """Test behavior with only GOOGLE_API_KEY available."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'test-key'}, clear=True):
            with patch('pathlib.Path.exists', return_value=True):
                result = stop.get_llm_script_path()
                assert 'gemini.py' in result

    def test_only_gemini_api_key(self):
        """Test behavior with only GEMINI_API_KEY available."""
        with patch.dict(os.environ, {'GEMINI_API_KEY': 'test-key'}, clear=True):
            with patch('pathlib.Path.exists', return_value=True):
                result = stop.get_llm_script_path()
                assert 'gemini.py' in result

    def test_only_openai_api_key(self):
        """Test behavior with only OPENAI_API_KEY available."""
        with patch.dict(os.environ, {'OPENAI_API_KEY': 'test-key'}, clear=True):
            with patch('pathlib.Path.exists', return_value=True):
                result = stop.get_llm_script_path()
                assert 'oai.py' in result

    def test_only_anthropic_api_key(self):
        """Test behavior with only ANTHROPIC_API_KEY available."""
        with patch.dict(os.environ, {'ANTHROPIC_API_KEY': 'test-key'}, clear=True):
            with patch('pathlib.Path.exists', return_value=True):
                result = stop.get_llm_script_path()
                assert 'anth.py' in result

    def test_google_and_gemini_keys_preference(self):
        """Test GOOGLE_API_KEY takes priority over GEMINI_API_KEY."""
        with patch.dict(os.environ, {
            'GOOGLE_API_KEY': 'google-key',
            'GEMINI_API_KEY': 'gemini-key'
        }, clear=True):
            with patch('pathlib.Path.exists', return_value=True):
                result = stop.get_llm_script_path()
                assert 'gemini.py' in result  # Both should select Gemini script

    def test_mixed_api_keys_openai_anthropic(self):
        """Test OpenAI priority over Anthropic when both available."""
        with patch.dict(os.environ, {
            'OPENAI_API_KEY': 'openai-key',
            'ANTHROPIC_API_KEY': 'anthropic-key'
        }, clear=True):
            with patch('pathlib.Path.exists', return_value=True):
                result = stop.get_llm_script_path()
                assert 'oai.py' in result  # OpenAI should win


if __name__ == "__main__":
    import subprocess
    pytest.main([__file__])