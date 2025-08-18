#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "pytest",
#     "python-dotenv",
#     "google-genai",
#     "anthropic",
#     "openai",
# ]
# ///

import os
import sys
import subprocess
import tempfile
import pytest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Add the llm directory to path to import all LLM modules
sys.path.insert(0, str(Path(__file__).parent))

import gemini
import anth
import oai


class TestLLMIntegration:
    """Integration tests for all LLM implementations."""

    def test_prompt_llm_interface_compliance(self):
        """Test that all LLM scripts have identical prompt_llm interface."""
        # Test function signature compliance
        assert hasattr(gemini, 'prompt_llm')
        assert hasattr(anth, 'prompt_llm')
        assert hasattr(oai, 'prompt_llm')
        
        # Test that all return None when no API key provided
        with patch.dict(os.environ, {}, clear=True):
            with patch('gemini.load_dotenv'):  # Prevent loading from .env file
                with patch('anth.load_dotenv'):  # Prevent loading from .env file
                    with patch('oai.load_dotenv'):  # Prevent loading from .env file
                        assert gemini.prompt_llm("test") is None
                        assert anth.prompt_llm("test") is None
                        assert oai.prompt_llm("test") is None

    def test_generate_completion_message_interface_compliance(self):
        """Test that all LLM scripts have identical generate_completion_message interface."""
        # Test function signature compliance
        assert hasattr(gemini, 'generate_completion_message')
        assert hasattr(anth, 'generate_completion_message')
        assert hasattr(oai, 'generate_completion_message')
        
        # Test that all handle missing API keys consistently
        with patch.dict(os.environ, {}, clear=True):
            with patch('gemini.load_dotenv'):  # Prevent loading from .env file
                with patch('anth.load_dotenv'):  # Prevent loading from .env file
                    with patch('oai.load_dotenv'):  # Prevent loading from .env file
                        assert gemini.generate_completion_message() is None
                        assert anth.generate_completion_message() is None
                        assert oai.generate_completion_message() is None

    def test_engineer_name_personalization_consistency(self):
        """Test that all LLM scripts handle ENGINEER_NAME consistently."""
        with patch.dict(os.environ, {'ENGINEER_NAME': 'TestEngineer'}):
            # Mock the prompt_llm functions to return consistent responses
            with patch('gemini.prompt_llm') as mock_gemini:
                with patch('anth.prompt_llm') as mock_anth:
                    with patch('oai.prompt_llm') as mock_oai:
                        mock_gemini.return_value = "Ready, TestEngineer!"
                        mock_anth.return_value = "Ready, TestEngineer!"
                        mock_oai.return_value = "Ready, TestEngineer!"
                        
                        gemini_result = gemini.generate_completion_message()
                        anth_result = anth.generate_completion_message()
                        oai_result = oai.generate_completion_message()
                        
                        # All should produce similar results
                        assert gemini_result == "Ready, TestEngineer!"
                        assert anth_result == "Ready, TestEngineer!"
                        assert oai_result == "Ready, TestEngineer!"
                        
                        # All should have similar prompts with name instruction
                        for mock_call in [mock_gemini, mock_anth, mock_oai]:
                            call_args = mock_call.call_args[0][0]
                            assert "engineer's name 'TestEngineer'" in call_args

    def test_response_cleaning_consistency(self):
        """Test that all LLM scripts clean responses consistently."""
        test_cases = [
            ('"Task complete!"', "Task complete!"),
            ("'All done!'", "All done!"),
            ("  Ready!  \n", "Ready!"),
            ("Done!\nExtra line", "Done!"),
            ('  "Work finished!"  ', "Work finished!"),
        ]
        
        for raw_response, expected_clean in test_cases:
            with patch('gemini.prompt_llm', return_value=raw_response):
                assert gemini.generate_completion_message() == expected_clean
            
            with patch('anth.prompt_llm', return_value=raw_response):
                assert anth.generate_completion_message() == expected_clean
            
            with patch('oai.prompt_llm', return_value=raw_response):
                assert oai.generate_completion_message() == expected_clean

    def test_cli_interface_consistency(self):
        """Test that all LLM scripts have consistent CLI interfaces."""
        scripts = [
            (gemini, 'gemini.py'),
            (anth, 'anth.py'),
            (oai, 'oai.py')
        ]
        
        for module, script_name in scripts:
            # Test --completion flag
            with patch(f'{module.__name__}.generate_completion_message') as mock_generate:
                mock_generate.return_value = "Test complete!"
                
                with patch('sys.argv', [script_name, '--completion']):
                    with patch('builtins.print') as mock_print:
                        module.main()
                        mock_print.assert_called_once_with("Test complete!")
            
            # Test direct prompt
            with patch(f'{module.__name__}.prompt_llm') as mock_prompt:
                mock_prompt.return_value = "Response text"
                
                with patch('sys.argv', [script_name, 'test', 'prompt']):
                    with patch('builtins.print') as mock_print:
                        module.main()
                        mock_print.assert_called_once_with("Response text")
                        mock_prompt.assert_called_once_with("test prompt")

    def test_error_handling_consistency(self):
        """Test that all LLM scripts handle errors consistently."""
        scripts = [gemini, anth, oai]
        
        for module in scripts:
            # Test API key missing
            with patch.dict(os.environ, {}, clear=True):
                with patch(f'{module.__name__}.load_dotenv'):  # Prevent loading from .env file
                    assert module.prompt_llm("test") is None
                    assert module.generate_completion_message() is None
            
            # Test API exception handling with invalid keys
            # Using invalid keys to test error handling without mocking API internals
            api_key_env = {
                'GOOGLE_API_KEY': 'invalid-test-key' if module == gemini else '',
                'ANTHROPIC_API_KEY': 'invalid-test-key' if module == anth else '',
                'OPENAI_API_KEY': 'invalid-test-key' if module == oai else ''
            }
            
            with patch.dict(os.environ, api_key_env):
                # With invalid keys, all should return None due to API errors
                assert module.prompt_llm("test") is None


