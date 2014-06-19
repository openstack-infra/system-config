#!/usr/bin/env bash

set -o pipefail
set -ex

export WORKSPACE=$PWD
SKIP_JOBS=$WORKSPACE/skip_jobs
if [ -f $SKIP_JOBS ]; then
    echo Jobs skipped due to jenkins.opencontrail.org:/root/ci-test/skip_jobs
    exit
fi

if [ -z $SCONS_JOBS ]; then
    export SCONS_JOBS=1
fi

if [ -z $USER ]; then
    USER=jenkins
fi

# Build unittests
function build_unittest() {
    # Goto the repo top directory.
    cd $WORKSPACE/repo

    # Build every thing.
    export BUILD_ONLY=TRUE
    scons -j $SCONS_JOBS . 2>&1 | tee $WORKSPACE/scons_build.log
    # scons -j $SCONS_JOBS test 2>&1 | tee $WORKSPACE/scons_build.log

    unset BUILD_ONLY
}

function print_test_results() {

    # Turn off error check and echo for the rest of the script.
    set +ex

    grep -w FAIL $WORKSPACE/scons_test.log > $WORKSPACE/scons_failed_unittests.log
    FAIL_COUNT=`cat $WORKSPACE/scons_failed_unittests.log | wc -l`
    grep -w PASS $WORKSPACE/scons_test.log
    echo
    echo "Number of PASS tests: "`grep -cw PASS $WORKSPACE/scons_test.log`
    echo "Number of FAIL tests: $FAIL_COUNT"

    if [ "$FAIL_COUNT" != "0" ]; then
        echo
        cat $WORKSPACE/scons_failed_unittests.log
        echo
        echo "*****************************************************************"
        echo $FAIL_COUNT tests failure ignored -- This will change shortly...
        echo "*****************************************************************"
    fi

    # Maintain a consolidated list of failed tests in jenkins master.
    cp $WORKSPACE/scons_failed_unittests.log $WORKSPACE/scons_all_failed_unittests.log
    ssh 148.251.110.18 cat /root/ci-test/scons_all_failed_unittests.log  >> $WORKSPACE/scons_all_failed_unittests.log
    perl -ni -e 's/.*\/repo\/build\///g; print $_;' $WORKSPACE/scons_all_failed_unittests.log
    sort -u $WORKSPACE/scons_all_failed_unittests.log > $WORKSPACE/scons_all_failed_unittests2.log
    mv $WORKSPACE/scons_all_failed_unittests2.log scons_all_failed_unittests.log
    scp -q $WORKSPACE/scons_all_failed_unittests.log 148.251.110.18:/root/ci-test/scons_all_failed_unittests.log

    TOTAL_FAIL_COUNT=`cat $WORKSPACE/scons_all_failed_unittests.log | wc -l`
    echo
    echo
    echo "*******************************************************************"
    echo Aggregate stats from other runs for failed tests: $TOTAL_FAIL_COUNT
    echo "*******************************************************************"
    ssh 148.251.110.18 cat /root/ci-test/scons_all_failed_unittests.log
    echo "*******************************************************************"

    # Turn on error check and echo
    set -ex
}

# Run unittests
function run_unittest() {
    # Goto the repo top directory.
    cd $WORKSPACE/repo

    ### Ignore test failures until tests stability is achieved ###
    scons -i -j $SCONS_JOBS test 2>&1 | tee $WORKSPACE/scons_test.log

    print_test_results
}

function test_wait() {
    while :
    do
        echo Sleeping until /root/ci_job_wait is gone
        if [ ! -f /root/ci_job_wait ]; then
            break
        fi
        sleep 10
    done
}

function ci_cleanup() {
    test_wait
    rm -rf $WORKSPACE/* $WORKSPACE/.* 2>/dev/null || true
    echo Success
    exit
}

function main() {
    build_unittest
    run_unittest
    print_test_results
    ci_cleanup
}

env
main
