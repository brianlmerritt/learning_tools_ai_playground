#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
PLUGINS_DIR="$ROOT_DIR/plugins"
SUBMODULES_FILE="$CONFIGS_DIR/plugins.yaml"

source $ROOT_DIR/bin/setup_environment.sh
echo "Environmental Variables Set including VOLUMES_HOME:${VOLUMES_HOME}"

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

# Get the Moodle Docker network name with better detection
MOODLE_NETWORK=$(docker network ls --format "table {{.Name}}" | grep moodle-docker | head -1)
if [ -z "$MOODLE_NETWORK" ]; then
    # Fallback to default name
    MOODLE_NETWORK="moodle-docker_default"
    echo "Warning: Moodle Docker network not found. Using default: $MOODLE_NETWORK"
else
    echo "Using Moodle Docker network: $MOODLE_NETWORK"
fi
# Export for use in docker-compose files
export MOODLE_NETWORK
echo "MOODLE_NETWORK exported as: $MOODLE_NETWORK"

# Verify the network actually exists
if ! docker network ls --format "{{.Name}}" | grep -q "^${MOODLE_NETWORK}$"; then
    echo "ERROR: Network $MOODLE_NETWORK does not exist. Please run moodle_up.sh first."
    exit 1
fi

# Read the submodules from the YAML file
submodules=$(yq -o=json '.submodules' "$SUBMODULES_FILE")

# Create a temporary file to avoid subshell issues
temp_file=$(mktemp)
echo "$submodules" | jq -c '.[]' > "$temp_file"

# Read from the temporary file instead of using a pipeline
while IFS= read -r submodule; do
    name=$(echo "$submodule" | jq -r '.name')
    path=$(echo "$submodule" | jq -r '.path')
    docker_command=$(echo "$submodule" | jq -r '.docker')
    is_submodule=$(echo "$submodule" | jq -r '.submodule')
    ignore=$(echo "$submodule" | jq -r '.ignore')

    # Output the extracted information
    echo "Name: $name"
    echo "Path: $path"
    echo "Docker Command: $docker_command"

    # Check if ignore is true FIRST
    if [ "$ignore" = "true" ]; then
        echo "Ignoring $name as per plugins.yaml (ignore: true)"
        continue
    fi

    # Extract the plugin directory name from the path
    plugin_directory_name=$(echo "$path" | awk -F'/' '{print $2}')
    
    # Check if the plugin directory exists
    if [ ! -d "$PLUGINS_DIR/$plugin_directory_name" ]; then
        if [ "$is_submodule" = "true" ]; then
            echo "Directory $PLUGINS_DIR/$plugin_directory_name does not exist for submodule $name. Please run ./bin/plugin_submodules.sh to initialize submodules."
            continue
        else
            mkdir -p "$PLUGINS_DIR/$plugin_directory_name"
        fi
    fi

    # Change to the correct plugin subdirectory
    cd "$PLUGINS_DIR/$plugin_directory_name" || exit

    # Run the docker command
    if [ "$docker_command" != "null" ]; then
        echo "Running docker command for $name"
        echo "Current MOODLE_NETWORK value: $MOODLE_NETWORK"
        
        # Extract the YAML file name from the docker command
        yaml_file=$(echo "$docker_command" | sed -n 's/.*-f \([^ ]*\).*/\1/p')
        
        # If no -f flag, assume docker-compose.yaml
        if [ -z "$yaml_file" ]; then
            yaml_file="docker-compose.yaml"
        fi
        
        if [ -n "$yaml_file" ] && [ -f "$yaml_file" ]; then
            # If USE_NVIDIA is true and the plugin is ollama, use the nvidia yaml file
            if [ "$USE_NVIDIA" = "true" ] && [ "$name" = "ollama" ]; then
                yaml_file="${yaml_file/docker-compose.yaml/docker-compose-nvidia.yaml}"
                docker_command="${docker_command/docker-compose.yaml/docker-compose-nvidia.yaml}"
                echo "Using docker-compose-nvidia.yaml for Ollama"
            fi
            
            # Create a backup of the original file
            cp "$yaml_file" "${yaml_file}.backup"
            
            # Check if the file already has a networks section
            if yq eval '.networks' "$yaml_file" > /dev/null 2>&1; then
                echo "Updating existing network configuration in $yaml_file"
                # Update the network configuration using yq
                yq eval -i ".networks.moodle_network.external = true" "$yaml_file"
                yq eval -i ".networks.moodle_network.name = \"$MOODLE_NETWORK\"" "$yaml_file"
            else
                echo "Adding network configuration to $yaml_file"
                # Add the network configuration
                cat >> "$yaml_file" << EOF

networks:
  moodle_network:
    external: true
    name: $MOODLE_NETWORK
EOF
            fi
            
            # Show the network configuration for debugging
            echo "Network configuration in $yaml_file:"
            yq eval '.networks' "$yaml_file"
        fi
        
        # Run the docker compose command with explicit environment variable
        # Also ensure we're using the latest docker compose syntax
        MOODLE_NETWORK="$MOODLE_NETWORK" docker compose ${docker_command#docker compose }
    else
        echo "No docker command specified for $name"
    fi
    echo # extra line for readability

    # Change back to the root directory
    cd "$ROOT_DIR" || exit
done < "$temp_file"

# Clean up temporary file
rm "$temp_file"

echo "AI plugin setup completed."