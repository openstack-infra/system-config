#!/bin/bash
#
# This is a work around for https://logstash.jira.com/browse/LOGSTASH-1951
# Logstash disconnects from the cluster and will not rejoin under
# its own power.

ES_ADDRESS=$1

JSON_OUT=$(curl -sf "http://${ES_ADDRESS}:9200/_cluster/nodes/${HOSTNAME}")
CURL_RET=$?
RESULT=$(echo $JSON_OUT | jq '.nodes == {}')

if [ "$CURL_RET" == "0" ] && [ "$RESULT" == "true" ] ;
then
    stop --quiet logstash-indexer
    start --quiet logstash-indexer
fi
