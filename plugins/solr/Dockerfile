FROM solr:9.4

# Switch to root to install plugins and set up scripts
USER root

# Install required plugins for vector search
RUN apt-get update && apt-get install -y wget curl && \
    mkdir -p /opt/solr/contrib/ltr/lib && \
    wget -O /opt/solr/contrib/ltr/lib/solr-ltr-9.4.0.jar https://repo1.maven.org/maven2/org/apache/solr/solr-ltr/9.4.0/solr-ltr-9.4.0.jar

# Copy custom configuration files
COPY solr_config/solrconfig.xml /opt/solr/server/solr/configsets/_default/conf/
COPY solr_config/managed-schema /opt/solr/server/solr/configsets/_default/conf/
COPY solr_config/stopwords.txt /opt/solr/server/solr/configsets/_default/conf/
COPY solr_config/synonyms.txt /opt/solr/server/solr/configsets/_default/conf/

# Set proper permissions for the copied files
RUN chown solr:solr /opt/solr/server/solr/configsets/_default/conf/solrconfig.xml \
    /opt/solr/server/solr/configsets/_default/conf/managed-schema \
    /opt/solr/server/solr/configsets/_default/conf/stopwords.txt \
    /opt/solr/server/solr/configsets/_default/conf/synonyms.txt && \
    chmod 644 /opt/solr/server/solr/configsets/_default/conf/solrconfig.xml \
    /opt/solr/server/solr/configsets/_default/conf/managed-schema \
    /opt/solr/server/solr/configsets/_default/conf/stopwords.txt \
    /opt/solr/server/solr/configsets/_default/conf/synonyms.txt

# Copy custom entrypoint script
COPY solr-entrypoint.sh /usr/local/bin/solr-entrypoint.sh
RUN chmod +x /usr/local/bin/solr-entrypoint.sh

# Create necessary directories and set permissions
RUN mkdir -p /var/solr/data && \
    chown -R solr:solr /var/solr /opt/solr/server/solr/configsets /opt/solr/contrib

# Switch back to solr user
USER solr

# Expose the default Solr port
EXPOSE 8983

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/solr-entrypoint.sh"]
