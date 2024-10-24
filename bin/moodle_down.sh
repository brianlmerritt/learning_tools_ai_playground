#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
MOODLE_DIR="$ROOT_DIR/core/moodle"
MOODLE_DOCKER_DIR="$ROOT_DIR/core/moodle-docker"
MOODLE_YAML="$CONFIGS_DIR/moodle.yaml"

export MOODLE_DOCKER_WWWROOT="$ROOT_DIR/core/moodle"

database_name=$(yq -r '.database[0].name' "$MOODLE_YAML")

# Export the database name as an environment variable
export MOODLE_DOCKER_DB=$database_name

# Shutdown the nginx proxy
cd $ROOT_DIR/core/nginx_proxy
docker compose down

cd $MOODLE_DOCKER_DIR

# Start up containers
bin/moodle-docker-compose down