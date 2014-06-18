#!/usr/bin/env bash

#echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
#echo "GERRIT_REFSPEC=$GERRIT_PATCHSET_REVISION"
#echo "BUILD_NUMBER=$BUILD_NUMBER"

# install some required packages
# bottle==0.11.6, configparser, 
pip install bottle==0.11.6
pip install configparser

scp /usr/local/jenkins/slave_scripts/tempest_ci/contrail-tempest-devstack-job.sh jenkins@localhost:
scp /usr/local/jenkins/slave_scripts/tempest_ci/contrail-devstack-setup.sh jenkins@localhost:

ssh jenkins@localhost  "bash -x contrail-devstack-setup.sh"
ssh jenkins@localhost  "bash -x contrail-tempest-devstack-job.sh $GERRIT_REFSPEC $GERRIT_PATCHSET_REVISION $BUILD_NUMBER"

