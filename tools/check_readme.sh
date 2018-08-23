#!/bin/bash

# Trivial script run from tox -e linters to ensure roles have a
# README.rst attached

if ! [ -f $1/README.rst ]; then
    echo "*** Missing role documentation: $1/README.rst"
    exit 1
fi
