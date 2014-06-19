#!/usr/bin/env bash

# DEVSTACK
Q_PORT=9696
PATCH_DIR=/opt/stack/neutron
NEUTRON_CONF=/etc/neutron/neutron.conf
Q_PLUGIN_CONF_FILE=etc/neutron/plugins/opencontrail/contrailplugin.ini
CFG_FILE_OPTIONS="--config-file $NEUTRON_CONF --config-file /$Q_PLUGIN_CONF_FILE"

# GERRIT
GERRIT_REFSPEC=$1
GERRIT_PATCHSET_REVISION=$2
BUILD_NUMBER=$3

#JENKINS
JENKINS_SERVER=jenkins.opencontrail.org

echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
echo "GERRIT_REFSPEC=$GERRIT_PATCHSET_REVISION"
echo "BUILD_NUMBER=$BUILD_NUMBER"

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
	pushd  /opt/stack/tempest
	> tempest.log
	bash -x ./verify.sh
	ret=$?
	popd
fi

# Create Log Directory based on jenkins build_id
UPLOAD_DIR=/var/lib/jenkins/userContent/${BUILD_NUMBER}
LOG_DIR=${UPLOAD_DIR}/logs
CONF_DIR=${UPLOAD_DIR}/config
ssh -i ~/.ssh/id_rsa root@${JENKINS_SERVER} "mkdir -p ${LOG_DIR} && mkdir -p ${CONF_DIR} && cp /var/lib/jenkins/jobs/Contrail\\ Neutron\\ Openstack\\ Third\\ Party\\ Testing/builds/${BUILD_NUMBER}/log ${UPLOAD_DIR}/console.log"

# Copy logs
LOG_FILES=" \
/opt/stack/tempest/tempest.log \
/opt/stack/tempest/results.html \
/home/jenkins/devstack/log/stack.log \
/home/jenkins/devstack/log/screens \
"
CONF_FILES=" \
/opt/stack/tempest/etc/tempest.conf \
/etc/neutron/ \
/etc/nova/ \
"

scp -r -i ~/.ssh/id_rsa $LOG_FILES root@${JENKINS_SERVER}:${LOG_DIR}
scp -r -i ~/.ssh/id_rsa $CONF_FILES root@${JENKINS_SERVER}:${CONF_DIR}
scp -r -i ~/.ssh/id_rsa /home/jenkins/devstack/localrc root@${JENKINS_SERVER}:${LOG_DIR}/localrc.txt
scp -r -i ~/.ssh/id_rsa /home/jenkins/contact.txt root@${JENKINS_SERVER}:${UPLOAD_DIR}/
scp -r -i ~/.ssh/id_rsa /home/jenkins/devstack/log/stack.log.summary root@${JENKINS_SERVER}:${LOG_DIR}/stack.log.summary.txt

# send response to Gerrit based along with log link

url="http://${JENKINS_SERVER}/userContent/${BUILD_NUMBER}"

if [ $ret -eq 1 ] ; then
    log_url=" Contrail third party testing FAILED [ ${url} ]"
    verf="--verified=-1"
else
    log_url=" Contrail third party testing PASSED [ ${url} ]"
    verf="--verified=+1"
fi

gerrit_cmd="ssh -i ~/.ssh/id_rsa-r -p 29418 contrail@review.openstack gerrit review -m "

echo "${gerrit_cmd} ${log_url} ${verf} ${GERRIT_PATCHSET_REVISION}"

#bash -c "${gerrit_cmd} \\\"${log_url}\\\" ${verf} ${GERRIT_PATCHSET_REVISION}"

