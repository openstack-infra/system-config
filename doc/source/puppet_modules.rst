Puppet Modules
==============

Overview
--------

Much of the OpenStack project infrastructure is deployed and managed using
puppet.
The OpenStack Infrastructure team manages a number of custom puppet modules
outlined in this document.

Lodgeit
-------

The lodgeit module installs and configures lodgeit [1]_ on required servers to
be used as paste installations.  For OpenStack we use
`a fork <https://github.com/openstack-infra/lodgeit>`_ of this which is based on
one with bugfixes maintained by
`dcolish <https://bitbucket.org/dcolish/lodgeit-main>`_ but adds back missing
anti-spam features required by Openstack.

Puppet will configure lodgeit to use drizzle [2]_ as a database backend,
apache as a front-end proxy and upstart scripts to run the lodgeit
instances.  It will store and maintain local branch of the the mercurial
repository for lodgeit in ``/tmp/lodgeit-main``.

To use this module you need to add something similar to the following in the
main ``site.pp`` manifest:

.. code-block:: ruby
   :linenos:

   node "paste.openstack.org" {
     include openstack_server
     include lodgeit
     lodgeit::site { "openstack":
       port => "5000",
       image => "header-bg2.png"
     }

     lodgeit::site { "drizzle":
       port => "5001"
     }
   }

In this example we include the lodgeit module which will install all the
pre-requisites for Lodgeit as well as creating a checkout ready.
The ``lodgeit::site`` calls create the individual paste sites.

The name in the ``lodgeit::site`` call will be used to determine the URL, path
and name of the site.  So "openstack" will create ``paste.openstack.org``,
place it in ``/srv/lodgeit/openstack`` and give it an upstart script called
``openstack-paste``.  It will also change the h1 tag to say "Openstack".

The port number given needs to be a unique port which the lodgeit service will
run on.  The puppet script will then configure nginx to proxy to that port.

Finally if an image is given that will be used instead of text inside the h1
tag of the site.  The images need to be stored in the ``modules/lodgeit/files``
directory.

Lodgeit Backups
^^^^^^^^^^^^^^^

The lodgeit module will automatically create a git repository in ``/var/backups/lodgeit_db``.  Inside this every site will have its own SQL file, for example "openstack" will have a file called ``openstack.sql``.  Every day a cron job will update the SQL file (one job per file) and commit it to the git repository.

.. note::
   Ideally the SQL files would have a row on every line to keep the diffs stored
   in git small, but ``drizzledump`` does not yet support this.

Planet
------

The planet module installs Planet Venus [4]_ along with required dependancies
on a server.  It also configures specified planets based on options given.

Planet Venus works by having a cron job which creates static files.  In this
module the static files are served using apache.

To use this module you need to add something similar to the following into the
main ``site.pp`` manifest:

.. code-block:: ruby
   :linenos:

   node "planet.openstack.org" {
     include planet

     planet::site { "openstack":
       git_url => "https://github.com/openstack/openstack-planet.git"
     }
   }

In this example the name "openstack" is used to create the site
``paste.openstack.org``.  The site will be served from
``/srv/planet/openstack/`` and the checkout of the ``git_url`` supplied will
be maintained in ``/var/lib/planet/openstack/``.

This module will also create a cron job to pull new feed data 3 minutes past each hour.

The ``git_url`` parameter needs to point to a git repository which stores the
planet.ini configuration for the planet (which stores a list of feeds) and any required theme data.  This will be pulled every time puppet is run.

.. _Meetbot_Puppet_Module:

Meetbot
-------

The meetbot module installs and configures meetbot [5]_ on a server.  The
meetbot version installed by this module is pulled from the
`OpenStack Infrastructure fork <https://github.com/openstack-infra/meetbot/>`_
of the project.

It also configures apache to be used for accessing the public IRC logs of
the meetings.

To use this module simply add a section to the site manifest as follows:

.. code-block:: ruby
   :linenos:

   node "eavesdrop.openstack.org" {
     include openstack_cron
     class { 'openstack_server':
       iptables_public_tcp_ports => [80]
     }
     include meetbot

     meetbot::site { "openstack":
       nick => "openstack",
       network => "FreeNode",
       server => "chat.freenode.net:7000",
       url => "eavesdrop.openstack.org",
       channels => "#openstack #openstack-dev #openstack-meeting",
       use_ssl => "True"
     }
   }

