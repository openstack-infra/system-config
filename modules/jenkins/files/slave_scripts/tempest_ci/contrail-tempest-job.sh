#!/usr/bin/env bash

#echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
#echo "GERRIT_REFSPEC=$GERRIT_PATCHSET_REVISION"
#echo "BUILD_NUMBER=$BUILD_NUMBER"

# install some required packages
#   bottle==0.11.6, configparser, netifaces
pip install bottle==0.11.6
pip install configparser
pip install netifaces

# devtack setup
scp /usr/local/jenkins/slave_scripts/tempest_ci/contrail-devstack-setup.sh jenkins@localhost:
scp /usr/local/jenkins/slave_scripts/tempest_ci/fix_localrc.py jenkins@localhost:
ssh jenkins@localhost  "bash -x contrail-devstack-setup.sh"

# setup tempest for a run
scp /usr/local/jenkins/slave_scripts/tempest_ci/tempest_setup.py jenkins@localhost:
ssh jenkins@localhost  "python tempest_setup.py"

# apply patch and run tempest
scp /usr/local/jenkins/slave_scripts/tempest_ci/contrail-tempest-devstack-job.sh jenkins@localhost:
ssh jenkins@localhost  "bash -x contrail-tempest-devstack-job.sh $GERRIT_REFSPEC $GERRIT_PATCHSET_REVISION $BUILD_NUMBER"

