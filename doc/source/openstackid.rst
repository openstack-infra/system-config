:title: OpenstackId

==================
OpenstackId Server
==================

OpenId Idp/ OAuth2.0 AS/RS

At a Glance
===========

:Wiki:
  * https://wiki.openstack.org/wiki/OpenStackID
:Hosts:
  * https://openstackid-dev.openstack.org
  * https://openstackid.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-openstackid/tree/
  * :file:`modules/openstack_project/manifests/openstackid_dev.pp`
:Projects:
  * http://git.openstack.org/cgit/openstack-infra/openstackid/
:Bugs:
  * https://storyboard.openstack.org/#!/project/728
:Resources:
  * http://laravel.com/docs/installation
  * http://laravel.com/docs/configuration

Objective
=========

OpenStackID has been developed to provide a unique online identity for
all OpenStack web properties. The intention is to replace Launchpad as
openID provider. The code provides authentication via OpenID and
authentication + authorization via OAuth2. More details about
OpenStackID server are on the wiki.


Configuration
=============

Environment Configuration
_________________________

We need to instruct the Laravel Framework how to determine which
environment it is running in. The default environment is always
production. However, you may setup other environments within the
*bootstrap/start.php* file at the root of your installation.

It is include on folder bootstrap a file called bootstrap/environment.php.tpl
you must make a copy and rename it to bootstrap/environment.php

In this file you will find an **$app->detectEnvironment** call. The
array passed to this method is used to determine the current
environment. You may add other environments and machine names to the
array as needed.

.. code-block:: php

   <?php

   $env = $app->detectEnvironment(array(

       'local' => array('your-machine-name'),

   ));

Database Configuration
______________________

It is often helpful to have different configuration values based on
the environment the application is running in. For example, you may
wish to use a different database configuration on your development
machine than on the production server. It is easy to accomplish this
using environment based configuration.
Simply create a folder within the config directory that matches your
environment name, such as **dev**. Next, create the configuration
files you wish to override and specify the options for that
environment. For example, to override the database configuration for
the local environment, you would create a database.php file in
app/config/dev.

OpenstackId server makes use of two database connections:

* openstackid
* os_members

**openstackid** is its own OpenstackId Server DB, where stores all
related configuration to openid/oauth2 protocol.
**os_members** is SS DB (http://www.openstack.org/).
both configuration are living on config file **database.php**, which
could be a set per environment as forementioned like
app/config/dev/database.php


Error Log Configuration
_______________________

Error log configuration is on file *app/config/log.php* but could be
overridden per environment such as *app/config/dev/log.php* , here you
set two variables:

* to_email : The receiver of the error log email.
* from_email: The sender of the error log email.


Recaptcha Configuration
_______________________

OpenstackId server uses recaptcha facility to discourage brute force
attacks attempts on login page, so in order to work properly recaptcha
plugin must be provided with a public and a private key
(http://www.google.com/recaptcha). These keys are set on file
*app/config/packages/greggilbert/recaptcha/config.php*, but also
could be set per environment using following directory structure
*app/config/packages/greggilbert/recaptcha/dev/config.php*.

Installation
____________

OpenstackId Server uses composer utility in order to install all
needed dependencies. After you get the source code from git, you must
run following commands on application root directory:

* curl -sS https://getcomposer.org/installer | php
* php composer.phar install
* php artisan migrate --env=YOUR ENVIRONMENT
* php artisan db:seed --env=YOUR ENVIRONMENT

** your virtual host must point to /public folder.

Permissions
___________

Laravel may require one set of permissions to be configured: folders
within app/storage require write access by the web server.
