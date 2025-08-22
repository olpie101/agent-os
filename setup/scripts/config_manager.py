#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pyyaml",
# ]
# ///

"""Configuration management for Agent OS extensions."""

import os
from pathlib import Path
from typing import Dict, Any, List, Optional

import yaml


class ConfigManager:
    """Manages configuration loading, merging, and validation."""

    def __init__(self):
        self.base_config: Dict[str, Any] = {}
        self.project_config: Dict[str, Any] = {}
        self.env_config: Dict[str, Any] = {}
        self.merged_config: Dict[str, Any] = {}

    def flatten_dict(self, d: Dict, parent_key: str = '', sep: str = '_') -> Dict:
        """Flatten nested dictionary structure."""
        items = []
        for k, v in d.items():
            new_key = f"{parent_key}{sep}{k}" if parent_key else k
            if isinstance(v, dict):
                items.extend(self.flatten_dict(v, new_key, sep=sep).items())
            else:
                # Convert to uppercase and replace dots/dashes with underscores
                final_key = new_key.upper().replace('.', '_').replace('-', '_')
                items.append((final_key, v))
        return dict(items)

    def load_yaml(self, path: Path) -> Dict:
        """Load and parse YAML file."""
        if not path.exists():
            return {}

        with open(path, 'r') as f:
            data = yaml.safe_load(f)
            return data if data else {}

    def load_configs(self, base_config_path: Optional[Path], project_config_path: Optional[Path] = None):
        """Load all configuration sources."""
        # Load base configuration
        if base_config_path and base_config_path.exists():
            raw_config = self.load_yaml(base_config_path)
            self.base_config = self.flatten_dict(raw_config)
            print(f"📚 Loaded base configuration from: {base_config_path}")

        # Load project configuration
        if project_config_path and project_config_path.exists():
            raw_config = self.load_yaml(project_config_path)
            self.project_config = self.flatten_dict(raw_config)
            print(f"📁 Loaded project configuration from: {project_config_path}")

        # Load environment variables (removing AGENT_OS_ prefix for consistency)
        self.env_config = {}
        for key, value in os.environ.items():
            if key.startswith('AGENT_OS_'):
                clean_key = key[9:]  # Remove 'AGENT_OS_' prefix
                self.env_config[clean_key] = value

    def merge_configs(self):
        """Merge configurations with proper hierarchy: base < project < env."""
        # Start with base config
        self.merged_config = dict(self.base_config)

        # Override with project config
        for key, value in self.project_config.items():
            self.merged_config[key] = value

        # Override with environment variables (highest priority)
        for key, value in self.env_config.items():
            self.merged_config[key] = value

    def validate_requirements(self) -> List[str]:
        """Validate that required extensions are enabled."""
        errors = []

        # Check each known extension
        for ext in ['sandbox', 'hooks', 'peer']:
            ext_upper = ext.upper()
            required_key = f'EXTENSIONS_{ext_upper}_REQUIRED'
            enabled_key = f'EXTENSIONS_{ext_upper}_ENABLED'

            # 'required' must come from base config (not overridable)
            required = str(self.base_config.get(required_key, 'false')).lower()
            # 'enabled' comes from merged config (respects overrides)
            enabled = str(self.merged_config.get(enabled_key, 'false')).lower()

            if required == 'true' and enabled != 'true':
                errors.append(f"Extension '{ext}' is required but disabled")

        return errors

    def get_value(self, key: str, default: Any = None) -> Any:
        """Get a configuration value from the merged config."""
        return self.merged_config.get(key, default)
    
    def get_merged_config(self) -> Dict[str, Any]:
        """Get the complete merged configuration."""
        return self.merged_config