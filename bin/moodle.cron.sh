# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

docker exec -it \
  --memory=4g \
  moodle-docker-webserver-1 \
  /usr/local/bin/php /usr/local/bin/php/cron.php --keep-alive=10 # Gives us 10 seconds to check or copy output