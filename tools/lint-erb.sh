#!/bin/bash

echo "linting erb"

find . -type f -name '*.erb' -exec cat {} \; |\
grep 'scope.lookup'
ret1=$?

find . -type f -name '*.erb' -exec cat {} \; |\
grep '<%='


