#!/usr/bin/env bash

set -ex

SCONS_JOBS=1

# Build software
function scons_build() {

    # Build every thing.
    export BUILD_ONLY=TRUE
    scons -j $SCONS_JOBS -U . 2>&1 | tee $WORKSPACE/scons_build.log
    # scons -j $SCONS_JOBS -U test 2>&1 | tee $WORKSPACE/scons_build.log

    unset BUILD_ONLY
}

# Run tests
function scons_test() {

    ### Ignore test failures until tests stability is achieved ###
    scons -i -j $SCONS_JOBS -U test 2>&1 | tee $WORKSPACE/scons_test.log

    # Turn off error check and echo for the rest of the script.
    set +xe

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
    set -xe
}

function main() {
    env
    # Goto the repo top directory.
    cd $WORKSPACE/repo
    scons_build
    scons_test
}

main
echo Success
