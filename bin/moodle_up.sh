#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$ROOT_DIR/configs"
MOODLE_DIR="$ROOT_DIR/core/moodle"
MOODLE_DOCKER_DIR="$ROOT_DIR/core/moodle-docker"
MOODLE_YAML="$CONFIGS_DIR/moodle.yaml"
source $ROOT_DIR/bin/setup_environment.sh
echo "Environmental Variables Set including VOLUMES_HOME:${VOLUMES_HOME} AND MOODLE_NETWORK:${MOODLE_NETWORK}"

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

### SOME CHECKS FOR SSL OVERRIDE AND RESET MOODLE CONFIG.PHP AND PREPEND PHP TO TELL APACHE TO USE HTTPS ###

# If SSL override is set, modify the config to use HTTPS
if [ "${MOODLE_DOCKER_SSL_OVERRIDE}" = "true" ]; then
    # Use sed to replace the http:// with https:// in the Docker deployment section
    sed -i 's/$CFG->wwwroot   = "http:\/\/{$host}";/$CFG->wwwroot   = "https:\/\/{$host}";/g' $MOODLE_DOCKER_WWWROOT/config.php
    
    # Also add sslproxy setting
    sed -i '/^$CFG->wwwroot/a $CFG->sslproxy = true;' $MOODLE_DOCKER_WWWROOT/config.php
fi

if [ "${MOODLE_DOCKER_SSL_OVERRIDE}" = "true" ]; then
    # First do the config.php modification if not already done
    if ! grep -q "sslproxy = true" $MOODLE_DOCKER_WWWROOT/config.php; then
        sed -i 's/$CFG->wwwroot   = "http:\/\/{$host}";/$CFG->wwwroot   = "https:\/\/{$host}";/g' $MOODLE_DOCKER_WWWROOT/config.php
        sed -i '/^$CFG->wwwroot/a $CFG->sslproxy = true;' $MOODLE_DOCKER_WWWROOT/config.php
    fi
    
    # Create the ssl-override.php file
    cat > $MOODLE_DOCKER_WWWROOT/ssl-override.php << 'EOF'
<?php
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = '8443';
    $_SERVER['REQUEST_SCHEME'] = 'https';
    
    // Fix host if needed
    if (isset($_SERVER['HTTP_HOST'])) {
        $_SERVER['HTTP_HOST'] = preg_replace('/:.*$/', ':8443', $_SERVER['HTTP_HOST']);
    }
}
EOF

    # Create .htaccess with container path
    echo "php_value auto_prepend_file /var/www/html/ssl-override.php" > $MOODLE_DOCKER_WWWROOT/.htaccess
fi

# If SSL override is set, modify the config to use HTTPS
if [ "${MOODLE_DOCKER_SSL_OVERRIDE}" = "true" ]; then
    echo "SSL Override is set, so reconfigured config.php and .htaccess"
fi


if [ "${MOODLE_DOCKER_SSL}" = "true" ]; then
    cp "$CONFIGS_DIR/local_ssl.yaml" "$MOODLE_DOCKER_DIR/local.yml"
else
    cp "$CONFIGS_DIR/local_nossl.yaml" "$MOODLE_DOCKER_DIR/local.yml"
fi

cd $MOODLE_DOCKER_DIR

# Start up containers
bin/moodle-docker-compose up -d

# Wait for DB to come up (important for oracle/mssql)
bin/moodle-docker-wait-for-db

# Print the name of the created network
echo "Moodle Docker network created:"
docker network ls | grep moodle-docker | awk '{print $2}'

# Bring up the nginx proxy
cd $ROOT_DIR/core/nginx_proxy
docker compose up -d
echo "Nginx Proxy network created on port:8443"
