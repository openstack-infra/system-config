#!/usr/bin/env bash

# TODO Ignore failures temporarily
set +e
set -x

if [ -z $USER ]; then
    USER=jenkins
fi

export WORKSPACE=$PWD
export CONTRAIL_REPO_SYNC_SKIP=TRUE
export PHYSICAL_INTERFACE=eth0
export CONTRAIL_SRC=$WORKSPACE/repo

# Build devstack
function setup_devstack() {
    export DEVSTACK_WORKSPACE=$WORKSPACE/devstack

    # Setup cache
    rm -rf /tmp/cache
    ln -sf /home/$USER/tmp/cache /tmp/cache

    rm -rf $DEVSTACK_WORKSPACE
    mkdir -p $DEVSTACK_WORKSPACE
    chown $USER.$USER $DEVSTACK_WORKSPACE
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

    $DEVSTACK_WORKSPACE/stack.sh
}

function main() {
    setup_devstack

    # Run devstack as $USER (not root)
    export -f run_devstack
    export HOME=/home/$USER

    # TODO Ignore failures for now.
    su -mc run_devstack $USER
    su -mc $DEVSTACK_WORKSPACE/unstack.sh $USER
}

# env
main
echo Success
