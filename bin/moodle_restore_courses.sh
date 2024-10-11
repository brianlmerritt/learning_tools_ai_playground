#!/bin/bash

# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Copy the necessary files into the container
docker cp "$ROOT_DIR/moodle_backups" moodle-docker-webserver-1:/mnt/backups
docker cp "$ROOT_DIR/bin/moodle-scripts" moodle-docker-webserver-1:/mnt/scripts

# Execute the restore script inside the container
docker exec -it moodle-docker-webserver-1 \
  /bin/bash -c "bash /mnt/scripts/restore_courses.sh"

# Optionally, remove the copied files after execution
# docker exec moodle-docker-webserver-1 rm -rf /mnt/backups /mnt/scripts
