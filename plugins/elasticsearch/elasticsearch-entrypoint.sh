#!/bin/bash
set -e

# Ensure correct permissions for the Elasticsearch data directory
if [ "$(id -u)" != "1000" ]; then
    echo "Changing ownership of /usr/share/elasticsearch/data to 1000:1000"
    chown -R 1000:1000 /usr/share/elasticsearch/data
fi

# Execute the original entrypoint script with all arguments
exec /usr/share/elasticsearch/bin/elasticsearch "$@"
