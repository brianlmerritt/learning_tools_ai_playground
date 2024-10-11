#!/bin/bash
set -e

# Correct permissions for the Solr data directory
mkdir -p /var/solr/data
chown -R solr:solr /var/solr

# Execute the original entrypoint script with all arguments
exec docker-entrypoint.sh "$@"