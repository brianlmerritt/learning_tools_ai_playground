#!/bin/bash

# Define the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set USE_NVIDIA
export USE_NVIDIA=true

# Set VOLUMES_HOME
export VOLUMES_HOME="$ROOT_DIR/ai_volumes"

# SET AI Keys here (note do not echo them)

export OPENAI_API_KEY=12345
export ANTHROPIC_API_KEY=54321
export HUGGINGFACE_API_KEY=ab333

echo "Environment variables set:"
echo "USE_NVIDIA=$USE_NVIDIA"
echo "VOLUMES_HOME=$VOLUMES_HOME"
