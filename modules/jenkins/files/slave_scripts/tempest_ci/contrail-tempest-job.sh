#!/usr/bin/env bash

GERRIT_REFSPEC=${GERRIT_REFSPEC-refs/changes/30/96630/21}
GERRIT_PATCHSET_REVISION=${GERRIT_PATCHSET_REVISION-fc71a70dd7e654515693b00e8f42e92105484381}
BUILD_NUMBER=${BUILD_NUMBER-999999}

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
ssh jenkins@localhost  "bash -x contrail-devstack-setup.sh $GERRIT_REFSPEC"

# setup tempest for a run
scp /usr/local/jenkins/slave_scripts/tempest_ci/tempest_setup.py jenkins@localhost:
ssh jenkins@localhost  "python tempest_setup.py"

# apply patch and run tempest
scp /usr/local/jenkins/slave_scripts/tempest_ci/contrail-tempest-devstack-job.sh jenkins@localhost:
scp /usr/local/jenkins/slave_scripts/tempest_ci/verify.sh jenkins@localhost:/opt/stack/tempest/
cp /usr/local/jenkins/slave_scripts/tempest_ci/subunit2html /usr/local/bin/
chmod 755 /usr/local/bin/subunit2html
ssh jenkins@localhost  "bash -x contrail-tempest-devstack-job.sh $GERRIT_REFSPEC $GERRIT_PATCHSET_REVISION $BUILD_NUMBER"

