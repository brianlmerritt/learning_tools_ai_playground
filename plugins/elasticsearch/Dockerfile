FROM docker.elastic.co/elasticsearch/elasticsearch:8.10.4

# Switch to root user to perform privileged operations
USER root

# Create the data directory and set permissions
RUN mkdir -p /usr/share/elasticsearch/data && \
    chown -R 1000:1000 /usr/share/elasticsearch

# Copy the custom entrypoint script into the image
COPY elasticsearch-entrypoint.sh /usr/local/bin/

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/elasticsearch-entrypoint.sh

# Switch back to the elasticsearch user
USER 1000:1000

# Override the entrypoint
ENTRYPOINT ["/usr/local/bin/elasticsearch-entrypoint.sh"]
