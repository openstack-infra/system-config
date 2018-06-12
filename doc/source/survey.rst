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

After initially provisioning the server, enable the Authwebserver plugin via mysqlclient:

.. code-block:: bash

    insert into plugins (name, active) values ('Authwebserver', 1);

    insert into plugin_settings (plugin_id, plugin_settings.key, plugin_settings.value) values (1, 'strip_domain', '""');
    insert into plugin_settings (plugin_id, plugin_settings.key, plugin_settings.value) values (1, 'serverkey', '"REMOTE_USER"');
    insert into plugin_settings (plugin_id, plugin_settings.key, plugin_settings.value) values (1, 'is_default', '"1"');

Log in as admin to auto-create your account:
Admin sign-in: https://survey.openstack.org/admin

Elevate your account to Superadmin via mysqlclient:

.. code-block:: bash

    insert into permissions (entity, entity_id, uid, permission, read_p) values ("global", 0, 2, "superadmin", 1);

(where the 2 in this example should be replaced with whatever the uid index
value is in the users table for your OpenID-autocreated account)

Refresh your browser. When logged in via the web-ui you should now have
superadmin priviledges allowing you to set the following values:

Configuration > Global Settings > Email Settings

    Default site admin email: infra-root@openstack.org

    Administrator name: admin

Configuration > Global Settings > Bounce Settings

    Default site admin email: infra-root@openstack.org

Save and Close
check admin name and email information on front page: survey.openstack.org
to confirm change

Admin Survey User
=================

Log in via https://survey.openstack.org/admin using OpenStackID.

Navigate to your 'My Account' settings at:
https://survey.openstack.org/index.php/admin/user/sa/personalsettings

Change your Email from 'autouser@test.test' to the email you would like to
use for the use of surveys.

Change your Full Name from 'autouser' to your Full Name that survey
participants can recognize.

Save and Close using the button in the top right hand corner.
