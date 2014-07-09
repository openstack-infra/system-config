#!/bin/bash -xe

# NOTE(dhellmann): The variables defined here are exported so they are
# visible inside the shell function defined below that is in turn
# executed in a sub-shell when safe-devstack-vm-gate.sh runs at the
# end of this file. The alternative was to place the body of this
# script in the jjb input file where jjb could expand values directly
# inside the function definition, but doing it this way makes it
# possible for someone to run the script by hand for local testing.

# The location of this script, so we can find other scripts we know
# are delivered with us.
export scriptbindir=$(dirname $0)

# The virtualenv name to use with tox.
export venv=$1

# The github-org for the project.
export org=$2

# The project name.
export project=$3

# Derive the version argument to run-unittests.sh from the venv.
export version=$(echo $venv | sed -e 's/^py//')
# Make sure the governance repository is checked out.
export PROJECTS="openstack/governance $PROJECTS"

# Set up variables to be used to find the current list of Oslo
# projects.
export PROGRAMS_FILE=/opt/stack/new/governance/reference/programs.yaml
# FIXME(dhellmann): This will need to be updated for python 3.
export REQUIREMENTS_FILES="
    /opt/stack/new/$project/requirements.txt
    /opt/stack/new/$project/test-requirements.txt
    "

function gate_hook {
    set -x

    remaining_time

    # Move to the directory of the project under test.
    cd /opt/stack/new/$project

    # Build the virtualenv without running the tests.
    timeout -s 9 ${REMAINING_TIME}m $scriptbindir/run-tox.sh $venv $org $project --notest

    # Figure out which Oslo libraries the project uses.
    oslo_libs="$($scriptbindir/list-oslo-dependencies.py $PROGRAMS_FILE $REQUIREMENTS_FILES)"
    if [ -z "$oslo_libs" ]
    then
        echo "ERROR: Could not determine Oslo library dependencies"
        return 1
    fi

    # Replace the copies of the Oslo libraries already installed with
    # the one checked out in the local repository.
    PIP=/opt/stack/new/$project/.tox/$venv/bin/pip
    for lib in $oslo_libs
    do
        libdir=/opt/stack/new/$lib
        if [ -d $libdir  ]
        then
            echo "Replacing $lib with copy from $libdir"
            $PIP uninstall -y ${lib}
            (cd $libdir && $PIP install .)
        fi
    done

    # Re-run tox to run the tests.
    timeout -s 9 ${REMAINING_TIME}m $scriptbindir/run-unittests.sh $version $org $project
}
export -f gate_hook

function post_test_hook {
    cd /opt/stack/new/$project
    mv nose_results.html $WORKSPACE/logs
    mv testr_results.html.gz $WORKSPACE/logs
    mv .testrepository/tmp* $WORKSPACE/logs
    mv subunit_log.txt.gz $WORKSPACE/logs
}
export -f post_test_hook

cp devstack-gate/devstack-vm-gate-wrap.sh ./safe-devstack-vm-gate-wrap.sh
./safe-devstack-vm-gate-wrap.sh
