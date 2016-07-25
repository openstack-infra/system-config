:title: Askbot

.. _askbot:

Askbot
######

Askbot is a publicly available Q&A support site for OpenStack.

At a Glance
===========

:Hosts:
  * https://ask.openstack.org
  * https://ask-staging.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-askbot/tree/
  * https://github.com/vamsee/puppet-solr
  * :file:`modules/openstack_project/manifests/ask.pp`
  * :file:`modules/openstack_project/manifests/ask-staging.pp`
:Projects:
  * https://askbot.com
  * http://lucene.apache.org/solr
  * http://redis.io

Overview
========

The site ask.openstack.org based on the officially released askbot pip distribution.
The stable deployment is extended with a custom OpenStack theme available at
https://git.openstack.org/cgit/openstack-infra/askbot-theme.

The ask-staging.openstack.org site based on master branch of
https://github.com/askbot/askbot-devel repository, and deploys askbot
directly from github and consume the openstack theme from
openstack-infra/askbot-theme repository. The staging site is using
python virtualenv for proper pip dependency handling.

System Architecture
===================

::

    +--------+      +----------+
    | apache | ---- | mod_wsgi |
    +--------+      +----------+
                        |
                 +-------------+    +---------------+
                 | askbot site |--- | celery daemon |
                 +-------------+    +---------------+
                /      |        \
               /       |         \
      +-------+  +------------+  +-------------+
      | redis |  | postgresql |  | apache solr |
      +-------+  +------------+  +-------------+

Apache / mod_wsgi
-----------------

Serve the incoming http request using the mod_wsgi Python WSGI adapter, through
an SSL virtual host. The site vhost also contains url aliases to serve static
content of the theme and all uploaded image files, including the site logo.

Askbot site
-----------

The Askbot django application, the custom site specific assets live under
/srv/askbot-sites/slot0 directory, including the configuration, application
level log files, static content, custom OpenStack theme and uploaded files.

The authentication based on Google, Yahoo and Launchpad OpenID providers.
Local login and all other providers except Google, Yahoo and Launchpad are
disabled in site configuration.

The askbot-theme repository contains just the pure Sass source of the theme,
so this must be precompiled by compass Sass tool.

Application management tool can be found under /srv/askbot-sites/slot0/config:
``python manage.py <command>``

Configuration files:

* :file:`modules/askbot/templates/askbot.vhost.erb`
* :file:`modules/askbot/templates/settings.py.erb`

In addition to the file-based configuration, Askbot provides a web interface
to tweak its own settings. Toggles and fields for reputation thresholds,
user communications rules, data entry and formatting rules, keys for external
services and static content can be found at `$URL/en/settings/`.

As per Django standard, `$URL/admin` provides access to the Django
administration interface. Effectively a limited web portal to the data in the
database - but sometimes useful for debugging login problems using the
`Django_authopenid` plugin.


Celery daemon
-------------

This upstart based daemon is responsible for async tasks of the Askbot site,
and can be managed by standard service management tools:
``server askbot-celeryd <start|stop|status>``

Redis
-----

Askbot is using redis for handling local caching of configuration and page
data. It is useful to clear the redis cache with the ``FLUSHALL`` command
after a service restart.

Postgresql
----------

A postgresql database hosts the content and dynamic site configuration.

Apache Solr
-----------

Apache Solr handling the full-text indexes of the site, based on a
multi-core setup, and assigning cores for specific languages. Currently
the English (en) and Chinese (zh) languages are supported.

Solr schema templates can be found at:

* :file:`modules/askbot/templates/solr/schema.en.xml.erb`
* :file:`modules/askbot/templates/solr/schema.cn.xml.erb`

Operational notes
=================

The askbot website contains a ``surprisingly`` askbot based support forum,
and a lot of operational related information is available there. Additional
maintenance commands:

* activate virtualenv: ``source /usr/askbot-env/bin/activate``
* synchronize db schema: ``python manage.py syncdb``
* migrate database between upgrades: ``python manage.py migrate``
* rebuild solr index: ``python manage.py askbot_rebuild_index -l <language-code>``
* assign administrator right to a user: ``python manage.py add_admin <user-id>``
* update site url setting in askbot database: ``update livesettings_setting set value = '<site-url>' where "group" = 'QA_SITE_SETTINGS' and key = 'APP_URL';``
