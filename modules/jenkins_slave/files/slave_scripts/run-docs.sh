#!/bin/bash -xe

# If a bundle file is present, call tox with the jenkins version of
# the test environment so it is used.  Otherwise, use the normal
# (non-bundle) test environment.  Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.
#

venv=venv

mkdir -p doc/build
export HUDSON_PUBLISH_DOCS=1
tox -e$venv -- python setup.py build_sphinx
result=$?

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
