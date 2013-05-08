:title: Gerrit Installation

Gerrit
######

Objective
*********

A workflow where developers submit changes to gerrit, changes are
peer-reviewed and automatically tested by Jenkins before being
committed to the main repo.  The public repo is on github.

References
**********

* http://gerrit.googlecode.com/svn/documentation/2.2.1/install.html
* http://feeding.cloud.geek.nz/2011/04/code-reviews-with-gerrit-and-gitorious.html
* http://feeding.cloud.geek.nz/2011/05/integrating-launchpad-and-gerrit-code.html
* http://www.infoq.com/articles/Gerrit-jenkins-hudson
* https://wiki.jenkins-ci.org/display/JENKINS/Gerrit+Trigger
* https://wiki.mahara.org/index.php/Developer_Area/Developer_Tools

Known Issues
************

* Don't use innodb until at least gerrit 2.2.2 because of:
  http://code.google.com/p/gerrit/issues/detail?id=518

Installation
************

Host Installation
=================

Prepare Host
------------
This sets the host up with the standard OpenStack system
administration configuration.  Skip this if you're not setting up a
host for use by the OpenStack project.

.. code-block:: bash

  sudo apt-get install puppet git openjdk-6-jre-headless mysql-server
  git clone git://github.com/openstack-infra/config.git
  cd config/
  sudo bash run_puppet.sh

Install MySQL
-------------

Basic configuration of MySQL is handled via puppet.

Install Gerrit
--------------

Note that Openstack's gerrit installation currently uses a custom .war of gerrit
2.2.2.  The following instruction is for the generic gerrit binaries:

.. code-block:: bash

  wget http://gerrit.googlecode.com/files/gerrit-2.2.1.war
  mv gerrit-2.2.1.war gerrit.war
  java -jar gerrit.war init -d review_site

