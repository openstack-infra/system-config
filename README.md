test.
These are a set of puppet manifests and modules that are currently being
used to manage some of the efforts of the OpenStack CI project. They are
quite bare and crappy at the moment, but should grow soon.

Additionally, there is a script, make_puppet_lp.py which is used to generate
a few lists of users from launchpad teams, to make management and population
of user accounts on different types of servers easier.

There are currently two different entry points, the slave.pp and the
server.pp manifest.

slave.pp is intended to be for jenkins slaves and adds all members of
~openstack-ci-admins

server.pp is intended as the base for other servers and adds members of
~openstack-admins

Puppet needs to be installed via gems, because we use the pip package
provider for one of the packages and that is only in 2.7.

For instance:

/var/lib/gems/1.8/bin/puppet apply --modulepath=`pwd`/modules manifests/slave.pp

or

/var/lib/gems/1.8/bin/puppet apply --modulepath=`pwd`/modules manifests/server.pp
