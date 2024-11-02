#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
SUBMODULES_FILE="$CONFIGS_DIR/plugins.yaml"
PLUGINS_DIR="$ROOT_DIR/plugins"

# If yq or jq not already installed then abort (yq is a YAML processor)
if ! command -v yq &> /dev/null; then
    echo "yq is required to process YAML files. Aborting..."
    exit 1
fi
if ! command -v jq &> /dev/null; then
    echo "jq is required to process JSON data. Aborting..."
    exit 1
fi

# Navigate to the root directory
cd "$ROOT_DIR"

# Read the submodules from the YAML file
submodules=$(yq '.submodules' "$SUBMODULES_FILE")

# Parse the JSON array in a loop
echo "$submodules" | jq -c '.[]' | while read -r submodule; do
    name=$(echo "$submodule" | jq -r '.name')
    url=$(echo "$submodule" | jq -r '.url')
    path=$(echo "$submodule" | jq -r '.path')
    branch=$(echo "$submodule" | jq -r '.branch')
    tag=$(echo "$submodule" | jq -r '.tag')

    # Extract the plugin directory name
    plugin_directory_name=$(echo "$path" | awk -F'/' '{print $2}')
    plugin_path="$PLUGINS_DIR/$plugin_directory_name"

    # Check if docker-compose.yaml exists
    if [ -f "$plugin_path/docker-compose.yaml" ]; then
        echo "$name: docker-compose.yaml exists"
    elif [ -d "$plugin_path" ]; then
        cd "$plugin_path"
        if [ $branch == "null" ]; then
            # Handle tag-based checkout
            branchExists=$(git show-ref refs/heads/plugin$tag)
            if [ -n "$branchExists" ]; then
                git checkout plugin$tag
            else
                git checkout -b plugin$tag $tag
            fi
        else
            # Handle branch-based checkout
            git checkout $branch
            git pull origin $branch
        fi
        cd "$ROOT_DIR"
    else
        echo "Adding plugin $name at $plugin_path"
        # Clone new repository
        if [ $branch != "null" ]; then
            git clone --branch "$branch" "$url" "$plugin_path"
        else
            git clone "$url" "$plugin_path"
            cd "$plugin_path"
            branchExists=$(git show-ref refs/heads/plugin$tag)
            if [ -n "$branchExists" ]; then
                git checkout plugin$tag
            else
                git checkout -b plugin$tag $tag
            fi
            cd "$ROOT_DIR"
        fi
    fi
done

cd "$ROOT_DIR"
