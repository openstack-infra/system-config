#!/usr/bin/env bash

# TODO Ignore failures temporarily
set -o pipefail
set +e
set -x

export WORKSPACE=$PWD
SKIP_JOBS=$WORKSPACE/skip_jobs
if [ -f $SKIP_JOBS ]; then
    echo Jobs skipped due to jenkins.opencontrail.org:/root/ci-test/skip_jobs
    exit
fi

export USER=jenkins
export CONTRAIL_REPO_SYNC_SKIP=TRUE
export PHYSICAL_INTERFACE=eth0
export CONTRAIL_SRC=$WORKSPACE/repo
export DEVSTACK_WORKSPACE=$WORKSPACE/devstack

# Run devstack
# TODO Ignore failures temporarily
function run_devstack() {
    set +e
    set -x

    apt-get --fix-missing update

    rm -rf $DEVSTACK_WORKSPACE
    mkdir -p $DEVSTACK_WORKSPACE
    cd $DEVSTACK_WORKSPACE

    git clone git@github.com:rombie/devstack.git .

    pwd
    # Update environment variables contrainer localrc.
    cp $DEVSTACK_WORKSPACE/contrail/localrc-single $DEVSTACK_WORKSPACE/localrc
    perl -ni -e 's/PHYSICAL_INTERFACE=.*/PHYSICAL_INTERFACE=eth0/g; print $_;' $DEVSTACK_WORKSPACE/localrc
    perl -ni -e 's/.*GIT_BASE=.*/GIT_BASE=https:\/\/git.openstack.org/g; print $_;' $DEVSTACK_WORKSPACE/localrc
    perl -ni -e 's/.*CONTRAIL_REPO=.*/CONTRAIL_REPO=devstack.xml; print $_;' $DEVSTACK_WORKSPACE/localrc
    echo CONTRAIL_REPO_SYNC_SKIP=TRUE >> $DEVSTACK_WORKSPACE/localrc
    echo CONTRAIL_SRC=$WORKSPACE/repo >> $DEVSTACK_WORKSPACE/localrc

    rm -rf /opt/stack/contrail
    ln -sf $WORKSPACE/repo /opt/stack/contrail
    chown -R $USER.$USER $WORKSPACE

    rm -rf /etc/contrail
    mkdir -p /etc/contrail
    chown $USER /etc/contrail

    mkdir -p /opt/stack/neutron
    cp /home/jenkins/tmp/cache/jenkins/third_party/node-v0.8.15.tar.gz /opt/stack/neutron/.
    chown -R $USER /opt/stack/
    su -c $DEVSTACK_WORKSPACE/stack.sh $USER
    /usr/bin/contrail-status
    /usr/bin/openstack-status
}

function main() {
    # Run devstack as $USER (not root)
    # export -f run_devstack

    # TODO Ignore failures for now.
    run_devstack

    su -c $DEVSTACK_WORKSPACE/unstack.sh $USER
}

# env
main
echo Success