You will also need a file ``/root/secret-files/name-nickserv.pass`` where `name`
is the name specified in the call to the module (`openstack` in this case).

Each call to meetbot::site will create setup a meebot in ``/var/lib/meetbot``
under a subdirectory of the name of the call to the module.  It will also
configure nginix to go to that site when the ``/meetings`` directory is
specified on the URL.

The puppet module also creates startup scripts for meetbot and will ensure that
it is running on each puppet run.

Gerrit
------

The Gerrit puppet module configures the basic needs of a Gerrit server.  It does
not (yet) install Gerrit itself and mostly deals with the configuration files
and skinning of Gerrit.

Using Gerrit
^^^^^^^^^^^^

Gerrit is set up when the following class call is added to a node in the site
manifest:

.. code-block:: ruby

  class { 'gerrit':
    canonicalweburl => "https://review.openstack.org/",
    email => "review@openstack.org",
    github_projects => [
      'openstack/nova',
      'stackforge/MRaaS',
      ],
    logo => 'openstack.png'
  }

Most of these options are self-explanitory.  The ``github_projects`` is a list of
all projects in GitHub which are managed by the gerrit server.

Skinning
^^^^^^^^

Gerrit is skinned using files supplied by the puppet module.  The skin is
automatically applied as soon as the module is executed.  In the site manifest
setting the logo is important:

.. code-block:: ruby

   class { 'gerrit':
     ...
     logo => 'openstack.png'
   }

This specifies a PNG file which must be stored in the ``modules/gerrit/files/``
directory.

Jenkins Master
--------------

The Jenkins Master puppet module installs and supplies a basic Jenkins
configuration.  It also supplies a skin to Jenkins to make it look more like an
OpenStack site.  It does not (yet) install the additional Jenkins plugins used
by the OpenStack project.

Using Jenkins Master
^^^^^^^^^^^^^^^^^^^^

In the site manifest a node can be configured to be a Jenkins master simply by
adding the class call below:

.. code-block:: ruby

   class { 'jenkins::master':
     site => 'jenkins.openstack.org',
     serveradmin => 'webmaster@openstack.org',
     logo => 'openstack.png'
   }

The ``site`` and ``serveradmin`` parameters are used to configure Apache.  You
will also need in this instance the following files for Apache to start::

   /etc/ssl/certs/jenkins.openstack.org.pem
   /etc/ssl/private/jenkins.openstack.org.key
   /etc/ssl/certs/intermediate.pem

The ``jenkins.openstack.org`` is replace by the setting in the ``site``
parameter.

Skinning
^^^^^^^^

The Jenkins skin uses the `Simple Theme Plugin
<http://wiki.jenkins-ci.org/display/JENKINS/Simple+Theme+Plugin>`_ for Jenkins.
The puppet module will install and configure most aspects of the skin
automatically, with a few adjustments needed.

In the site.pp file the ``logo`` parameter is important:

.. code-block:: ruby

   class { 'jenkins::master':
     ...
     logo => 'openstack.png'
   }

This relates to a PNG file that must be in the ``modules/jenkins/files/``
directory.

Once puppet installs this and the plugin is installed you need to go into
``Manage Jenkins -> Configure System`` and look for the ``Theme`` heading.
Assuming we are skinning the main OpenStack Jenkins site, in the ``CSS`` box
enter
``https://jenkins.openstack.org/plugin/simple-theme-plugin/openstack.css`` and
in the ``JS`` box enter
``https://jenkins.openstack.org/plugin/simple-theme-plugin/openstack.js``.

Etherpad Lite
-------------

This Puppet module installs Etherpad Lite [3]_ and its dependencies (including
node.js). This Puppet module also configures Etherpad Lite to be started at
boot with Nginx running in front of it as a reverse proxy and MySQL running as
the database backend.

Using this module is straightforward you simply need to include a few classes.
However, there are some limitations to be aware of which are described below.
The includes you need are:

