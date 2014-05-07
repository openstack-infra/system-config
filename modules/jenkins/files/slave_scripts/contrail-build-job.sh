#!/usr/bin/env bash

set -ex

env
cd $WORKSPACE/repo
scons -U controller/src/base
echo Success

