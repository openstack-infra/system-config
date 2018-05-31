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

Apache is used and there is a Trove backend.

Sysadmin
========

Initial deployment in a clean database will require entering the default
admin account credentials (from hiera) into the login form to perform
subsequent configuration. You will be prompted for OpenID authentication
but it won't be used by the interface for now.

Admin sign-in: https://survey.openstack.org/admin

Configuration > Global Settings > Email Settings

    Default site admin email: infra-root@openstack.org

    Administrator name: admin

Configuration > Global Settings > Bounce Settings

    Default site admin email: infra-root@openstack.org

Save and Close
check admin name and email information on front page: survey.openstack.org
to confirm change

Configuration -> Plugin Manager

    activate plugin "webserver"

    configure plugin "webserver"

    leave at defaults but "save and close"

    log out and reauthenticate as openid autocreated user


Enable the webserver auth plugin via mysqlclient:
    update plugins set active=1 where name="Authwebserver";

May also need to adjust these:
  mysql> select * from plugin_settings;
  +----+-----------+-------+----------+--------------+---------------+
  | id | plugin_id | model | model_id | key          | value         |
  +----+-----------+-------+----------+--------------+---------------+
  |  1 |         6 | NULL  |     NULL | strip_domain | ""            |
  |  2 |         6 | NULL  |     NULL | serverkey    | "REMOTE_USER" |
  |  3 |         6 | NULL  |     NULL | is_default   | "1"           |
  +----+-----------+-------+----------+--------------+---------------+
  3 rows in set (0.00 sec)

Authenticate as an OpenID autocreated user, and then elevate it to a
superadmin via mysqlclient:
 insert into permissions (entity, entity_id, uid, permission, read_p) values ("global", 0, 2, "superadmin", 1);
 (where the 2 in this example should be replaced with whatever the uid index value is in the users table for your OpenID-autocreated account)
