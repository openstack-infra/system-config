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
