:title: Translate

.. _translate:

Translate
#########

As of the Liberty release, translations for various projects in OpenStack are
done on the Zanata translations platform.

At a Glance
===========

:Hosts:
  * https://translate.openstack.org
  * https://translate-dev.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-zanata/tree/
  * :file:`modules/openstack_project/manifests/translate.pp`
  * :file:`modules/openstack_project/manifests/translate-dev.pp`
:Projects:
  * http://zanata.org/
  * https://github.com/zanata/
:Bugs:
  * https://zanata.atlassian.net/projects/ZNTA/issues/

Overview
========

The OpenStack Infrastructure runs a production instance and a development
instance of Zanata running on the `Wildfly JBoss Application Server
<http://wildfly.org/>`_. Upgrades must be tested on the development server
before being applied in production.

Translators work through the Zanata web UI or with the zanata-cli tool to do
their translations. A series of Zuul jobs handle translations proposals
on the proposal slave.

Projects are added for translations by
modifying :config:`gerrit/projects.yaml` and adding the following to
the project::

  options:
    - translate

Projects are then registered with Zanata with the register-zanata-projects.py
from :ref:`jeepyb`, this is run when :config:`gerrit/projects.yaml`
changes.

Finally, the translations jobs must be added to the project in
:config:`jenkins/jobs/projects.yaml` and :config:`zuul/layout.yaml`.
