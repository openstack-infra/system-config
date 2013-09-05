#!/bin/bash -ex

# This script installs a list of requirements using pip

PIP_ARGS=""
REQ_FILES=$1

for FILE in $REQ_FILES
do
  if [[ -e $FILE ]]; then
    if [[ $FILE == "dev-requirements.txt" ]]; then
      PIP_ARGS="$PIP_ARGS -r $FILE"
    else
      # Ignore lines beginning with https?:// just as the mirror script does.
      sed -e '/^https\?:\/\//d' $FILE > $FILE.clean
      PIP_ARGS="$PIP_ARGS -r $FILE.clean"
    fi
    # Run the same basic pip command that the mirror script runs.
    .venv/bin/pip install -M -U --exists-action=w $PIP_ARGS
  fi
done
