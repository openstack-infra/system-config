:title: Code Search

.. _codesearch:

Code Search
###########

The `Hound <https://github.com/etsy/Hound>`_ code search engine is deployed in
our infrastructure to service all OpenStack repositories.

At a Glance
===========

:Hosts:
  * http://codesearch.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-hound/tree/
  * :file:`modules/openstack_project/manifests/codesearch.pp`
:Projects:
  * https://github.com/etsy/Hound
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://github.com/etsy/Hound/issues
:Resources:
  * `Hound README <https://github.com/etsy/hound/blob/master/README.md>`_

Overview
========

Hound is configured to read projects from a config.json file that is
automatically generated from the Gerrit projects.yaml, defined in the
$::project_config::jeepyb_project_file variable in Puppet.


Maintenance
===========

Hound uses 'git pull' to keep repos in sync. If a force push is ever used to
correct an issue in a repo, then hound will not be able to pull or index those
changes. The only way to detect this is to look in /var/log/hound.log. The
error message looks like hound attempting to update the repo and getting a
'remote host hung up' message. The issue can be corrected by an infra-root
removing the relevant hound data directory. Hound will re-clone with the new
history.
