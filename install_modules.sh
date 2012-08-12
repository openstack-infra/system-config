#!/bin/bash

MODULE_PATH=/etc/puppet/modules

function clone_git() {
    REMOTE_URL=$1
    REPO=$2
    REV=$3

    if [ -d $MODULE_PATH/$REPO -a ! -d $MODULE_PATH/$REPO/.git ] ; then
        rm -rf $MODULE_PATH/$REPO
    fi
    if [ ! -d $MODULE_PATH/$REPO ] ; then
        git clone $REMOTE_URL $MODULE_PATH/$REPO
    fi
    OLDDIR=`pwd`
    cd $MODULE_PATH/$REPO
    if ! git rev-parse HEAD | grep "^$REV" >/dev/null; then
      git fetch $REMOTE_URL
      git reset --hard $REV >/dev/null
    fi
    cd $OLDDIR
}

if ! puppet help module >/dev/null 2>&1 ; then
    apt-get install -y -o Dpkg::Options::="--force-confold" puppet facter
fi

MODULES="puppetlabs-apt puppetlabs-mysql openstackci-dashboard openstackci-vcsrepo rodjek-logrotate"
MODULE_LIST=`puppet module list`

# Transition away from old things
if [ -d /etc/puppet/modules/vcsrepo/.git ] ; then
    rm -rf /etc/puppet/modules/vcsrepo
fi

for MOD in $MODULES ; do
  if ! echo $MODULE_LIST | grep $MOD >/dev/null 2>&1 ; then
    # This will get run in cron, so silence non-error output
    puppet module install --force $MOD >/dev/null
  fi
done
