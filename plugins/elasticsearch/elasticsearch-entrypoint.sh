#!/bin/bash
set -e

# Correct permissions for the Elasticsearch data directory
# mkdir -p /usr/share/elasticsearch/data
# chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data

# Execute the original entrypoint script with all arguments
exec /usr/local/bin/docker-entrypoint.sh "$@"
