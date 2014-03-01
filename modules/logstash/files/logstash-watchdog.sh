#!/bin/bash
#
# This is a work around for https://logstash.jira.com/browse/LOGSTASH-1951
# Logstash disconnects from the cluster and will not rejoin under
# its own power.

date >> /var/log/logstash/watchdog.log
ES_ADDRESS=$1
echo "$ES_ADDRESS" >> /var/log/logstash/watchdog.log

JSON_OUT=$(curl -sf "http://${ES_ADDRESS}:9200/_cluster/nodes/${HOSTNAME}")
CURL_RET=$?
echo "$JSON_OUT" >> /var/log/logstash/watchdog.log
echo "$CURL_RET" >> /var/log/logstash/watchdog.log
RESULT=$(echo $JSON_OUT | jq '.nodes == {}')
echo "$RESULT" >> /var/log/logstash/watchdog.log

if [ "$CURL_RET" == "0" ] && [ "$RESULT" == "true" ] ;
then
    echo "restarting" >> /var/log/logstash/watchdog.log
    stop --quiet logstash-indexer
    start --quiet logstash-indexer
fi
