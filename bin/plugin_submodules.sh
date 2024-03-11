#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
MOODLE_DIR="$ROOT_DIR/core/moodle"
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

# Navigate to the Moodle repository
cd "$ROOT_DIR"

# Read the submodules from the YAML file
submodules=$(yq '.submodules' "$SUBMODULES_FILE" )

# Parse the JSON array in a loop
echo "$submodules" | jq -c '.[]' | while read -r submodule; do
    name=$(echo "$submodule" | jq -r '.name')
    url=$(echo "$submodule" | jq -r '.url')
    path=$(echo "$submodule" | jq -r '.path')
    # Use the 'tag' if it exists, otherwise use 'branch'
    branch=$(echo "$submodule" | jq -r '.branch')
    tag=$(echo "$submodule" | jq -r '.tag')

    # Output or process the extracted information as needed
    echo "Name: $name"
    echo "URL: $url"
    echo "Path: $path"
    echo "Branch: $branch"
    echo "Tag: $tag"
    echo # Just for an empty line for readability

    # Check if the submodule directory exists
    if [ -d "$path" ]; then
        # Plugin already exists - if there is a url, checkout the branch
        echo "Setting submodule $name at $path to $branch $tag"
        echo $url
        if [ $url != "null" ]; then
            cd "$path"
            #There is a submodule here
            git checkout $branch
            cd "$ROOT_DIR"
        fi
    else
        # Plugin does not exist - add it as a submodule
        echo "Adding submodule $name at $path"
        git submodule add --branch "$branch" "$url" "$path"
    fi
done

cd "$ROOT_DIR"


