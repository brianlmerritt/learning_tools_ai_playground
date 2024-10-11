# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

docker exec -it \
  --memory=4g \
  -v $ROOT_DIR/moodle_backups:/mnt/backups:ro \
  -v $ROOT_DIR/bin/moodle-scripts:/mnt/scripts \
  moodle-docker-webserver-1 \
  /bin/bash -c "bash /mnt/scripts/restore_courses.sh"