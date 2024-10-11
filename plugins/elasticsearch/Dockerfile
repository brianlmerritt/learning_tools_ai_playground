FROM docker.elastic.co/elasticsearch/elasticsearch:8.10.4

# Switch to root user to perform privileged operations
USER root

# Copy the custom entrypoint script into the image
COPY elasticsearch-entrypoint.sh /usr/local/bin/

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/elasticsearch-entrypoint.sh

# Switch back to the elasticsearch user
USER elasticsearch

# Override the entrypoint
ENTRYPOINT ["/usr/local/bin/elasticsearch-entrypoint.sh"]
