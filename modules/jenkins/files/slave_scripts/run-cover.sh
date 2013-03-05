#!/bin/bash -xe

# Run coverage via tox. Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.

org=$1
project=$2

if [[ -z "$org" || -z "$project" ]]
then
  echo "Usage: $0 ORG PROJECT"
  echo
  echo "ORG: The project organization (eg 'openstack')"
  echo "PROJECT: The project name (eg 'nova')"
  exit 1
fi

/usr/local/jenkins/slave_scripts/select-mirror.sh $org $project

export NOSE_COVER_HTML=1

venv=cover

tox -e$venv
result=$?

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
