#!/bin/bash -x

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#
# Usage: run-tox.sh VENV
#
# Where VENV is the name of the tox environment to run (specified in the
# project's tox.ini file).

venv=$1
org=$2
project=$3

if [[ -z "$venv" || -z "$org" || -z "$project" ]]
then
  echo "Usage: $? VENV ORG PROJECT"
  echo
  echo "VENV: The tox environment to run (eg 'python27')"
  echo "ORG: The project organization (eg 'stackforge')"
  echo "PROJECT: The project name (eg 'nova')"
  exit 1
fi

source /usr/local/jenkins/slave_scripts/select-mirror.sh $org $project

tox -v -e$venv
