#!/bin/bash
echo "ERROR - this stript is no longer used"
exit 1
# Create solrconfig.xml
cat << EOF > /opt/solr/server/solr/configsets/_default/conf/solrconfig.xml
<?xml version="1.0" encoding="UTF-8" ?>
<config>
  <luceneMatchVersion>9.4</luceneMatchVersion>
  
  <lib dir="${solr.install.dir:../../../..}/contrib/ltr/lib/" regex=".*\.jar" />
  <lib dir="${solr.install.dir:../../../..}/dist/" regex="solr-ltr-\d.*\.jar" />

  <requestHandler name="/select" class="solr.SearchHandler">
    <lst name="defaults">
      <str name="echoParams">explicit</str>
      <int name="rows">10</int>
    </lst>
  </requestHandler>

  <query>
    <enableLazyFieldLoading>true</enableLazyFieldLoading>
  </query>

  <transformer name="features" class="org.apache.solr.ltr.response.transform.LTRFeatureLoggerTransformerFactory">
    <str name="fvCacheName">QUERY_DOC_FV</str>
  </transformer>

  <queryParser name="ltr" class="org.apache.solr.ltr.search.LTRQParserPlugin"/>

  <cache name="QUERY_DOC_FV"
         class="solr.search.LRUCache"
         size="4096"
         initialSize="2048"
         autowarmCount="4096"
         regenerator="solr.NoOpRegenerator" />
         
  <runtimeLib>true</runtimeLib>
</config>
EOF

# Create managed-schema
cat << EOF > /opt/solr/server/solr/configsets/_default/conf/managed-schema
<?xml version="1.0" encoding="UTF-8"?>
<schema name="default-config" version="1.6">
  <field name="id" type="string" indexed="true" stored="true" required="true" multiValued="false"/>
  <field name="text" type="text_general" indexed="true" stored="true"/>
  <field name="vector" type="knn_vector" indexed="true" stored="true"/>

  <fieldType name="string" class="solr.StrField" sortMissingLast="true"/>
  <fieldType name="text_general" class="solr.TextField" positionIncrementGap="100">
    <analyzer type="index">
      <tokenizer class="solr.StandardTokenizerFactory"/>
      <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords.txt"/>
      <filter class="solr.LowerCaseFilterFactory"/>
    </analyzer>
    <analyzer type="query">
      <tokenizer class="solr.StandardTokenizerFactory"/>
      <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords.txt"/>
      <filter class="solr.SynonymGraphFilterFactory" synonyms="synonyms.txt" ignoreCase="true" expand="true"/>
      <filter class="solr.LowerCaseFilterFactory"/>
    </analyzer>
  </fieldType>

  <fieldType name="knn_vector" class="solr.DenseVectorField" vectorDimension="768" similarityFunction="cosine"/>

  <uniqueKey>id</uniqueKey>
</schema>
EOF