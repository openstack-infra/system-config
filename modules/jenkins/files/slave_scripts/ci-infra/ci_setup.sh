#!/usr/bin/env bash

# This file does the initial setup for each jenkins job triggered by CI.
# This checkout 'master' branch code it@github.com:juniper/contrail-infra-config.git
# Quite useful for testing, and also prevents repeated re-imaging of the slave
# VMs when script changes.

# In order to skip runs, do touch /root/ci-test/skip_jobs in
# jenkins.opencontrail.org

BRANCH=master
HOSTNAME=`cat /etc/hostname`

# Check if 'test' branch has to be used (For CI testing)
ssh root@jenkins.opencontrail.org ls /root/ci-test/\*$HOSTNAME\*-test
if [ "$?" == "0" ]; then
    BRANCH=test
fi

# Copy slave scripts from the jenkins.opencontrail.org central master location.
rm -rf /usr/local/jenkins/slave_scripts /root/contrail-infra-config
ln -sf /root/contrail-infra-config/modules/jenkins/files/slave_scripts /usr/local/jenkins/slave_scripts
git clone -b $BRANCH git@github.com:juniper/contrail-infra-config.git /root/contrail-infra-config
# ssh root@$SLAVE_MASTER -p $PORT tar zcf - /usr/local/jenkins/slave_scripts | tar -zx -C /

export WORKSPACE=$PWD
SKIP_JOBS=$WORKSPACE/skip_jobs

# Check if this run needs to be skipped.
ssh root@jenkins.opencontrail.org ls /root/ci-test/skip_jobs
if [ "$?" == "0" ]; then
    echo Jobs skipped due to jenkins.opencontrail.org:/root/ci-test/skip_jobs
    touch $SKIP_JOBS
    exit 0
fi

# Remove stale skip_jobs settings.
rm -rf $SKIP_JOBS
