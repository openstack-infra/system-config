#!/usr/bin/env bash

set -ex

env
cd $WORKSPACE/repo
scons -U controller/src/base 2>&1 | tee scons_cmd_output.txt
echo Success

