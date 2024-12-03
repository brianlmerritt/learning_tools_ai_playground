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
        echo "Setting submodule $name at $path to $branch $tag"
        cd "$path"
        echo $branch
        if [ $branch == "null" ]; then
            # If there is no branch, then we assume a tag is involved, create new branch or checkout existing
            branchExists=$(git show-ref refs/heads/moodle$tag)
            if [ -n "$branchExists" ]; then
                # If the branch exists, just check it out
                git checkout moodle$tag
            else
                # If the branch does not exist, create it based on $tag
                git checkout -b moodle$tag $tag
            fi
        else
            # Branch is set so just check it out
            git checkout $branch
        fi
        cd "$ROOT_DIR"
    else
        if [[ $path == *"core/moodle/"* ]]; then
            stripped_path="${path#*core/moodle/}"
            cd "$MOODLE_DIR"
            echo "Adding another submodule $name at $path"
            # Check if submodule already exists in .gitmodules
            if grep -q "path = $stripped_path" .gitmodules 2>/dev/null; then
                echo "Submodule already exists, updating instead..."
                git submodule update --init --recursive "$stripped_path"
                if [ $branch != "null" ]; then
                    (cd "$stripped_path" && git checkout "$branch")
                fi
            else
                basename="${stripped_path##*/}"
                shorter_path="${stripped_path%/*}"  # This removes the last folder from stripped_path
                if [ -d "$shorter_path" ]; then
                    cd "$shorter_path"
                    git submodule add -f --branch "$branch" "$url" "./$basename"
                else
                    git submodule add --branch "$branch" "$url" "$stripped_path"
                fi
            fi
        else
            cd "$MOODLE_DIR"
            echo "Adding new submodule $name at $path"
            if grep -q "path = $path" .gitmodules 2>/dev/null; then
                echo "Submodule already exists, updating instead..."
                git submodule update --init --recursive "$path"
                if [ $branch != "null" ]; then
                    (cd "$path" && git checkout "$branch")
                fi
            else
                git submodule add --branch "$branch" "$url" "$path"
            fi
        fi
    fi
done

cd "$ROOT_DIR"
