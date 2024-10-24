#!/bin/bash

# Define the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set USE_NVIDIA
export USE_NVIDIA=true

# Set VOLUMES_HOME
export VOLUMES_HOME="$ROOT_DIR/ai_volumes"
export MOODLE_NETWORK=${MOODLE_NETWORK:-moodle-docker_default}
export MOODLE_DOCKER_WEB_HOST=your.domain.com
export MOODLE_DOCKER_WEB_PORT=8443 # If Using SSL, otherwise use 80000
export MOODLE_DOCKER_SSL=true # If Using SSL, otherwise set to false

# SET AI Keys here (note do not echo them)

export OPENAI_API_KEY=12345
export ANTHROPIC_API_KEY=54321
export HUGGINGFACE_API_KEY=ab333

echo "Environment variables set:"
echo "USE_NVIDIA=$USE_NVIDIA"
echo "VOLUMES_HOME=$VOLUMES_HOME"



