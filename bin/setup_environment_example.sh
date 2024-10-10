#!/bin/bash

# Define the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set USE_NVIDIA
export USE_NVIDIA=true

# Set VOLUMES_HOME
export VOLUMES_HOME="$ROOT_DIR/ai_volumes"

# SET AI Keys here (note do not echo them)



echo "Environment variables set:"
echo "USE_NVIDIA=$USE_NVIDIA"
echo "VOLUMES_HOME=$VOLUMES_HOME"
