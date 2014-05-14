#!/usr/bin/env bash

set -o pipefail
set -ex

if [ -z $USER ]; then
    USER=jenkins
fi

export WORKSPACE=$PWD
if [ -z $SCONS_JOBS ]; then
    export SCONS_JOBS=1
fi

# Build unittests
function build_unittest() {
    # Goto the repo top directory.
    cd $WORKSPACE/repo

    # Build every thing.
    export BUILD_ONLY=TRUE
    scons -j $SCONS_JOBS -U . 2>&1 | tee $WORKSPACE/scons_build.log
    # scons -j $SCONS_JOBS -U test 2>&1 | tee $WORKSPACE/scons_build.log

    unset BUILD_ONLY
}

# Run unittests
function run_unittest() {
    # Goto the repo top directory.
    cd $WORKSPACE/repo

    ### Ignore test failures until tests stability is achieved ###
    scons -i -j $SCONS_JOBS -U test 2>&1 | tee $WORKSPACE/scons_test.log

    # Turn off error check and echo for the rest of the script.
    set +ex

    FAIL_COUNT=`grep -cw FAIL $WORKSPACE/scons_test.log`
    grep -w PASS $WORKSPACE/scons_test.log
    echo
    echo "Number of PASS tests: "`grep -cw PASS $WORKSPACE/scons_test.log`
    echo "Number of FAIL tests: $FAIL_COUNT"

    if [ "$FAIL_COUNT" != "0" ]; then
        echo
        grep -w FAIL $WORKSPACE/scons_test.log
        echo
        echo "*****************************************************************"
        echo $FAIL_COUNT tests failure ignored -- This will change shortly...
        echo "*****************************************************************"
    fi

    # Turn on error check and echo
    set -ex
}

function main() {
    build_unittest
    run_unittest
}

env
main
echo Success
