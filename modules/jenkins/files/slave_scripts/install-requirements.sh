#!/bin/bash -ex

# This script installs requirements with pip

PIP_ARGS=""
REQ_FILES=$1

for FILE in $REQ_FILES
do
  if [ -e $FILE ]
  then
    # Ignore lines beginning with https?:// just as the mirror script does.
    sed -e '/^https\?:\/\//d' $FILE > $FILE.clean
    PIP_ARGS="$PIP_ARGS -r $FILE.clean"
  fi
done
# Run the same basic pip command that the mirror script runs.
.venv/bin/pip install -M -U --exists-action=w $PIP_ARGS
if [ -e dev-requirements.txt ] ; then
    .venv/bin/pip install -M -U --exists-action=w -r dev-requirements.txt
fi
