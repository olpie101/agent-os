#!/bin/bash

# Agent OS Configuration Hierarchy Loader
# Loads configuration in order: base config.yml → .agent-os.yaml → environment variables

set -e

# Debug mode (set AGENT_OS_DEBUG=1 to enable)
DEBUG="${AGENT_OS_DEBUG:-0}"

debug_log() {
    if [ "$DEBUG" = "1" ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Function to parse YAML using yq if available
parse_yaml_with_yq() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    debug_log "Parsing YAML with yq: $yaml_file"
    
    # Use yq to flatten the YAML and export as environment variables
    while IFS='=' read -r key value; do
        # Convert key to environment variable format
        env_key=$(echo "${prefix}${key}" | tr '[:lower:]' '[:upper:]' | tr '.-' '_' | sed 's/__/_/g')
        export "$env_key=$value"
        debug_log "Exported: $env_key=$value"
    done < <(yq eval '.. | select(tag != "!!seq" and tag != "!!map") | {path | join("_"): .} | to_entries | .[] | .key + "=" + .value' "$yaml_file" 2>/dev/null || true)
    # done < <(yq eval '.. | select(tag == "!!str") | {path | join("_"): .} | to_entries | .[] | .key + "=" + .value' "$yaml_file" 2>/dev/null || true)
}

# Function to parse YAML using bash (fallback)
parse_yaml_with_bash() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    debug_log "Parsing YAML with bash fallback: $yaml_file"
    
    # Parse YAML with support for nested structures
    local current_section=""
    local current_subsection=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Count leading spaces using regex (fixed method)
        local indent_count=0
        if [[ "$line" =~ ^([[:space:]]*) ]]; then
            indent_count=${#BASH_REMATCH[1]}
        fi
        
        # Check if it's a key-value pair
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            
            # Remove leading/trailing whitespace
            key="${key#"${key%%[![:space:]]*}"}"
            key="${key%"${key##*[![:space:]]}"}"
            value="${value#"${value%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"
            
            # Remove quotes and comments from value
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            # Remove inline comments
            value="${value%%#*}"
            value="${value%"${value##*[![:space:]]}"}"
            
            # Determine nesting level based on indentation
            if [ "$indent_count" -eq 0 ]; then
                # Top-level key
                current_section="$key"
                current_subsection=""
                if [ -n "$value" ]; then
                    env_key=$(echo "${prefix}${key}" | tr '[:lower:]' '[:upper:]' | tr '.-' '_')
                    export "$env_key=$value"
                    debug_log "Exported: $env_key=$value"
                fi
            elif [ "$indent_count" -le 2 ]; then
                # Second-level key
                current_subsection="$key"
                if [ -n "$value" ] && [ -n "$current_section" ]; then
                    env_key=$(echo "${prefix}${current_section}_${key}" | tr '[:lower:]' '[:upper:]' | tr '.-' '_')
                    export "$env_key=$value"
                    debug_log "Exported: $env_key=$value"
                fi
            else
                # Third-level key
                if [ -n "$value" ] && [ -n "$current_section" ] && [ -n "$current_subsection" ]; then
                    env_key=$(echo "${prefix}${current_section}_${current_subsection}_${key}" | tr '[:lower:]' '[:upper:]' | tr '.-' '_')
                    export "$env_key=$value"
                    debug_log "Exported: $env_key=$value"
                fi
            fi
        fi
    done < "$yaml_file"
}

# Main function to parse YAML and export as environment variables
parse_yaml_to_env() {
    local yaml_file="$1"
    local prefix="${2:-}"
    
    if [ ! -f "$yaml_file" ]; then
        debug_log "YAML file not found: $yaml_file"
        return 1
    fi
    
    # Check if yq is available
    if command -v yq &> /dev/null; then
        parse_yaml_with_yq "$yaml_file" "$prefix"
    else
        parse_yaml_with_bash "$yaml_file" "$prefix"
    fi
}

# Function to load base configuration
load_base_config() {
    local base_config="${AGENT_OS_HOME:-$HOME/.agent-os}/config.yml"
    
    echo "[DEBUG] config-loader.sh: AGENT_OS_HOME in load_base_config: '${AGENT_OS_HOME}'"
    echo "[DEBUG] config-loader.sh: Computed base_config path: '$base_config'"
    
    if [ -f "$base_config" ]; then
        echo "📚 Loading base configuration from: $base_config"
        parse_yaml_to_env "$base_config" "AGENT_OS_"
    else
        debug_log "Base config not found: $base_config"
    fi
}

# Function to load project configuration
load_project_config() {
    local project_config="${PROJECT_AGENT_OS_DIR:-$PWD/.agent-os}/.agent-os.yaml"
    
    if [ -f "$project_config" ]; then
        echo "📁 Loading project configuration from: $project_config"
        parse_yaml_to_env "$project_config" "AGENT_OS_PROJECT_"
    else
        debug_log "Project config not found: $project_config"
    fi
}

# Function to apply configuration hierarchy
apply_config_hierarchy() {
    echo "🔧 Applying configuration hierarchy..."
    
    # Step 1: Load base configuration
    load_base_config
    
    # Step 2: Load project configuration (overrides base)
    load_project_config
    
    # Step 3: Environment variables override everything
    # These are already set, so we just log them
    debug_log "Environment variables (highest priority):"
    env | grep "^AGENT_OS_" | while read -r var; do
        debug_log "  $var"
    done
    
    echo "✅ Configuration hierarchy loaded"
}

# Function to get a configuration value with fallback
get_config_value() {
    local key="$1"
    local default_value="${2:-}"
    
    # Convert key to environment variable format
    env_key=$(echo "AGENT_OS_$key" | tr '[:lower:]' '[:upper:]' | tr '.-' '__')
    
    # Check environment variable
    value="${!env_key}"
    
    if [ -z "$value" ]; then
        # Try project-specific variable
        project_env_key="AGENT_OS_PROJECT_$key"
        project_env_key=$(echo "$project_env_key" | tr '[:lower:]' '[:upper:]' | tr '.-' '__')
        value="${!project_env_key}"
    fi
    
    # Return value or default
    echo "${value:-$default_value}"
}

# Function to validate required extensions
validate_required_extensions() {
    echo "🔍 Validating required extensions..."
    
    # Check sandbox extension (always required)
    local sandbox_enabled=$(get_config_value "EXTENSIONS_SANDBOX_ENABLED" "true")
    local sandbox_required=$(get_config_value "EXTENSIONS_SANDBOX_REQUIRED" "true")
    
    if [ "$sandbox_required" = "true" ] && [ "$sandbox_enabled" = "false" ]; then
        echo "❌ ERROR: Sandbox extension is required but disabled!"
        echo "   The sandbox extension cannot be disabled as it's required for core functionality."
        return 1
    fi
    
    # Check other required extensions from config
    local all_valid=true
    
    # Parse extensions from config
    for ext in sandbox hooks peer; do
        local ext_upper=$(echo "$ext" | tr '[:lower:]' '[:upper:]')
        local enabled=$(get_config_value "EXTENSIONS_${ext_upper}_ENABLED" "false")
        local required=$(get_config_value "EXTENSIONS_${ext_upper}_REQUIRED" "false")
        
        debug_log "Extension $ext: enabled=$enabled, required=$required"
        
        if [ "$required" = "true" ] && [ "$enabled" = "false" ]; then
            echo "❌ ERROR: Extension '$ext' is required but disabled!"
            all_valid=false
        fi
    done
    
    if [ "$all_valid" = "true" ]; then
        echo "✅ All required extensions are enabled"
        return 0
    else
        return 1
    fi
}

# Export functions for use in other scripts
export -f parse_yaml_to_env
export -f load_base_config
export -f load_project_config
export -f apply_config_hierarchy
export -f get_config_value
export -f validate_required_extensions
export -f debug_log

# If script is run directly (not sourced), apply configuration
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    apply_config_hierarchy
    validate_required_extensions
fi
