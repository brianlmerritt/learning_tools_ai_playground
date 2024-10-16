#!/bin/bash
set -e

# Function to wait for Solr to be ready
wait_for_solr() {
    echo "Waiting for Solr to be ready..."
    until $(curl --output /dev/null --silent --head --fail http://localhost:8983/solr); do
        printf '.'
        sleep 5
    done
    echo "Solr is up and running!"
}

# Start Solr in the background
echo "Starting Solr..."
/opt/solr/bin/solr start

# Wait for Solr to be ready
wait_for_solr

# Create a new core if it doesn't exist
if [ ! -d "/var/solr/data/vectorcore" ]; then
    echo "Creating vectorcore..."
    
    # Create the core using the _default configset
    /opt/solr/bin/solr create_core -c vectorcore -d _default
    
    # Disable auto-creation of fields
    /opt/solr/bin/solr config -c vectorcore -p 8983 -action set-user-property -property update.autoCreateFields -value false
else
    echo "vectorcore already exists."
fi

# Keep container running
tail -f /dev/null