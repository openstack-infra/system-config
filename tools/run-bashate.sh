#!/bin/bash

ROOT=$(readlink -fn $(dirname $0)/.. )
find $ROOT -not -wholename \*.tox/\* -and \( -name \*.sh -or -name \*rc -or -name functions\* \) -and -not -name "gerrit-2.8.4-cleanup.sh" -print0 | \
xargs -0 bashate -v
