#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
PLUGINS_DIR="$ROOT_DIR/plugins"
SUBMODULES_FILE="$CONFIGS_DIR/plugins.yaml"

source $ROOT_DIR/bin/setup_environment.sh
echo "Environmental Variables Set including VOLUMES_HOME:${VOLUMES_HOME}"

#sudo chown -R 8983:8983 ${VOLUMES_HOME}/solr_data
#sudo chmod -R 755 ${VOLUMES_HOME}/solr_data

# If yq or jq not already installed then abort (yq is a YAML processor)
if ! command -v yq &> /dev/null; then
    echo "yq is required to process YAML files. Aborting..."
    exit 1
fi
if ! command -v jq &> /dev/null; then
    echo "jq is required to process JSON data. Aborting..."
    exit 1
fi

# Use the USE_NVIDIA environment variable set by setup_environment.sh
if [ "$USE_NVIDIA" = "true" ]; then
    echo "Nvidia support enabled by setup_environment.sh"
else
    # Check the plugins.yaml file as a fallback
    use_nvidia=$(yq -r '.use_nvidia' "$SUBMODULES_FILE")
    if [ "$use_nvidia" = "true" ]; then
        export USE_NVIDIA=true
        echo "Nvidia support enabled by plugins.yaml"
    else
        export USE_NVIDIA=false
        echo "Nvidia support disabled"
    fi
fi

# Get the Moodle Docker network name
MOODLE_NETWORK=$(docker network ls | grep moodle-docker | awk '{print $2}')
if [ -z "$MOODLE_NETWORK" ]; then
    echo "Error: Moodle Docker network not found. Please run bin/moodle_up.sh first."
    exit 1
fi
echo "Using Moodle Docker network: $MOODLE_NETWORK"

# Read the submodules from the YAML file
# submodules=$(yq '.submodules' "$SUBMODULES_FILE")
submodules=$(yq -o=json '.submodules' "$SUBMODULES_FILE")


# Parse the JSON array in a loop
echo "$submodules" | jq -c '.[]' | while read -r submodule; do
    name=$(echo "$submodule" | jq -r '.name')
    path=$(echo "$submodule" | jq -r '.path')
    docker_command=$(echo "$submodule" | jq -r '.docker')

    # Output the extracted information
    echo "Name: $name"
    echo "Path: $path"
    echo "Docker Command: $docker_command"

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
        # Extract the YAML file name from the docker command
        yaml_file=$(echo "$docker_command" | sed -n 's/.*-f \([^ ]*\).*/\1/p')
        if [ -n "$yaml_file" ]; then
            # If USE_NVIDIA is true and the plugin is ollama, use the nvidia yaml file
            if [ "$USE_NVIDIA" = "true" ] && [ "$name" = "ollama" ]; then
                yaml_file="${yaml_file/docker-compose.yaml/docker-compose-nvidia.yaml}"
                docker_command="${docker_command/docker-compose.yaml/docker-compose-nvidia.yaml}"
                echo "Using docker-compose-nvidia.yaml for Ollama"
            fi
            # Add or update the network configuration in the YAML file
            if ! grep -q "networks:" "$yaml_file"; then
                echo "networks:" >> "$yaml_file"
                echo "  moodle_network:" >> "$yaml_file"
                echo "    external: true" >> "$yaml_file"
                echo "    name: $MOODLE_NETWORK" >> "$yaml_file"
            fi
        fi
        # Run the docker compose command
        eval "$docker_command"
    else
        echo "No docker command specified for $name"
    fi
    echo # extra line for readability

    # Change back to the root directory
    cd "$ROOT_DIR" || exit
done

echo "AI plugin setup completed."
