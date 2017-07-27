:title: GitHub

.. _github:

GitHub
######

GitHub is a code-hosting platform that, while not used for OpenStack
development, is nonetheless frequently enough used by non-OpenStack projects
that OpenStack has tooling interactions with it.

At a Glance
===========

:Hosts:
  * review.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/system-config/tree/
  * :file:`modules/openstack_project/manifests/gerrit.pp`
  * :file:`hiera/fqdn/zuulv3.openstack.org.yaml`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/zuul
  * https://git.openstack.org/cgit/openstack-infra/jeepyb
:Chat:
  * #openstack-infra on freenode

Overview
========

There are currently three different forms of interaction with GitHub.

* Gerrit Replication
* Pull Request Closer
* OpenStack Zuul App

Gerrit Replication
------------------

Each project in gerrit is replicated on merge to a corresponding repository
in GitHub. More information on this can be found in the :ref:`gerrit`
document at :ref:`gerrit_github_integration`.

Pull Request Closer
-------------------

A cronjob is run that looks for Pull Requests that have been erroneously
submitted and closes them with a helpful message pointing people to the
documentation on `Contributing to OpenStack`_. More information on this can
be found in the :ref:`jeepyb` document at :ref:`closing_pull_requests`.

.. _Contributing to OpenStack: http://docs.openstack.org/infra/manual/developers.html#getting-started

.. _openstack_zuul_app:

OpenStack Zuul App
------------------

Zuul v3 is integrated with GitHub by way of a `GitHub App`_. This is done to
enable OpenStack to test integration with external projects that use GitHub
for development. Information on onfiguring projects to use the OpenStack Zuul
App can be found in the :ref:`zuul` page at :ref:`zuul_github_projects`.

The OpenStack Zuul App is managed `OpenStack Zuul Settings Page`_ which is
available to admins of the `openstack-infra Organization`_.

The OpenStack Zuul App has a Private key, a Webhook secret and a set of OAuth
Credentials which are all stored in hiera.

The Private key can only be retrieved when it is generated, so in the case it
is lost a new one must be generated and the resulting value put into hiera.
The Private key is placed into the ``api_token`` field in the ``github``
entry in ``zuul_connection_secrets`` for the ``zuulv3.openstack.org`` FQDN.

GitHub sends JSON payloads via HTTP POST to the URL configured in the Webhook
URL setting. The current value of this setting for Zuul v3 is:
https://zuulv3.openstack.org/connection/github/payload. It includes the
configured "Webhook Secret" so that Zuul can verify that the payload actually
did come from GitHub. The "Webhook Secret" is placed into the ``webhook_token``
field in the ``github`` entry in ``zuul_connection_secrets`` for the
``zuulv3.openstack.org`` FQDN.

The OAuth credentials for the OpenStack Zuul App are currently unused.

.. _GitHub App: https://developer.github.com/apps/
.. _OpenStack Zuul Settings Page: https://github.com/organizations/openstack-infra/settings/apps/openstack-zuul.
.. _openstack-infra Organization: https://github.com/organizations/openstack-infra/settings/profile
