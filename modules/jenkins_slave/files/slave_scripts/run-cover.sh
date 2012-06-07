#!/bin/bash -xe

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#

if [ -f .cache.bundle ]
then
  venv=jenkinscover
else
  venv=cover
fi

tox -e$venv
result=$?
.tox/$venv/bin/coverage xml

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
