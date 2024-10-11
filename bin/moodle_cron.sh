# Define the paths
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

docker exec -it \
  moodle-docker-webserver-1 \
  /usr/local/bin/php /var/www/html/admin/cli/cron.php --keep-alive=10 # Gives us 10 seconds to check or copy output