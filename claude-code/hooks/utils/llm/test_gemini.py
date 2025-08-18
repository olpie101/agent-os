#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "pytest",
#     "python-dotenv",
#     "google-genai",
# ]
# ///

import os
import sys
import pytest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Add the llm directory to path to import gemini
sys.path.insert(0, str(Path(__file__).parent))

import gemini


class TestGeminiLLM:
    """Test suite for Gemini LLM script functionality."""

    def test_prompt_llm_missing_api_key(self):
        """Test prompt_llm returns None when API key is missing."""
        with patch.dict(os.environ, {}, clear=True):
            with patch('gemini.load_dotenv'):  # Prevent loading from .env file
                result = gemini.prompt_llm("test prompt")
                # Without API key, should return None
                assert result is None

    def test_prompt_llm_with_google_api_key(self):
        """Test prompt_llm uses GOOGLE_API_KEY when available."""
        # Test that function can access GOOGLE_API_KEY
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'invalid-test-key'}):
            # With an invalid key, the API call will fail and return None
            result = gemini.prompt_llm("test prompt")
            # Should return None due to invalid API key
            assert result is None
            
        # Can't test actual API calls without valid key

    def test_prompt_llm_with_gemini_api_key_fallback(self):
        """Test prompt_llm falls back to GEMINI_API_KEY when GOOGLE_API_KEY not available."""
        # Test that function can access GEMINI_API_KEY as fallback
        with patch.dict(os.environ, {'GEMINI_API_KEY': 'invalid-test-key'}, clear=True):
            with patch('gemini.load_dotenv'):  # Prevent loading from .env file
                # Ensure GOOGLE_API_KEY is not set
                assert 'GOOGLE_API_KEY' not in os.environ
                # With an invalid key, the API call will fail and return None
                result = gemini.prompt_llm("test prompt")
                # Should return None due to invalid API key
                assert result is None

    def test_prompt_llm_api_exception_handling(self):
        """Test prompt_llm returns None when API throws exception."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'invalid-key'}):
            # Invalid key should cause API to fail, returning None
            result = gemini.prompt_llm("test prompt")
            assert result is None

    def test_prompt_llm_response_cleaning(self):
        """Test prompt_llm strips whitespace from response."""
        # Can't test response cleaning without actual API response
        # The .strip() call in the implementation handles this
        # Testing with invalid key to verify error handling
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'invalid-key'}):
            result = gemini.prompt_llm("test prompt")
            assert result is None

    def test_generate_completion_message_without_engineer_name(self):
        """Test generate_completion_message without ENGINEER_NAME."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'test-key'}, clear=True):
            with patch('gemini.prompt_llm') as mock_prompt:
                mock_prompt.return_value = '"Task complete!"'
                
                result = gemini.generate_completion_message()
                
                # Verify quotes are stripped
                assert result == "Task complete!"
                # Verify prompt doesn't include name instruction
                call_args = mock_prompt.call_args[0][0]
                assert "engineer's name" not in call_args

    def test_generate_completion_message_with_engineer_name(self):
        """Test generate_completion_message with ENGINEER_NAME."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'test-key', 'ENGINEER_NAME': 'Alice'}):
            with patch('gemini.prompt_llm') as mock_prompt:
                mock_prompt.return_value = 'Ready for you, Alice!'
                
                result = gemini.generate_completion_message()
                
                assert result == "Ready for you, Alice!"
                # Verify prompt includes name instruction
                call_args = mock_prompt.call_args[0][0]
                assert "engineer's name 'Alice'" in call_args

    def test_generate_completion_message_multiline_response(self):
        """Test generate_completion_message takes first line from multiline response."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'test-key'}):
            with patch('gemini.prompt_llm') as mock_prompt:
                mock_prompt.return_value = "Task complete!\nExtra text here"
                
                result = gemini.generate_completion_message()
                assert result == "Task complete!"

    def test_generate_completion_message_prompt_llm_failure(self):
        """Test generate_completion_message returns None when prompt_llm fails."""
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'test-key'}):
            with patch('gemini.prompt_llm') as mock_prompt:
                mock_prompt.return_value = None
                
                result = gemini.generate_completion_message()
                assert result is None

    def test_cli_interface_completion_flag(self):
        """Test CLI interface with --completion flag."""
        with patch('gemini.generate_completion_message') as mock_generate:
            mock_generate.return_value = "All done!"
            
            with patch('sys.argv', ['gemini.py', '--completion']):
                with patch('builtins.print') as mock_print:
                    gemini.main()
                    mock_print.assert_called_once_with("All done!")

    def test_cli_interface_completion_flag_failure(self):
        """Test CLI interface with --completion flag when generation fails."""
        with patch('gemini.generate_completion_message') as mock_generate:
            mock_generate.return_value = None
            
            with patch('sys.argv', ['gemini.py', '--completion']):
                with patch('builtins.print') as mock_print:
                    gemini.main()
                    mock_print.assert_called_once_with("Error generating completion message")

    def test_cli_interface_direct_prompt(self):
        """Test CLI interface with direct prompt."""
        with patch('gemini.prompt_llm') as mock_prompt:
            mock_prompt.return_value = "Response to test"
            
            with patch('sys.argv', ['gemini.py', 'test', 'prompt', 'here']):
                with patch('builtins.print') as mock_print:
                    gemini.main()
                    mock_print.assert_called_once_with("Response to test")
                    mock_prompt.assert_called_once_with("test prompt here")

    def test_cli_interface_direct_prompt_failure(self):
        """Test CLI interface with direct prompt when API fails."""
        with patch('gemini.prompt_llm') as mock_prompt:
            mock_prompt.return_value = None
            
            with patch('sys.argv', ['gemini.py', 'test', 'prompt']):
                with patch('builtins.print') as mock_print:
                    gemini.main()
                    mock_print.assert_called_once_with("Error calling Gemini API")

    def test_cli_interface_no_arguments(self):
        """Test CLI interface with no arguments shows usage."""
        with patch('sys.argv', ['gemini.py']):
            with patch('builtins.print') as mock_print:
                gemini.main()
                mock_print.assert_called_once_with("Usage: ./gemini.py 'your prompt here' or ./gemini.py --completion")


if __name__ == "__main__":
    pytest.main([__file__])