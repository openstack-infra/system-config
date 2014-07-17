#!/bin/bash -xe

echo "Grabbing consoleLog"

console_log_path='consoleText'
wget -O /tmp/console.txt --no-check-certificate $BUILD_URL$console_log_path
