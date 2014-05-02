#!/usr/bin/env bash

set -ex

cd $WORKSPACE/repo
scons -U controller/src/base && echo Success