::

  include etherpad_lite        # Acts like a package manager and installs things
  include etherpad_lite::nginx # Sets up Nginx to reverse proxy Etherpad Lite
  include etherpad_lite::site  # Configures Etherpad Lite
  include etherpad_lite::mysql # Configures MySQL DB backend for Etherpad Lite

These classes are parameterized and provide some configurability, but should
all work together when instantiated with their defaults.

Config File
^^^^^^^^^^^

Because the Etherpad Lite configuration file contains a database password it is
not directly managed by Puppet. Instead Puppet expects the configuration file
to be at ``/root/secret-files/etherpad-lite_settings.json`` on the Puppet
master (if running in master/agent setup) or on the server itself if running
``puppet apply``.

MySQL will be configured by Puppet to listen on TCP 3306 of localhost and a
database called ``etherpad-lite`` will be created for user ``eplite``. Also,
this module does install the Abiword package. Knowing this, a good template for
your config is:

::

  /*
    This file must be valid JSON. But comments are allowed

    Please edit settings.json, not settings.json.template
  */
  {
    //Ip and port which etherpad should bind at
    "ip": "127.0.0.1",
    "port" : 9001,

    //The Type of the database. You can choose between dirty, sqlite and mysql
    //You should use mysql or sqlite for anything else than testing or development
    "dbType" : "mysql",
    //the database specific settings
    "dbSettings" : {
                     "user"    : "eplite",
                     "host"    : "localhost",
                     "password": "changeme",
                     "database": "etherpad-lite"
                   },

    //the default text of a pad
    "defaultPadText" : "Welcome to Etherpad Lite!\n\nThis pad text is synchronized as you type, so that everyone viewing this page sees the same text. This allows you to collaborate seamlessly on documents!\n\nEtherpad Lite on Github: http:\/\/j.mp/ep-lite\n",

    /* Users must have a session to access pads. This effectively allows only group pads to be accessed. */
    "requireSession" : false,

    /* Users may edit pads but not create new ones. Pad creation is only via the API. This applies both to group pads and regular pads. */
    "editOnly" : false,

    /* if true, all css & js will be minified before sending to the client. This will improve the loading performance massivly,
       but makes it impossible to debug the javascript/css */
    "minify" : true,

    /* How long may clients use served javascript code? Without versioning this
      is may cause problems during deployment. */
    "maxAge" : 21600000, // 6 hours

    /* This is the path to the Abiword executable. Setting it to null, disables abiword.
       Abiword is needed to enable the import/export of pads*/
    "abiword" : "/usr/bin/abiword",

    /* This setting is used if you need http basic auth */
    // "httpAuth" : "user:pass",

    /* The log level we are using, can be: DEBUG, INFO, WARN, ERROR */
    "loglevel": "INFO"
  }

Don't forget to change the password if you copy this configuration. Puppet will
grep that password out of the config and use it to set the password for the
MySQL eplite user.

Nginx
^^^^^

The reverse proxy is configured to talk to Etherpad Lite over localhost:9001.
Nginx listens on TCP 443 for HTTPS connections. Because HTTPS is used you will
need SSL certificates. These files are not directly managed by Puppet (again
because of the sensitive nature of these files), but Puppet will look for
``/root/secret-files/eplite.crt`` and ``/root/secret-files/eplite.key`` and
copy them to ``/etc/nginx/ssl/eplite.crt`` and ``/etc/nginx/ssl/eplite.key``,
which is where Nginx expects them to be.

MySQL
^^^^^

MySQL is configured by the Puppet module to allow user ``eplite`` to use
database ``etherpad-lite``. If you want backups for the ``etherpad-lite``
database you can include ``etherpad_lite::backup``. By default this will backup
the ``etherpad-lite`` DB daily and keep a rotation of 30 days of backups.

.. rubric:: Footnotes
.. [1] `Lodgeit homepage <http://www.pocoo.org/projects/lodgeit/>`_
.. [2] `Drizzle homepage <http://www.drizzle.org/>`_
.. [3] `Etherpad Lite homepage <https://github.com/Pita/etherpad-lite>`_
.. [4] `Planet Venus homepage <http://intertwingly.net/code/venus/docs/index.html>`_
.. [5] `Meetbot homepage <http://wiki.debian.org/MeetBot>`_
