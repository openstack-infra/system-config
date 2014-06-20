#
# Setup devstack for tempest run
#
DEVSTACK_DIR=/home/jenkins/devstack
DEVSTACK_LOG_DIR=${DEVSTACK_DIR}/log/
TEMPEST_DIR=/opt/stack/tempest

GERRIT_REFSPEC=$1
#echo ${GERRIT_REFSPEC}

# First cleanup devstack if present 
if [ -d "${DEVSTACK_DIR}" ]; then
  pushd ${DEVSTACK_DIR}
  # cleanup devstack
  ./unstack.sh
  # remove logs
  rm -rf $DEVSTACK_LOG_DIR/stack*
  rm -rf $DEVSTACK_LOG_DIR/screen/*
  popd
else
  # Clone devstack
  git clone https://github.com/dsetia/devstack.git ${DEVSTACK_DIR}
  # copy and fix localrc
  cp devstack/contrail/localrc-ci devstack/localrc
  python fix_localrc.py
fi

#
# download neutron as we need our patch applied before we can run ./stack.sh
#

# make sure directory is there ...
sudo mkdir -p /opt/stack/
# with the right owner:group
sudo chown jenkins:root /opt/stack

# remove tempest dir
rm -rf ${TEMPEST_DIR}

# Clone neutron and apply our patch
PATCH_DIR=/opt/stack/neutron
rm -rf ${PATCH_DIR}
git clone https://git.openstack.org/openstack/neutron.git ${PATCH_DIR}
pushd ${PATCH_DIR}
git fetch https://review.openstack.org/openstack/neutron ${GERRIT_REFSPEC} && git checkout FETCH_HEAD
popd

# Run devstack now
pushd ${DEVSTACK_DIR}
./stack.sh
popd
