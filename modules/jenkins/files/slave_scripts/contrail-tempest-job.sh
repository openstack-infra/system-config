#!/usr/bin/env bash

SSH_ENV="$HOME/.ssh/environment"

#echo "GERRIT_REFSPEC=$GERRIT_REFSPEC"
#echo "GERRIT_REFSPEC=$GERRIT_PATCHSET_REVISION"
#echo "BUILD_NUMBER=$BUILD_NUMBER"

ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
if [ $? -eq 0 ]; then
    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
    ssh-add
fi

ssh jenkins@10.84.35.154  "bash -x contrail-devstack-job.sh $GERRIT_REFSPEC $GERRIT_PATCHSET_REVISION $BUILD_NUMBER"

