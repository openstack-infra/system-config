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
    (cd $MODULE_PATH/$REPO &&
      git fetch origin &&
      git reset --hard $REV >/dev/null )
}

if ! puppet help module >/dev/null 2>&1 ; then
    apt-get install -y -o Dpkg::Options::="--force-confold" puppet facter
fi

MODULES="puppetlabs-apt puppetlabs-mysql puppetlabs-dashboard"
MODULE_LIST=`puppet module list`

for MOD in $MODULES ; do
  if ! echo $MODULE_LIST | grep $MOD >/dev/null 2>&1 ; then
    # This will get run in cron, so silence non-error output
    puppet module install $MOD >/dev/null
  fi
done

# Install vcsrepo from git
clone_git git://github.com/puppetlabs/puppetlabs-vcsrepo.git vcsrepo f3acccdf

# Fix a problem with the released verison of the dashboard module
if grep scope.lookupvar ${MODULE_PATH}/dashboard/templates/passenger-vhost.erb | grep dashboard_port >/dev/null 2>&1 ; then

  cd ${MODULE_PATH}/dashboard
  echo | patch -p1 <<'EOD'
diff --git a/templates/passenger-vhost.erb b/templates/passenger-vhost.erb
index a2f6d16..de7dd0a 100644
--- a/templates/passenger-vhost.erb
+++ b/templates/passenger-vhost.erb
@@ -1,6 +1,6 @@
-Listen <%= scope.lookupvar("dashboard::params::dashboard_port") %>
+Listen <%= dashboard_port %>
 
-<VirtualHost *:<%= scope.lookupvar("dashboard::params::dashboard_port") %>>
+<VirtualHost *:<%= dashboard_port %>>
   ServerName <%= name %>
   DocumentRoot <%= docroot %>
   RailsBaseURI <%= rails_base_uri %>
EOD
fi
