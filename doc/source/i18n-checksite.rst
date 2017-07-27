:title: I18n-checksite

.. _i18n-checksite:

I18n-Checksite
##############

As of the Liberty release, translations for various projects in OpenStack are
done on the Zanata translations platform.

At a Glance
===========

:Hosts:
  * https://i18n-checksite.openstack.org
  * http://i18n-checksite.openstack.org
:Projects:
  * https://docs.openstack.org/openstack-ansible/
:Bugs:
  * https://bugs.launchpad.net/openstack-ansible

Overview
========

The OpenStack Infrastructure runs a production instance of OpenStack 
Ansibe All-in-One (OSA) with extension of translation check site.
Translated strings will be periodically fetched from translation
platform and built in Horizon.

Translators are able to check translated strings in a real environment
to keep the phrases in the right context.

Installation of OSA will done by ansible playbook
remote_puppet_i18n-checksite.yaml manually.
