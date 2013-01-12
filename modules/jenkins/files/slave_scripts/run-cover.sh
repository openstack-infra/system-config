#!/bin/bash -xe

# Run coverage via tox. Also, run pip freeze on the
# resulting environment at the end so that we have a record of exactly
# what packages we ended up testing.

export NOSE_COVER_HTML=1

venv=cover

tox -e$venv
result=$?

echo "Begin pip freeze output from test virtualenv:"
echo "======================================================================"
.tox/$venv/bin/pip freeze
echo "======================================================================"

exit $result
