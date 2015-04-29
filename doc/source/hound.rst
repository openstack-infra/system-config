:title: Hound

.. _hound:

Hound
#####

Hound is installed on hound.openstack.org and provides code indexing and search
across all of the repositories hosted in the OpenStack Infra systems.

At a Glance
===========

:Hosts:
  * http://hound.openstack.org
:Puppet:
  * :file:`modules/openstack_project/manifests/hound.pp`
:Projects:
  * https://github.com/etsy/Hound
:Bugs:
  * https://github.com/etsy/Hound/issues

Overview
========

Apache is configured as a reverse proxy. There is no precious data.

There is a jeepyb script, `create-hound-config` that transforms a
`projects.yaml` file into `/home/hound/config.json`. When it is updated,
hound is restarted. On starting, hound starts a searcher thread for every
repo in config.json, and will cache the repo and index data in
`/home/hound/data`.