The .war file will bring up an interactive tool to change the settings, these
should be set as follows. Note that the password configured earlier for MySQL
should be provided when prompted::

  *** Gerrit Code Review 2.2.1
  ***

  Create '/home/gerrit2/review_site' [Y/n]?

  *** Git Repositories
  ***

  Location of Git repositories   [git]:

  *** SQL Database
  ***

  Database server type           [H2/?]: ?
  Supported options are:
  h2
  postgresql
  mysql
  jdbc
  Database server type           [H2/?]: mysql

  Gerrit Code Review is not shipped with MySQL Connector/J 5.1.10
  **  This library is required for your configuration. **
  Download and install it now [Y/n]?
  Downloading http://repo2.maven.org/maven2/mysql/mysql-connector-java/5.1.10/mysql-connector-java-5.1.10.jar ... OK
  Checksum mysql-connector-java-5.1.10.jar OK
  Server hostname                [localhost]:
  Server port                    [(MYSQL default)]:
  Database name                  [reviewdb]:
  Database username              [gerrit2]:
  gerrit2's password             :
  confirm password :

  *** User Authentication
  ***

  Authentication method          [OPENID/?]:

  *** Email Delivery
  ***

  SMTP server hostname           [localhost]:
  SMTP server port               [(default)]:
  SMTP encryption                [NONE/?]:
  SMTP username                  :

  *** Container Process
  ***

  Run as                         [gerrit2]:
  Java runtime                   [/usr/lib/jvm/java-6-openjdk/jre]:
  Copy gerrit.war to /home/gerrit2/review_site/bin/gerrit.war [Y/n]?
  Copying gerrit.war to /home/gerrit2/review_site/bin/gerrit.war

  *** SSH Daemon
  ***

  Listen on address              [*]:
  Listen on port                 [29418]:

  Gerrit Code Review is not shipped with Bouncy Castle Crypto v144
  If available, Gerrit can take advantage of features
  in the library, but will also function without it.
  Download and install it now [Y/n]?
  Downloading http://www.bouncycastle.org/download/bcprov-jdk16-144.jar ... OK
  Checksum bcprov-jdk16-144.jar OK
  Generating SSH host key ... rsa... dsa... done

  *** HTTP Daemon
  ***

  Behind reverse proxy           [y/N]? y
  Proxy uses SSL (https://)      [y/N]? y
  Subdirectory on proxy server   [/]:
  Listen on address              [*]:
  Listen on port                 [8081]:
  Canonical URL                  [https://review.openstack.org/]:

  Initialized /home/gerrit2/review_site
  Executing /home/gerrit2/review_site/bin/gerrit.sh start
  Starting Gerrit Code Review: OK
  Waiting for server to start ... OK
  Opening browser ...
  Please open a browser and go to https://review.openstack.org/#admin,projects

Configure Gerrit
----------------

The file /home/gerrit2/review_site/etc/gerrit.config will be setup automatically
by puppet.

Set Gerrit to start on boot:

.. code-block:: bash

  ln -snf /home/gerrit2/review_site/bin/gerrit.sh /etc/init.d/gerrit
  update-rc.d gerrit defaults 90 10

Then create the file ``/etc/default/gerritcodereview`` with the following
contents:

.. code-block:: ini

  GERRIT_SITE=/home/gerrit2/review_site

Add "Approved" review type to gerrit:

.. code-block:: mysql

  mysql -u root -p
  use reviewdb;
  insert into approval_categories values ('Approved', 'A', 2, 'MaxNoBlock', 'N', 'APRV');
  insert into approval_category_values values ('No score', 'APRV', 0);
  insert into approval_category_values values ('Approved', 'APRV', 1);
  update approval_category_values set name = "Looks good to me (core reviewer)" where name="Looks good to me, approved";

Expand "Verified" review type to -2/+2:

.. code-block:: mysql

  mysql -u root -p
  use reviewdb;
  update approval_category_values set value=2
    where value=1 and category_id='VRIF';
  update approval_category_values set value=-2
    where value=-1 and category_id='VRIF';
  insert into approval_category_values values
    ("Doesn't seem to work","VRIF",-1),
    ("Works for me","VRIF","1");

Reword the default messages that use the word Submit, as they imply that
we're not happy with people for submitting the patch in the first place:

.. code-block:: mysql

  mysql -u root -p
  use reviewdb;
  update approval_category_values set name="Do not merge"
    where category_id='CRVW' and value=-2;
  update approval_category_values
    set name="I would prefer that you didn't merge this"
    where category_id='CRVW' and value=-1;

OpenStack currently uses Gerrit's built in CLA system. This
configuration is not recommended for new projects and is merely an
artifact of legal requirements placed on the OpenStack project. Here are
the SQL commands to set it up:

.. code-block:: mysql

  insert into contributor_agreements values (
  'Y', 'Y', 'Y', 'ICLA',
  'OpenStack Individual Contributor License Agreement',
  'static/cla.html', 2);


Install Apache
--------------
::

  apt-get install apache2

Create: /etc/apache2/sites-available/gerrit:

.. code-block:: apacheconf

  <VirtualHost *:80>
    ServerAdmin webmaster@localhost

    ErrorLog ${APACHE_LOG_DIR}/gerrit-error.log

    LogLevel warn

    CustomLog ${APACHE_LOG_DIR}/gerrit-access.log combined

    Redirect / https://review-dev.openstack.org/

  </VirtualHost>

  <IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    ServerAdmin webmaster@localhost

    ErrorLog ${APACHE_LOG_DIR}/gerrit-ssl-error.log

    LogLevel warn

    CustomLog ${APACHE_LOG_DIR}/gerrit-ssl-access.log combined

    SSLEngine on

    SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
    #SSLCertificateChainFile /etc/apache2/ssl.crt/server-ca.crt

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>

    BrowserMatch "MSIE [2-6]" \
        nokeepalive ssl-unclean-shutdown \
        downgrade-1.0 force-response-1.0
    # MSIE 7 and newer should be able to use keepalive
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

    RewriteEngine on
    RewriteCond %{HTTP_HOST} !review-dev.openstack.org
    RewriteRule ^.*$ https://review-dev.openstack.org/

        ProxyPassReverse / http://localhost:8081/
        <Location />
          Order allow,deny
          Allow from all
          ProxyPass http://localhost:8081/ retry=0
        </Location>


  </VirtualHost>
  </IfModule>

Run the following commands:

.. code-block:: bash

  a2enmod ssl proxy proxy_http rewrite
  a2ensite gerrit
  a2dissite default

Install Exim
------------
::

  apt-get install exim4
  dpkg-reconfigure exim4-config

Choose "internet site", otherwise select defaults

edit: /etc/default/exim4 ::

  QUEUEINTERVAL='5m'

GitHub Setup
============

Generate an SSH key for Gerrit for use on GitHub
------------------------------------------------
::

  sudo su - gerrit2
  gerrit2@gerrit:~$ ssh-keygen
  Generating public/private rsa key pair.
  Enter file in which to save the key (/home/gerrit2/.ssh/id_rsa):
  Created directory '/home/gerrit2/.ssh'.
  Enter passphrase (empty for no passphrase):
  Enter same passphrase again:

GitHub Configuration
--------------------

#. create openstack-gerrit user on github
#. add gerrit2 ssh public key to openstack-gerrit user
#. create gerrit team in openstack org on github with push/pull access
#. add openstack-gerrit to gerrit team in openstack org
#. add public master repo to gerrit team in openstack org
#. save github host key in known_hosts

::

  gerrit2@gerrit:~$ ssh git@github.com
  The authenticity of host 'github.com (207.97.227.239)' can't be established.
  RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.
  Are you sure you want to continue connecting (yes/no)? yes
  Warning: Permanently added 'github.com,207.97.227.239' (RSA) to the list of known hosts.
  PTY allocation request failed on channel 0

You will also need to create the file ``github-projects.secure.config`` in the ``/etc/github/`` directory.  The contents of this are as follows:

.. code-block:: ini

  [github]
  username = guthub-user
  password = string

The username should be the github username for gerrit to use when communicating
with github.  The api_token can be found in github's account setting for the
account.

Gerrit Replication to GitHub
----------------------------

The file ``review_site/etc/replication.config`` is needed with the following
contents:

.. code-block:: ini

  [remote "github"]
  url = git@github.com:${name}.git

Jenkins / Gerrit Integration
============================

Create a Jenkins User in Gerrit
-------------------------------

With the jenkins public key, as a gerrit admin user::

  cat jenkins.pub | ssh -p29418 review.openstack.org gerrit create-account --ssh-key - --full-name Jenkins --email jenkins@openstack.org jenkins

Create "CI Systems" group in gerrit, make jenkins a member

Create a Gerrit Git Prep Job in Jenkins
---------------------------------------

When gating trunk with Jenkins, we want to test changes as they will
appear once merged by Gerrit, but the gerrit trigger plugin will, by
default, test them as submitted.  If HEAD moves on while the change is
under review, it may end up getting merged with HEAD, and we want to
test the result.

To do that, make sure the "Hudson Template Project plugin" is
installed, then set up a new job called "Gerrit Git Prep", and add a
shell command build step (no other configuration)::

  #!/bin/sh -x
  git checkout $GERRIT_BRANCH
  git reset --hard remotes/origin/$GERRIT_BRANCH
  git merge FETCH_HEAD
  CODE=$?
  if [ ${CODE} -ne 0 ]; then
    git reset --hard remotes/origin/$GERRIT_BRANCH
    exit ${CODE}
  fi

Later, we will configure Jenkins jobs that we want to behave this way
to use this build step.

Auto Review Expiry
==================

Puppet automatically installs a daily cron job called ``expire-old-reviews``
onto the gerrit servers.  This script follows two rules:

 #. If the review hasn't been touched in 2 weeks, mark as abandoned.
 #. If there is a negative review and it hasn't been touched in 1 week, mark as
    abandoned.

If your review gets touched by either of these rules it is possible to
unabandon a review on the gerrit web interface.

Launchpad Integration
=====================

Keys
----

The key for the launchpad account is in ~/.ssh/launchpad_rsa. Connecting
to Launchpad requires oauth authentication - so open the URL in a
browser and log in to launchpad as the hudson-openstack user. Subsequent
runs will use the cached credentials.

Gerrit IRC Bot
==============

Installation
------------

Ensure there is an up-to-date checkout of openstack-infra/config in ~gerrit2.

::

  apt-get install python-irclib python-daemon python-yaml
  cp ~gerrit2/openstack-infra/config/gerritbot.init /etc/init.d
  chmod a+x /etc/init.d/gerritbot
  update-rc.d gerritbot defaults
  su - gerrit2
  ssh-keygen -f /home/gerrit2/.ssh/gerritbot_rsa

As a Gerrit admin, create a user for gerritbot::

  cat ~gerrit2/.ssh/gerritbot_rsa | ssh -p29418 review.openstack.org gerrit create-account --ssh-key - --full-name GerritBot gerritbot

Configure gerritbot, including which events should be announced in the
gerritbot.config file:

.. code-block:: ini

  [ircbot]
  nick=NICNAME
  pass=PASSWORD
  server=chat.freenode.net
  channel=openstack-dev
  port=6667

  [gerrit]
  user=gerritbot
  key=/home/gerrit2/.ssh/gerritbot_rsa
  host=review.openstack.org
  port=29418
  events=patchset-created, change-merged, x-vrif-minus-1, x-crvw-minus-2

Register an account with NickServ on FreeNode, and put the account and
password in the config file.

::

  sudo /etc/init.d/gerritbot start

Launchpad Bug Integration
=========================

In addition to the hyperlinks provided by the regex in gerrit.config,
we use a Gerrit hook to update Launchpad bugs when changes referencing
them are applied.

Installation
------------

Ensure an up-to-date checkout of openstack-infra/config is in ~gerrit2.

::

  apt-get install python-pyme
  cp ~gerrit2/gerrit-hooks/change-merged ~gerrit2/review_site/hooks/

Create a GPG and register it with Launchpad::

  gerrit2@gerrit:~$ gpg --gen-key
  gpg (GnuPG) 1.4.11; Copyright (C) 2010 Free Software Foundation, Inc.
  This is free software: you are free to change and redistribute it.
  There is NO WARRANTY, to the extent permitted by law.

  Please select what kind of key you want:
     (1) RSA and RSA (default)
     (2) DSA and Elgamal
     (3) DSA (sign only)
     (4) RSA (sign only)
  Your selection?
  RSA keys may be between 1024 and 4096 bits long.
  What keysize do you want? (2048)
  Requested keysize is 2048 bits
  Please specify how long the key should be valid.
           0 = key does not expire
        <n>  = key expires in n days
        <n>w = key expires in n weeks
        <n>m = key expires in n months
        <n>y = key expires in n years
  Key is valid for? (0)
  Key does not expire at all
  Is this correct? (y/N) y

  You need a user ID to identify your key; the software constructs the user ID
  from the Real Name, Comment and Email Address in this form:
      "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"

  Real name: Openstack Gerrit
  Email address: review@openstack.org
  Comment:
  You selected this USER-ID:
      "Openstack Gerrit <review@openstack.org>"

  Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
  You need a Passphrase to protect your secret key.

  gpg: gpg-agent is not available in this session
  You don't want a passphrase - this is probably a *bad* idea!
  I will do it anyway.  You can change your passphrase at any time,
  using this program with the option "--edit-key".

  We need to generate a lot of random bytes. It is a good idea to perform
  some other action (type on the keyboard, move the mouse, utilize the
  disks) during the prime generation; this gives the random number
  generator a better chance to gain enough entropy.

  gpg: /home/gerrit2/.gnupg/trustdb.gpg: trustdb created
  gpg: key 382ACA7F marked as ultimately trusted
  public and secret key created and signed.

  gpg: checking the trustdb
  gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
  gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
  pub   2048R/382ACA7F 2011-07-26
          Key fingerprint = 21EF 7F30 C281 F61F 44CD  EC48 7424 9762 382A CA7F
  uid                  Openstack Gerrit <review@openstack.org>
  sub   2048R/95F6FA4A 2011-07-26

  gerrit2@gerrit:~$ gpg --send-keys --keyserver keyserver.ubuntu.com 382ACA7F
  gpg: sending key 382ACA7F to hkp server keyserver.ubuntu.com

Log into the Launchpad account and add the GPG key to the account.

Adding New Projects

Generate an SSH key for Gerrit
------------------------------------------------
::

  sudo su - gerrit2
  gerrit2@gerrit:~$ ssh-keygen -f ~/.ssh/example_project_id_rsa
  Generating public/private rsa key pair.
  Enter passphrase (empty for no passphrase):
  Enter same passphrase again:
*******************

Creating a new Gerrit Project with Puppet
=========================================

Gerrit project creation is now managed through changes to the
openstack-infra/config repository. The old manual processes are documented
below as the processes are still valid and documentation of them may
still be useful when dealing with corner cases. That said, you should
use this method whenever possible.

Puppet and its related scripts are able to create the new project in
Gerrit, create the new project on Github, create a local git replica on
the Gerrit host, configure the project Access Controls, and create new
groups in Gerrit that are mentioned in the Access Controls. You might
also want to configure Zuul and Jenkins to run tests on the new project.
The details for that process are in the next section.

Gerrit projects are configured in the
``openstack-infra/config:modules/openstack_project/templates/review.projects.yaml.erb``.
file. This file contains two sections, the first is a set of default
config values that each project can override, and the second is a list
of projects (each may contain their own overrides).

As a Gerrit admin, create a user for example-project-creator::

  cat ~gerrit2/.ssh/example_project_id_rsa | ssh -p29418 review.openstack.org gerrit create-account --ssh-key - --full-name "Example Project Creator" --email example-project-creator@example.org example-project-creator

#. Config default values::

     - homepage: http://example.org
       local-git-dir: /var/lib/git
       gerrit-host: review.example.org
       gerrit-user: example-project-creator
       gerrit-key: /home/gerrit2/.ssh/example_project_id_rsa
       github-config: /etc/github/github-projects.secure.config
       has-wiki: False
       has-issues: False
       has-pull-requests: False
       has-downloads: False

Note The gerrit-user 'example-project-creator' should be added to the
"Project Bootstrapers" group in :ref:`acl`.

#. Project definition::

     - project: example/gerrit
       description: Fork of Gerrit used by Example
       remote: https://gerrit.googlesource.com/gerrit
     - project: example/project1
       description: Best project ever.
       has-wiki: True
       acl-config: /path/to/acl/file

The above config gives puppet and its related scripts enough information
to create new projects, but not enough to add access controls to each
project. To add access control you need to have have an ``acl-config``
option for the project in ``review.projects.yaml.erb`` file. That option
should have a value that is a path to the project.config for that
project.

That is the high level view of how we can configure projects using the
pupppet repository. To create an actual change that does all of this for
a single project you will want to do the following:

#. Add a ``modules/openstack_project/files/gerrit/acls/project-name.config``
   file to the repo. You can refer to the :ref:`project-config` section
   below if you need more details on writing the project.config file,
   but contents will probably end up looking like the below block (note
   that the sections are in alphabetical order and each indentation is
   8 spaces)::

     [access "refs/heads/*"]
             label-Code-Review = -2..+2 group project-name-core
             label-Approved = +0..+1 group project-name-core
             workInProgress = group project-name-core
     [access "refs/heads/milestone-proposed"]
             label-Code-Review = -2..+2 group project-name-milestone
             label-Approved = +0..+1 group project-name-milestone
     [project]
             state = active
     [receive]
             requireChangeId = true
             requireContributorAgreement = true
     [submit]
             mergeContent = true

#. Add a project entry for the project in
   ``openstack-infra/config:modules/openstack_project/templates/review.projects.yaml.erb``.::

     - project: openstack/project-name
       acl-config: /home/gerrit2/acls/project-name.config

#. If there is an existing repo that is being replaced by this new
   project you can set the upstream value for the project. When an
   upstream is set, that upstream will be cloned and pushed into Gerrit
   instead of an empty repository. eg::

     - project: openstack/project-name
       acl-config: /home/gerrit2/acls/project-name.config
       upstream: git://github.com/awesumsauce/project-name.git

That is all you need to do. Push the change to gerrit and if necessary
modify group membership for the groups you configured in the
``project.config`` through Launchpad.

Have Zuul Monitor a Gerrit Project
=====================================

Define the required jenkins jobs for this project using the Jenkins Job
Builder. Edit openstack-infra/config:modules/openstack_project/files/jenkins_job_builder/config/projects.yaml
and add the desired jobs. Most projects will use the python jobs template.

A minimum config::

  - project:
      name: PROJECT
      github-org: openstack
      node: precise
      tarball-site: tarballs.openstack.org
      doc-publisher-site: docs.openstack.org

      jobs:
        - python-jobs

Full example config for nova::

  - project:
      name: nova
      github-org: openstack
      node: precise
      tarball-site: tarballs.openstack.org
      doc-publisher-site: docs.openstack.org

      jobs:
        - python-jobs
        - python-diablo-bitrot-jobs
        - python-essex-bitrot-jobs
        - openstack-publish-jobs
        - gate-{name}-pylint

Edit openstack-infra/config:modules/openstack_project/files/zuul/layout.yaml
and add the required jenkins jobs to this project. At a minimum you will
probably need the gate-PROJECT-merge test in the check and gate queues.

A minimum config::

  - name: openstack/PROJECT
      check:
        - gate-PROJECT-merge:
      gate:
        - gate-PROJECT-merge:

Full example config for nova::

  - name: openstack/nova
      check:
        - gate-nova-merge:
        - gate-nova-docs
        - gate-nova-pep8
        - gate-nova-python26
        - gate-nova-python27
        - gate-tempest-devstack-vm
        - gate-tempest-devstack-vm-cinder
        - gate-nova-pylint
      gate:
        - gate-nova-merge:
        - gate-nova-docs
        - gate-nova-pep8
        - gate-nova-python26
        - gate-nova-python27
        - gate-tempest-devstack-vm
        - gate-tempest-devstack-vm-cinder
      post:
        - nova-branch-tarball
        - nova-coverage
        - nova-docs
      pre-release:
        - nova-tarball
      publish:
        - nova-tarball
        - nova-docs

Creating a Project in Gerrit
============================

Using ssh key of a gerrit admin (you)::

  ssh -p 29418 review.openstack.org gerrit create-project --name openstack/PROJECT

If the project is an API project (eg, image-api), we want it to share
some extra permissions that are common to all API projects (eg, the
OpenStack documentation coordinators can approve changes, see
:ref:`acl`).  Run the following command to reparent the project if it
is an API project::

  ssh -p 29418 review.openstack.org gerrit set-project-parent --parent API-Projects openstack/PROJECT

Add yourself to the "Project Bootstrappers" group in Gerrit which will
give you permissions to push to the repo bypassing code review.

Do the initial push of the project with::

  git push ssh://USERNAME@review.openstack.org:29418/openstack/PROJECT.git HEAD:refs/heads/master
  git push --tags ssh://USERNAME@review.openstack.org:29418/openstack/PROJECT.git

Remove yourself from the "Project Bootstrappers" group, and then set
the access controls as specified in :ref:`acl`.

Create a Project in GitHub
==========================

As a github openstack admin:

* Visit https://github.com/organizations/openstack
* Click New Repository
* Visit the gerrit team admin page
* Add the new repository to the gerrit team

Pull requests can not be disabled for a project in Github, so instead
we have a script that runs from cron to close any open pull requests
with instructions to use Gerrit.

* Edit openstack-infra/config:modules/openstack_project/templates/review.projects.yaml.erb

and add the project to the list of projects in the yaml file

For example::

  - project: openstack/PROJECT

Adding Local Git Replica
========================

Gerrit replicates all repos to a local directory so that Apache can
serve the anonymous http requests out directly.

On the gerrit host::

  sudo git --bare init /var/lib/git/openstack/PROJECT.git
  sudo chown -R gerrit2:gerrit2 /var/lib/git/openstack/PROJECT.git

Adding A New Project On The Command Line
****************************************

All of the steps involved in adding a new project to Gerrit can be
accomplished via the commandline, with the exception of creating a new repo
on github.

First of all, add the .gitreview file to the repo that will be added. Then,
assuming an ssh config alias of `review` for the gerrit instance, as a person
in the Project Bootstrappers group::

     ssh review gerrit create-project --name openstack/$PROJECT
     git review -s
     git push gerrit HEAD:refs/heads/master
     git push --tags gerrit

At this point, the branch contents will be in gerrit, and the project config
settings and ACLs need to be set. These are maintained in a special branch
inside of git in gerrit. Check out the branch from git::

     git fetch gerrit +refs/meta/*:refs/remotes/gerrit-meta/*
     git checkout -b config remotes/gerrit-meta/config

There will be two interesting files, `groups` and `project.config`. `groups`
contains UUIDs and names of groups that will be referenced in
`project.config`. UUIDs can be found on the group page in gerrit.
Next, edit `project.config` to look like::

      [access "refs/*"]
              owner = group Administrators
      [receive]
              requireChangeId = true
              requireContributorAgreement = true
      [submit]
              mergeContent = true
      [access "refs/heads/*"]
              label-Code-Review = -2..+2 group $PROJECT-core
              label-Approved = +0..+1 group $PROJECT-core
      [access "refs/heads/milestone-proposed"]
              label-Code-Review = -2..+2 group $PROJECT-milestone
              label-Approved = +0..+1 group $PROJECT-milestone

If the project is for a client library, the `refs/*` section of
`project.config` should look like::

      [access "refs/*"]
              owner = group Administrators
              create = group $PROJECT-milestone
              pushTag = group $PROJECT-milestone

Replace $PROJECT with the name of the project.

Finally, commit the changes and push the config back up to Gerrit::

      git commit -m "Initial project config"
      git push gerrit HEAD:refs/meta/config

At this point you can follow the steps above for creating the project's github
replica, the local git replica, and zuul monitoring/jenkins jobs.

Migrating a Project from bzr
============================

Add the bzr PPA and install bzr-fastimport:

  add-apt-repository ppa:bzr/ppa
  apt-get update
  apt-get install bzr-fastimport

Doing this from the bzr PPA is important to ensure at least version 0.10 of
bzr-fastimport.

Clone the git-bzr-ng from termie:

  git clone https://github.com/termie/git-bzr-ng.git

In git-bzr-ng, you'll find a script, git-bzr. Put it somewhere in your path.
Then, to get a git repo which contains the migrated bzr branch, run:

  git bzr clone lp:${BRANCHNAME} ${LOCATION}

So, for instance, to do glance, you would do:

  git bzr clone lp:glance glance

And you will then have a git repo of glance in the glance dir. This git repo
is now suitable for uploading in to gerrit to become the new master repo.

.. _project-config:

Project Config
**************

There are a few options which need to be enabled on the project in the Admin
interface.

* Merge Strategy should be set to "Merge If Necessary"
* "Automatically resolve conflicts" should be enabled
* "Require Change-Id in commit message" should be enabled
* "Require a valid contributor agreement to upload" should be enabled

Optionally, if the PTL agrees to it:

* "Require the first line of the commit to be 50 characters or less" should
  be enabled.

.. _acl:

Access Controls
===============

High level goals:

#. Anonymous users can read all projects.
#. All registered users can perform informational code review (+/-1)
   on any project.
#. Jenkins can perform verification (blocking or approving: +/-1).
#. All registered users can create changes.
#. The OpenStack Release Manager and Jenkins can tag releases (push
   annotated tags).
#. Members of $PROJECT-core group can perform full code review
   (blocking or approving: +/- 2), and submit changes to be merged.
#. Members of openstack-release (Release Manager and PTLs), and
   $PROJECT-milestone (PTL and release minded people) exclusively can
   perform full code review (blocking or approving: +/- 2), and submit
   changes to be merged on milestone-proposed branches.
#. Full code review (+/- 2) of API projects should be available to the
   -core group of the corresponding implementation project as well as to
   the OpenStack Documentation Coordinators.
#. Full code review of stable branches should be available to the
   -core group of the project as well as the openstack-stable-maint
   group.
#. Drivers (PTL and delegates) of client library projects should be
   able to add tags (which are automatically used to trigger
   releases).

To manage API project permissions collectively across projects, API
projects are reparented to the "API-Projects" meta-project instead of
"All-Projects".  This causes them to inherit permissions from the
API-Projects project (which, in turn, inherits from All-Projects).

These permissions try to achieve the high level goals::

  All Projects (metaproject):
    refs/*
      read: anonymous
      push annotated tag: release managers, ci tools, project bootstrappers
      forge author identity: registered users
      forge committer identity: project bootstrappers
      push (w/ force push): project bootstrappers
      create reference: project bootstrappers, release managers
      push merge commit: project bootstrappers

    refs/for/refs/*
      push: registered users

    refs/heads/*
      label code review:
        -1/+1: registered users
        -2/+2: project bootstrappers
      label verified:
        -2/+2: ci tools
        -2/+2: project bootstrappers
        -1/+1: external tools
      label approved 0/+1: project bootstrappers
      submit: ci tools
      submit: project bootstrappers

    refs/heads/milestone-proposed
      label code review (exclusive):
        -2/+2 openstack-release
        -1/+1 registered users
      label approved (exclusive): 0/+1: openstack-release
      owner: openstack-release

    refs/heads/stable/*
      label code review (exclusive):
        -2/+2 opestack-stable-maint
        -1/+1 registered users
      label approved (exclusive): 0/+1: opestack-stable-maint

    refs/meta/*
      push: project bootstrappers

    refs/meta/config
      read: project bootstrappers
      read: project owners

  API Projects (metaproject):
    refs/*
      owner: Administrators

    refs/heads/*
      label code review -2/+2: openstack-doc-core
      label approved 0/+1: openstack-doc-core

  project foo:
    refs/*
      owner: Administrators
      create reference: foo-milestone  [client library only]
      push annotated tag: foo-milestone  [client library only]

    refs/heads/*
      label code review -2/+2: foo-core
      label approved 0/+1: foo-core

    refs/heads/milestone-proposed
      label code review -2/+2: foo-milestone
      label approved 0/+1: foo-milestone

Renaming a Project
******************

Renaming a project is not automated and is disruptive to developers,
so it should be avoided. Allow for an hour of downtime for the
project in question, and about 10 minutes of downtime for all of
Gerrit. All Gerrit changes, merged and open, will carry over, so
in-progress changes do not need to be merged before the move.

To rename a project:

#. Prepare a change to the Puppet configuration which updates
   projects.yaml/ACLs and jenkins-job-builder for the new name.

#. Stop puppet on review.openstack.org to prevent your interim
   configuration changes from being reset by the project management
   routines::

     sudo puppetd --disable

#. Make the project inacessible by editing the Access pane. Add a
   "read" ACL for "Administrators", and mark it "exclusive". Be sure
   to save changes.

#. Update the database on review.openstack.org::

     sudo mysql --defaults-file=/etc/mysql/debian.cnf reviewdb

     update account_project_watches
     set project_name = "openstack/NEW"
     where project_name = "openstack/OLD";

     update changes
     set dest_project_name = "openstack/NEW"
     where dest_project_name = "openstack/OLD";

#. Take Jenkins offline through its WebUI.

#. Stop Gerrit on review.openstack.org and move both the Git
   repository and the mirror::

     sudo invoke-rc.d gerrit stop
     sudo mv ~gerrit2/review_site/git/openstack/{OLD,NEW}.git
     sudo mv /var/lib/git/openstack/{OLD,NEW}.git
     sudo invoke-rc.d gerrit start

#. Bring Jenkins online through its WebUI.

#. Merge the prepared Puppet configuration change, removing the
   original Jenkins jobs via the Jenkins WebUI later if needed.

#. Start puppet again on review.openstack.org::

     sudo puppetd --enable

#. Rename the project in GitHub or, if this is a move to a new org, let
   the project management run create it for you and then remove the
   original later (assuming you have sufficient permissions).

#. If this is an org move and the project name itself is not
   changing, gate jobs may fail due to outdated remote URLs. Clear
   the workspaces on persistent Jenkins slaves to mitigate this::

     ssh -t $h.slave.openstack.org 'sudo rm -rf ~jenkins/workspace/*PROJECT*'

#. Again, if this is an org move rather than a rename and the GitHub
   project has been created but is empty, trigger replication to
   populate it::

     ssh -p 29418 review.openstack.org gerrit replicate --all

#. Wait for puppet changes to be applied so that the earlier
   restrictive ACL will be reset for you (ending the outage for this
   project).

#. Submit a change that updates .gitreview with the new location of the
   project.

Developers will either need to re-clone a new copy of the repository,
or manually update their remotes with something like::

  git remote set-url origin https://github.com/$ORG/$PROJECT.git

Deleting a User from Gerrit
***************************

This isn't normally necessary, but if you find that you need to
completely delete an account from Gerrit, here's how:

.. code-block:: mysql

  delete from account_agreements where account_id=NNNN;
  delete from account_diff_preferences where id=NNNN;
  delete from account_external_ids where account_id=NNNN;
  delete from account_group_members where account_id=NNNN;
  delete from account_group_members_audit where account_id=NNNN;
  delete from account_patch_reviews where account_id=NNNN;
  delete from account_project_watches where account_id=NNNN;
  delete from account_ssh_keys where account_id=NNNN;
  delete from accounts where account_id=NNNN;

.. code-block:: bash

  ssh review.openstack.org -p29418 gerrit flush-caches --all

