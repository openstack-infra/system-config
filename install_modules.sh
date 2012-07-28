#!/bin/bash

MODULES="puppetlabs-mysql puppetlabs-vcsrepo"
MODULE_LIST=`puppet module list`

for MOD in $MODULES ; do
  if ! echo $MODULE_LIST | grep $MOD >/dev/null 2>&1 ; then
    # This will get run in cron, so silence non-error output
    puppet module install $MOD >/dev/null
  fi
done
