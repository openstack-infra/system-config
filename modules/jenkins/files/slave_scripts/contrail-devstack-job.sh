#!/usr/bin/env bash

# TODO Ignore failures temporarily
set -o pipefail
set +e
set -x

export USER=jenkins
export WORKSPACE=$PWD
export CONTRAIL_REPO_SYNC_SKIP=TRUE
export PHYSICAL_INTERFACE=eth0
export CONTRAIL_SRC=$WORKSPACE/repo

# Build devstack
function setup_devstack() {
    export DEVSTACK_WORKSPACE=$WORKSPACE/devstack

    rm -rf $DEVSTACK_WORKSPACE
    mkdir -p $DEVSTACK_WORKSPACE
    chown -R $USER.$USER $WORKSPACE
    chown -R $USER.$USER $CONTRAIL_SRC

    # rm -rf /opt/stack
    # mkdir -p /opt/stack
    # chown $USER.$USER /opt/stack
}

# Run devstack
# TODO Ignore failures temporarily
function run_devstack() {
    set +e
    set -x
    cd $DEVSTACK_WORKSPACE

    git clone git@github.com:rombie/devstack.git .

    pwd
    # Update environment variables contrainer localrc.
    cp $DEVSTACK_WORKSPACE/contrail/localrc-single $DEVSTACK_WORKSPACE/localrc
    perl -ni -e 's/PHYSICAL_INTERFACE=.*/PHYSICAL_INTERFACE=eth0/g; print $_;' $DEVSTACK_WORKSPACE/localrc
    perl -ni -e 's/.*GIT_BASE=.*/GIT_BASE=https:\/\/git.openstack.org/g; print $_;' $DEVSTACK_WORKSPACE/localrc
    echo CONTRAIL_REPO_SYNC_SKIP=TRUE >> $DEVSTACK_WORKSPACE/localrc
    echo CONTRAIL_SRC=$WORKSPACE/repo >> $DEVSTACK_WORKSPACE/localrc

    su -c $DEVSTACK_WORKSPACE/stack.sh $USER
}

function main() {
    setup_devstack

    # Run devstack as $USER (not root)
    # export -f run_devstack

    # TODO Ignore failures for now.
    run_devstack

    su -c $DEVSTACK_WORKSPACE/unstack.sh $USER
}

# env
main
echo Success
