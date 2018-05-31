:title: Survey

.. _survey:

Survey
######

Survey runs an instance of the LimeSurvey software, an open source survey
tool written in php.

At a Glance
===========

:Hosts:
  * https://survey.openstack.org
:Puppet:
  * file:`modules/openstack_project/manifests/survey.pp`
:Projects:
  * https://www.limesurvey.org/
:Bugs:
  * https://www.limesurvey.org/community/bug-tracker

Overview
========

Apache is used with a Trove backend.

Sysadmin
========

Enable the webserver auth plugin via mysqlclient:

.. code-block:: bash

    insert into plugins (name, active) values ('Authwebserver', 1);

    insert into plugin_settings (plugin_id, plugin_settings.key, plugin_settings.value) values (1, 'strip_domain', '""');
    insert into plugin_settings (plugin_id, plugin_settings.key, plugin_settings.value) values (1, 'serverkey', '"REMOTE_USER"');
    insert into plugin_settings (plugin_id, plugin_settings.key, plugin_settings.value) values (1, 'is_default', '"1"');

Admin sign-in: https://survey.openstack.org/admin

Configuration > Global Settings > Email Settings

    Default site admin email: infra-root@openstack.org

    Administrator name: admin

Configuration > Global Settings > Bounce Settings

    Default site admin email: infra-root@openstack.org

Save and Close
check admin name and email information on front page: survey.openstack.org
to confirm change


Authenticate as an OpenID autocreated user, and then elevate it to a
superadmin via mysqlclient:

.. code-block:: bash

    insert into permissions (entity, entity_id, uid, permission, read_p) values ("global", 0, 2, "superadmin", 1);

(where the 2 in this example should be replaced with whatever the uid index
value is in the users table for your OpenID-autocreated account)
