#!/bin/bash

ES_ADDRESS=$1

JSON_OUT=$(curl -sf "http://$ES_ADDRESS/_cluster/nodes/$HOSTNAME")
CURL_RET=$?
RESULT=$(echo $JSON_OUT | jq '.node == {}')

if [ "$CURL_RET" == "0" ] && [ "$RESULT" == "true" ] ;
then
    restart logstash-indexer
fi
