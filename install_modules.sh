#!/bin/bash

if ! puppet help module >/dev/null 2>&1 ; then
    apt-get install -y -o Dpkg::Options::="--force-confold" puppet facter
fi

MODULES="puppetlabs-apt puppetlabs-mysql puppetlabs-dashboard puppetlabs-vcsrepo"
MODULE_LIST=`puppet module list`

for MOD in $MODULES ; do
  if ! echo $MODULE_LIST | grep $MOD >/dev/null 2>&1 ; then
    # This will get run in cron, so silence non-error output
    puppet module install $MOD >/dev/null
  fi
done

# Fix a problem with the released verison of the dashboard module
if grep scope.lookupvar /etc/puppet/modules/dashboard/templates/passenger-vhost.erb | grep dashboard_port >/dev/null 2>&1 ; then

  cd /etc/puppet/modules/dashboard
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
