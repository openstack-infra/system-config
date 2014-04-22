#!/bin/bash -xe

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#

org=$1
project=$2

source /usr/local/jenkins/slave_scripts/functions.sh
check_variable_org_project "$org" "$project" "$0"

source /usr/local/jenkins/slave_scripts/select-mirror.sh $org $project

venv=venv

VDISPLAY=99
DIMENSIONS='1280x1024x24'
/usr/bin/Xvfb :${VDISPLAY} -screen 0 ${DIMENSIONS} 2>&1 > /dev/null &

set +e
DISPLAY=:${VDISPLAY} NOSE_WITH_XUNIT=1 tox -e$venv -- \
    /bin/bash run_tests.sh -N --only-selenium
result=$?

pkill Xvfb 2>&1 > /dev/null
set -e

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
