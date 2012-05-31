#!/bin/bash -xe

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#
# Usage: run-tox.sh PYTHONVERSION
#
# Where PYTHONVERSION is the numeric version identifier used as a suffix
# in the tox.ini file.  E.g., "26" or "27" for "py26"/"jenkins26" or
# "py27"/"jenkins27" respectively.

version=$1

if [ -z "$version" ]
then
  echo "The tox environment python version (eg '27') must be the first argument."
  exit 1
fi

if [ -f .cache.bundle ]
then
  venv=jenkins$version
else
  venv=py$version
fi

export NOSE_WITH_XUNIT=1

tox -e$venv
result=$?

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
