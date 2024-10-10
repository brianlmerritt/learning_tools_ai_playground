#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
PLUGINS_DIR="$ROOT_DIR/plugins"
SUBMODULES_FILE="$CONFIGS_DIR/plugins.yaml"

# Check if VOLUMES_HOME is set, if not, set it to the project root ai_volumes directory
if [ -z "$VOLUMES_HOME" ]; then
    source $ROOT_DIR/bin/setup_environment.sh
    echo "VOLUMES_HOME was not set. It has been set to: $VOLUMES_HOME"
fi

# If yq or jq not already installed then abort (yq is a YAML processor)
if ! command -v yq &> /dev/null; then
    echo "yq is required to process YAML files. Aborting..."
    exit 1
fi
if ! command -v jq &> /dev/null; then
    echo "jq is required to process JSON data. Aborting..."
    exit 1
fi

# Read the submodules from the YAML file
submodules=$(yq '.submodules' "$SUBMODULES_FILE")

# Parse the JSON array in a loop
echo "$submodules" | jq -c '.[]' | while read -r submodule; do
    name=$(echo "$submodule" | jq -r '.name')
    path=$(echo "$submodule" | jq -r '.path')
    docker_command=$(echo "$submodule" | jq -r '.docker')

    # Output the extracted information
    echo "Name: $name"
    echo "Path: $path"
    echo "Docker Command: $docker_command"
    #echo # Just for an empty line for readability

    # Extract the plugin directory name from the path
    plugin_directory_name=$(echo "$path" | awk -F'/' '{print $2}')
    
    # Check if the plugin directory exists, if not create it
    if [ ! -d "$PLUGINS_DIR/$plugin_directory_name" ]; then
        mkdir -p "$PLUGINS_DIR/$plugin_directory_name"
    fi

    # Change to the correct plugin subdirectory
    cd "$PLUGINS_DIR/$plugin_directory_name" || exit

    # Run the docker command
    if [ "$docker_command" != "null" ]; then
        echo "Running docker command for $name"
        eval "$docker_command"
    else
        echo "No docker command specified for $name"
    fi
    echo # extra line for readability

    # Change back to the root directory
    cd "$ROOT_DIR" || exit
done

echo "Plugin submodules processing completed."
