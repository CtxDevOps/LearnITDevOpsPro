#!/usr/bin/env bash
# Description: layer configuration example checking disk space usage.

set -eu

#  Hardcoded Default
effective_target_path="/"
config_source="default"

# Configuration File (Key-Value Parser without 'source') ---
config_file="$HOME/.config/disk_usage.conf"

if [[ -f "$config_file" ]]; then
    while IFS='=' read -r config_key config_value || [[ -n "$config_key" ]]; do
        # Skip empty lines and comments
        [[ -z "$config_key" || "$config_key" == \#* ]] && continue

        if [[ "$config_key" == "TARGET_PATH" ]]; then
            effective_target_path="$config_value"
            config_source="config file ($config_file)"
        else
            # Show a warning to stderr for unknown keys without stopping execution
            echo "Warning: Unknown key '$config_key' in $config_file" >&2
        fi
    done < "$config_file"
fi

# Environment Variable
if [[ -n "${TARGET_PATH:-}" ]]; then
    effective_target_path="$TARGET_PATH"
    config_source="environment variable (TARGET_PATH)"
fi

# Command-Line Options
show_config=false

while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--path" ]]; then
        effective_target_path="$2"
        config_source="command-line option (--path)"
        shift 2
    elif [[ "$1" == "--pokaz-konfiguracje" ]]; then
        show_config=true
        shift
    else
        echo "Error: Unknown option '$1'" >&2
        exit 1
    fi
done

#  Inspection Mode or Main Execution
if [[ "$show_config" == true ]]; then
    echo "TARGET_PATH = $effective_target_path (source: $config_source)"
else
    df -h "$effective_target_path"
fi
