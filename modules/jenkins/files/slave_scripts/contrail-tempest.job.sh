#!/usr/bin/env bash

Q_PORT=9696
PATCH_DIR=/opt/stack/neutron
NEUTRON_BIN_DIR=/opt/stack/neutron/bin
NEUTRON_CONF=/etc/neutron/neutron.conf
Q_PLUGIN_CONF_FILE=etc/neutron/plugins/opencontrail/contrailplugin.ini
CFG_FILE_OPTIONS="--config-file $NEUTRON_CONF --config-file /$Q_PLUGIN_CONF_FILE"
# $GERRIT_REFSPEC
GERRIT_REFSPEC=$1
GERRIT_PATCHSET_REVISION=$2
BUILD_NUMBER=$3

echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
echo "GERRIT_REFSPEC=$GERRIT_PATCHSET_REVISION"
echo "BUILD_NUMBER=$BUILD_NUMBER"

DEVSTACK_IP_ADDR=10.84.35.154

pushd /home/jenkins/devstack
. /home/jenkins/devstack/localrc

. /home/jenkins/devstack/functions
popd

ret=0

ps aux |  awk ' /neutron-server/ { print $2 } ' | xargs sudo kill -9

rm -rf ${PATCH_DIR}
git clone https://git.openstack.org/openstack/neutron.git ${PATCH_DIR}

pushd ${PATCH_DIR}
git fetch https://review.openstack.org/openstack/neutron ${GERRIT_REFSPEC} && git checkout FETCH_HEAD

popd

pushd /home/jenkins/devstack/
SCREEN_NAME=${SCREEN_NAME-stack}

screen -S $SCREEN_NAME -p  q-svc -X stuff $'cd /opt/stack/neutron && python /usr/local/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/opencontrail/contrailplugin.ini & echo $! >/opt/stack/status/stack/q-svc.pid; fg || echo "q-svc failed to start" | tee "/opt/stack/status/stack/q-svc.failure"\r'

SERVICE_TIMEOUT=${SERVICE_TIMEOUT-6}
SERVICE_HOST=${SERVICE_HOST-localhost}
echo "Waiting for Neutron to start..."
echo if ! timeout $SERVICE_TIMEOUT sh -c "while ! wget --no-proxy -q -O- http://${SERVICE_HOST}:${Q_PORT}; do sleep 1; done"
if ! timeout $SERVICE_TIMEOUT sh -c "while ! wget --no-proxy -q -O- http://${SERVICE_HOST}:${Q_PORT}; do sleep 1; done"; then
    ret=1
fi

popd

if [ $ret -eq 0 ] ; then
	#ssh to DEVSTACK_IP_ADDR and run tempest tests
	pushd  /opt/stack/tempest
	> tempest.log
	bash -x ./verify.sh
	ret=$?
	popd
fi

# Create Log Directory based on jenkins build_id
LOGDIR=/var/lib/jenkins/userContent/${BUILD_NUMBER}
ssh -i ~/.ssh/id_rsa root@jenkins.opencontrail.org "mkdir -p ${LOGDIR} && cp /var/lib/jenkins/jobs/Contrail\\ Neutron\\ Openstack\\ Third\\ Party\\ Testing/builds/${BUILD_NUMBER}/log ${LOGDIR}/console.log"

# Copy logs
FILES=" \
/opt/stack/tempest/tempest.log \
/opt/stack/tempest/etc/tempest.conf \
/home/jenkins/devstack/localrc \
/home/jenkins/devstack/log/stack.log.summary \
/home/jenkins/devstack/log/stack.log \
/home/jenkins/list_tests.txt \
/home/jenkins/contact.txt \
"
#mkdir -p /home/jenkins/tempest.ci/${BUILD_NUMBER}
#for x in $FILES; do
#   rx=$( readlink $x )
#   [ -n $rx ] || x=$rx
#   d=$( dirname $x )
#   y=$( basename $x )
#   pushd $d
#   tar czvf /home/jenkins/tempest.ci/${BUILD_NUMBER}/${y}.tar.gz $y;
#   popd
#done
scp -r -i ~/.ssh/id_rsa $FILES root@jenkins.opencontrail.org:${LOGDIR}

# send response to Gerrit based along with log link

url="http://jenkins.opencontrail.org/userContent/${BUILD_NUMBER}"

if [ $ret -eq 1 ] ; then
    log_url=" Contrail third party testing FAILED [ ${url} ]"
    verf="--verified=-1"
else
    log_url=" Contrail third party testing PASSED [ ${url} ]"
    verf="--verified=+1"
fi

gerrit_cmd="ssh -i ~/.ssh/id_rsa-r -p 29418 contrail@localhost gerrit review -m "

echo "${gerrit_cmd} ${log_url} ${verf} ${GERRIT_PATCHSET_REVISION}"
#print gerrit_cmd_list
#call(gerrit_cmd_list)

bash -c "${gerrit_cmd} \\\"${log_url}\\\" ${verf} ${GERRIT_PATCHSET_REVISION}"

