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

# Detect yq flavor: mikefarah/yq needs -o=json; Python yq (kislyuk) outputs JSON by default
if yq --version 2>&1 | grep -qi 'mikefarah'; then
    YQ_JSON_FLAG="-o=json"
else
    YQ_JSON_FLAG=""
fi

# Navigate to the Moodle repository
cd "$ROOT_DIR"

# Read the submodules from the YAML file
submodules=$(yq $YQ_JSON_FLAG '.submodules' "$SUBMODULES_FILE")


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

    # Check if the submodule directory exists AND is a valid git repository.
    # A directory that exists but is not a git repo (e.g. from an interrupted
    # previous clone) is removed so the plugin can be properly cloned below.
    if [ -d "$path" ] && ! git -C "$path" rev-parse --git-dir > /dev/null 2>&1; then
        echo "Directory $path exists but is not a git repo — removing and re-cloning"
        rm -rf "$path"
    fi

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
            # Branch is set: fetch remote and pull only if remote has changes and local files do not
            git fetch origin
            git checkout $branch

            local_sha=$(git rev-parse HEAD)
            remote_sha=$(git rev-parse "origin/$branch" 2>/dev/null || echo "unknown")

            if [ "$local_sha" != "$remote_sha" ] && [ "$remote_sha" != "unknown" ]; then
                # Count actual user file modifications only.
                # Excludes: submodule pointer changes (directories, not files)
                # Excludes: .gitmodules (managed by submodule operations, not user edits)
                modified_files=$(git diff --name-only HEAD 2>/dev/null | \
                    while IFS= read -r filepath; do
                        [ -f "$filepath" ] && [ "$filepath" != ".gitmodules" ] && echo "$filepath"
                    done | wc -l | tr -d ' ')

                if [ "$modified_files" -eq 0 ]; then
                    should_pull="y"

                    # moodle-docker can change base images significantly.
                    # Ask for confirmation before pulling remote changes.
                    if [ "$path" = "core/moodle-docker" ]; then
                        if [ -t 0 ]; then
                            while true; do
                                read -r -p "Remote updates found for moodle-docker on $branch. Pull now? [y/n/q]: " reply
                                case "${reply}" in
                                    [Yy])
                                        should_pull="y"
                                        break
                                        ;;
                                    [Nn])
                                        should_pull="n"
                                        break
                                        ;;
                                    [Qq])
                                        echo "Stopping script at user request."
                                        exit 0
                                        ;;
                                    *)
                                        echo "Please enter y, n, or q."
                                        ;;
                                esac
                            done
                        else
                            should_pull="n"
                            echo "Remote updates found for moodle-docker; non-interactive shell detected, skipping pull."
                        fi
                    fi

                    if [ "$should_pull" = "y" ]; then
                        echo "Pulling remote updates for $path..."
                        git pull origin $branch
                    else
                        echo "Skipping remote pull for $path."
                    fi
                else
                    echo "ERROR: $path has local file changes and remote changes. Manual resolution required. Aborting."
                    exit 1
                fi
            fi
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
