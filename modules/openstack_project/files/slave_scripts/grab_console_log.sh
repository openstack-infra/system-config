#!/bin/bash -xe

echo "Grabbing consoleLog"

console_log_path='consoleText'
wget -P /tmp --no-check-certificate $BUILD_URL$console_log_path
