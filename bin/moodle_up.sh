#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
MOODLE_DIR="$ROOT_DIR/core/moodle"
MOODLE_DOCKER_DIR="$ROOT_DIR/core/moodle-docker"
MOODLE_YAML="$CONFIGS_DIR/moodle.yaml"

export MOODLE_DOCKER_WWWROOT="$ROOT_DIR/core/moodle"
# Install yq if not already installed (yq is a YAML processor)
if ! command -v yq &> /dev/null; then
    echo "yq is required to process YAML files. Aborting..."
    exit 1
fi
# Extract the database name from the YAML file
database_name=$(yq -r '.database[0].name' "$MOODLE_YAML")

# Export the database name as an environment variable
export MOODLE_DOCKER_DB=$database_name

#echo $MOODLE_DOCKER_DB

cp core/moodle-docker/config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

if [ -f "$CONFIGS_DIR/local.yaml" ]; then
    cp "$CONFIGS_DIR/local.yaml" "$MOODLE_DOCKER_DIR/local.yaml"
fi

cd $MOODLE_DOCKER_DIR

# Start up containers
bin/moodle-docker-compose up -d

# Wait for DB to come up (important for oracle/mssql)
bin/moodle-docker-wait-for-db
