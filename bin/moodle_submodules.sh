#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
MOODLE_DIR="$ROOT_DIR/core/moodle"
SUBMODULES_FILE="$CONFIGS_DIR/moodle.yaml"

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
    branch_or_tag=$(echo "$submodule" | jq -r '.tag // .branch')
    
    # Output or process the extracted information as needed
    echo "Name: $name"
    echo "URL: $url"
    echo "Path: $path"
    echo "Branch/Tag: $branch_or_tag"
    echo # Just for an empty line for readability

    # Check if the submodule directory exists
    if [ -d "$path" ]; then
        echo "Setting submodule $name at $path to $branch_or_tag"
        cd "$path"
        #git submodule update --init --recursive 
        git checkout "$branch_or_tag"
        cd "$ROOT_DIR"
    else
        if [[ $path == *"core/moodle/"* ]]; then
            stripped_path="${path#*core/moodle/}"
            cd "$MOODLE_DIR"
            echo "Adding submodule $name at $path"
            git submodule add --branch "$branch_or_tag" "$url" "$stripped_path"
        else
            cd "$MOODLE_DIR"
            echo "Adding submodule $name at $path"
            git submodule add --branch "$branch_or_tag" "$url" "$path"
        fi
    fi
done

cd "$ROOT_DIR"
git submodule update --init --recursive

