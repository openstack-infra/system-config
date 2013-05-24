:title: Planet

Planet
######

The `Planet Venus
<http://intertwingly.net/code/venus/docs/index.html>`_ blog aggregator
is installed on planet.openstack.org.

Planet Venus works by having a cron job which creates static files.
In our configuration, the static files are served using Apache.

The puppet module is configured to use the openstack/planet git
repository to provide the ``planet.ini`` configuration file.
