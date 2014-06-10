#!/usr/bin/env bash

#echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
#echo "GERRIT_REFSPEC=$GERRIT_PATCHSET_REVISION"
#echo "BUILD_NUMBER=$BUILD_NUMBER"

scp /usr/local/jenkins/slave_scripts/contrail-tempest-devstack-job.sh jenkins@localhost:
ssh jenkins@localhost  "bash -x contrail-tempest-devstack-job.sh $GERRIT_REFSPEC $GERRIT_PATCHSET_REVISION $BUILD_NUMBER"

