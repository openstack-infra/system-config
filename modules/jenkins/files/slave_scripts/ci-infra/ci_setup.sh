#!/usr/bin/env bash

BRANCH=master
HOSTNAME=`cat /etc/hostname`
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

rm -rf $SKIP_JOBS
