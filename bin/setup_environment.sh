#!/bin/bash

# Define the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env from project root and export every variable defined in it.
# set -a causes all subsequent assignments to be automatically exported.
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    # shellcheck source=../.env
    source "$ROOT_DIR/.env"
    set +a
else
    echo "Warning: $ROOT_DIR/.env not found. Copy .env.example to .env and populate it."
fi

# Defaults — only applied when not already set by .env
export USE_NVIDIA=${USE_NVIDIA:-false}
export VOLUMES_HOME=${VOLUMES_HOME:-$ROOT_DIR/ai_volumes}
export MOODLE_NETWORK=${MOODLE_NETWORK:-moodle-docker_default}
export MOODLE_DOCKER_WEB_HOST=${MOODLE_DOCKER_WEB_HOST:-localhost}
export MOODLE_DOCKER_WEB_PORT=${MOODLE_DOCKER_WEB_PORT:-8000}
export MOODLE_DOCKER_SSL=${MOODLE_DOCKER_SSL:-false}
export MOODLE_DOCKER_BROWSER=${MOODLE_DOCKER_BROWSER:-chrome}

# Detect yq flavor: mikefarah/yq needs -o=json; Python yq (kislyuk) outputs JSON by default.
# Exported so scripts that source this file can use $YQ_JSON_FLAG without re-detecting.
if yq --version 2>&1 | grep -qi 'mikefarah'; then
    export YQ_JSON_FLAG="-o=json"
else
    export YQ_JSON_FLAG=""
fi

echo "Environment variables set:"
echo "USE_NVIDIA=$USE_NVIDIA"
echo "VOLUMES_HOME=$VOLUMES_HOME"