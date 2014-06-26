#!/usr/bin/env bash

set -o pipefail
set -x

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

function archive_failed_test_logs() {
    find $WORKSPACE/repo/build -name "*.log" |\grep -w test | xargs \grep -lw FAILED | xargs tar -zvcf --ignore-failed-read $WORKSPACE/failed_unit_test_logs.tgz
    if [ ! -f $WORKSPACE/failed_unit_test_logs.tgz ]; then
        return
    fi
    if [ -z $BUILD_NUMBER ]; then
        BUILD_NUMBER=0
    fi
    sshpass -p c0ntrail123 ssh ci-admin@ubuntu-build02 \
        mkdir -p /ci-admin/failed_unit_test_logs/$BUILD_NUMBER
    sshpass -p c0ntrail123 scp $WORKSPACE/failed_unit_test_logs.tgz \
        ci-admin@ubuntu-build02:/ci-admin/failed_unit_test_logs/$BUILD_NUMBER/.
    sshpass -p c0ntrail123 ssh ci-admin@ubuntu-build02 \
        tar -C /ci-admin/failed_unit_test_logs/$BUILD_NUMBER/ -zxf \
        /ci-admin/failed_unit_test_logs/$BUILD_NUMBER/failed_unit_test_logs.tgz
}

function print_test_results() {

    # Turn off error check and echo for the rest of the script.
    set +x

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
    set -x
}

# Run unittests
function build_and_run_unittest() {
    # Goto the repo top directory.
    cd $WORKSPACE/repo
    scons -j $SCONS_JOBS test 2>&1 | tee $WORKSPACE/scons_test.log
    exit_code=$?

    # Exit in case of error
    if [ "$exit_code" != "0" ]; then
        ci_exit $exit_code
    fi

    # Flaky test results are ignored.
    scons -j $SCONS_JOBS -i flaky-test 2>&1 | tee -a $WORKSPACE/scons_test.log
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

function ci_exit() {
    exit_code=$1
    if [ -z $exit_code ]; then
        exit_code=0
    fi
    test_wait
    archive_failed_test_logs

    if [ "$exit_code" == "0" ]; then
        rm -rf $WORKSPACE/* $WORKSPACE/.* 2>/dev/null
        echo Success
    else
        echo Exit with failed code $exit_code
        # Leave the workspace intact.
    fi
    exit $exit_code
}

function main() {
    build_and_run_unittest
    print_test_results
    ci_exit
}

env
main
