:title: StoryBoard

StoryBoard
##########

StoryBoard is the task and project tracking system both developed and used by
the OpenStack project. Some projects have already elected to move to
StoryBoard, however it is still considered in limited alpha and is not ready
for production use.

This section describes how StoryBoard is configured for use in the
OpenStack project and the tools used to manage that configuration.

At a Glance
===========

:Hosts:
  * https://storyboard.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-storyboard/tree/
  * :file:`modules/openstack_project/manifests/storyboard.pp`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/storyboard
  * https://git.openstack.org/cgit/openstack-infra/storyboard-webclient
  * https://git.openstack.org/cgit/openstack-infra/puppet-storyboard
:Configuration:
  * :config:`gerrit/projects.yaml`
  * :file:`modules/openstack_project/files/storyboard/superusers.yaml`
:Bugs:
  * https://storyboard.openstack.org/#!/project/456
:Resources:
  * `StoryBoard Documentation <http://ci.openstack.org/storyboard/>`_
  * `StoryBoard Wiki <https://wiki.openstack.org/wiki/StoryBoard>`_
  * `StoryBoard Roadmap <https://wiki.openstack.org/wiki/StoryBoard/Roadmap>`_

Installation
============

StoryBoard is installed and configured by Puppet, using the puppet module
developed for the project.  See :ref:`sysadmin` for how Puppet is used to
manage OpenStack infrastructure systems.

Configuration
=============

The default superusers configuration of StoryBoard is managed from within
infra/system-config. The rest of the configuration is on projects-config.
To add a project, admin, or modify a team, please follow the instructions
below.

Adding a Project to StoryBoard
------------------------------

.. note::
   At this point, only OpenStack Infrastructure projects should be added to
   StoryBoard, as key features such as release versioning are not yet
   implemented.

Projects loaded into StoryBoard are handled from the same file that drives our
gerrit projects. Adding a new project is as simple as modifying a single
file and adding the line ``use-storyboard: true``:

``:config:`gerrit/projects.yaml```::

     - project: openstack-infra/storyboard
       description: OpenStack Task Tracking API
       use-storyboard: true


Adding an Admin to StoryBoard
-----------------------------

StoryBoard administrators are handled from a single configuration file, and
are identified by OpenID. To add a new administator, simply add their
Launchpad OpenID string and email as follows:

``:config:`gerrit/projects.yaml```::

    - openid: https://login.launchpad.net/+id/LOLPONIES
      email: pinkie.pie@example.com


Modifying a Team on StoryBoard
------------------------------

Teams are not yet supported. Stay tuned!
