#!/bin/bash -xe

URL=$1

echo "Jenkins: Waiting for Nova to start on infrastructure node"
RET=7
while [ $RET != 0 ]; do
    curl -s $URL >/dev/null
    RET=$?
    sleep 1
done
echo "Jenkins: Nova is running."
