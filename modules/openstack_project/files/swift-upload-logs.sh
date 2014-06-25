#!/bin/sh

SWIFT_SERVER=https://
USER=
SERVICE=
CONTAINER=
KEY=
SWIFT=swift

CONTAINER=$1
LOG_PATH=$2
CONSOLE_URL=$3
WORKSPACE=$4

TIMEOUT=180

for f in `ls /opt/stack/logs/*.201*`; do
  rm $f
done

mkdir $LOG_PATH -p
ln -s /opt/stack/logs $LOG_PATH

# get current copy of console, probably truncated
curl -o $LOG_PATH/console.html $CONSOLE_URL
sed '1 i<pre>' -i $LOG_PATH/console.html  && sed '$ a</pre>' -i $LOG_PATH/console.html

# upload
$SWIFT -A $SWIFT_SERVER -U "$SERVICE:$USER" -K $KEY upload $CONTAINER $LOG_PATH

# get full console
mainpid=$$
(sleep $TIMEOUT; kill $mainpid) &
watchdogpid=$!

while ! curl -s $CONSOLE_URL | grep -q "_ summary _"; do continue; done
curl -o $LOG_PATH/console.html $CONSOLE_URL
sed '1 i<pre>' -i $LOG_PATH/console.html  && sed '$ a</pre>' -i $LOG_PATH/console.html
$SWIFT -A $SWIFT_SERVER -U "$SERVICE:$USER" -K $KEY upload $CONTAINER $LOG_PATH/console.html

kill $watchdogpid