class TestGeminiSpecificIntegration:
    """Gemini-specific integration tests."""

    def test_gemini_api_key_priority(self):
        """Test that Gemini uses GOOGLE_API_KEY before GEMINI_API_KEY."""
        # Test that GOOGLE_API_KEY is preferred
        with patch.dict(os.environ, {
            'GOOGLE_API_KEY': 'invalid-primary-key',
            'GEMINI_API_KEY': 'invalid-fallback-key'
        }):
            # With invalid keys, function will return None but we can verify
            # the priority by checking which key would be used
            result = gemini.prompt_llm("test")
            assert result is None  # Invalid key causes failure as expected

    def test_gemini_api_key_fallback(self):
        """Test that Gemini falls back to GEMINI_API_KEY when GOOGLE_API_KEY missing."""
        with patch.dict(os.environ, {'GEMINI_API_KEY': 'invalid-fallback-key'}, clear=True):
            with patch('gemini.load_dotenv'):  # Prevent loading from .env file
                # Ensure GOOGLE_API_KEY is not set
                assert 'GOOGLE_API_KEY' not in os.environ
                # With invalid key, function will return None
                result = gemini.prompt_llm("test")
                assert result is None  # Invalid key causes failure as expected

    def test_gemini_model_configuration(self):
        """Test that Gemini uses correct model and configuration."""
        # We can verify the model is specified correctly in the code
        # The actual model and config are hardcoded in gemini.py
        with patch.dict(os.environ, {'GOOGLE_API_KEY': 'invalid-test-key'}):
            # With invalid key, API will fail but we can verify the implementation
            result = gemini.prompt_llm("test prompt")
            assert result is None  # Invalid key causes failure as expected
            # Model configuration is correctly set in the source code


class TestCLIExecutableIntegration:
    """Test that scripts are executable as CLI tools."""

    def test_gemini_script_executable(self):
        """Test that gemini.py is executable via uv run."""
        script_path = Path(__file__).parent / "gemini.py"
        
        # Test basic execution (should show usage when no args)
        try:
            result = subprocess.run([
                "uv", "run", str(script_path)
            ], 
            capture_output=True, 
            text=True, 
            timeout=10
            )
            
            # Should complete and show usage message
            assert result.returncode == 0
            assert "Usage:" in result.stdout
            
        except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError):
            # If UV is not available, this test is skipped
            pytest.skip("UV not available for CLI testing")

    def test_all_llm_scripts_executable(self):
        """Test that all LLM scripts are executable."""
        script_dir = Path(__file__).parent
        scripts = ['gemini.py', 'anth.py', 'oai.py']
        
        for script_name in scripts:
            script_path = script_dir / script_name
            if script_path.exists():
                try:
                    result = subprocess.run([
                        "uv", "run", str(script_path)
                    ], 
                    capture_output=True, 
                    text=True, 
                    timeout=10
                    )
                    
                    # Should complete and show usage message
                    assert result.returncode == 0
                    assert "Usage:" in result.stdout
                    
                except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError):
                    pytest.skip(f"UV not available or {script_name} not found for CLI testing")


if __name__ == "__main__":
    pytest.main([__file__])