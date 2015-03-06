.. _third-party-testing:

Third Party Testing
===================

Overview
--------

Gerrit has an event stream which can be subscribed to, using this it
is possible to test commits against testing systems beyond those
supplied by OpenStack's Jenkins setup.  It is also possible for these
systems to feed information back into Gerrit and they can also leave
non-gating votes on Gerrit review requests.

There are several examples of systems that read the Gerrit event stream
and run their own tests on the commits
`on this page <https://wiki.openstack.org/wiki/ThirdPartySystems>`_.
For each patch set the third party system tests, the system adds a comment
in Gerrit with a summary of the test result and links to the test artifacts.

Requirements
------------

* Until a third party testing system operates in a stable fashion, third
  party tests can comment on patches but not vote on them.

  * A system can also be set up to only do '+1' reviews and leave all the
    '-1's to be manually confirmed.

* A third-party system may only leave one comment per patch set
  (unless it is retriggered).

* The maintainers are responsible for re-triggering tests when their third
  party testing system breaks.

* Support recheck to request re-running a test.

  * Support the following syntaxes: ``recheck``.
  * Recheck means recheck everything. A single recheck comment should
    re-trigger all testing systems.

* Publish contact information for the maintainers.

  * All accounts must have a wikipage entry. Follow the instructions on
    the `ThirdPartySystems wiki page
    <https://wiki.openstack.org/wiki/ThirdPartySystems>`_ to add your
    system.  When complete, there should be a page dedicated to your
    system with a URL like:
    ``https://wiki.openstack.org/wiki/ThirdPartySystems/Example``.
  * All comments from your CI system must contain a link to the wiki
    page for your CI system.
  * Maintainers are encouraged to be in IRC regularly to make it
    faster to contact them.

* Include a public link to all test artifacts to make debugging failed tests
  easier (using a dns name over a hardcoded ip is recommended).
  This should include:

  * Environment details

    * This must include a utc timestamp of the test run
  * Test configuration

    * Skipped tests
    * logs should include a trace of the commands used
  * OpenStack logs
  * Tempest logs (including ``testr_results.html.gz``)

    * logs must be browsable; logs requiring download, installation or login
      to access are not acceptable

  .. note:: All test artifacts must be retained for one month.

Reading the Event Stream
------------------------

It is possible to use ssh to connect to ``review.openstack.org`` on port 29418
with your ssh key if you have a normal reviewer account in Gerrit.

This will give you a real-time JSON stream of events happening inside Gerrit.
For example:

.. code-block:: bash

   $ ssh -p 29418 USERNAME@review.openstack.org gerrit stream-events

Will give a stream with an output like this (line breaks and
indentation added in this document for readability, the real JSON will
be all one line per event):

.. code-block:: javascript

   {"type":"comment-added","change":
     {"project":"openstack/keystone","branch":"stable/essex","topic":"bug/969088","id":"I18ae38af62b4c2b2423e20e436611fc30f844ae1","number":"7385","subject":"Make import_nova_auth only create roles which don\u0027t already exist","owner":
       {"name":"Chuck Short","email":"chuck.short@canonical.com","username":"zulcss"},"url":"https://review.openstack.org/7385"},
     "patchSet":
       {"number":"1","revision":"aff45d69a73033241531f5e3542a8d1782ddd859","ref":"refs/changes/85/7385/1","uploader":
         {"name":"Chuck Short","email":"chuck.short@canonical.com","username":"zulcss"},
       "createdOn":1337002189},
     "author":
       {"name":"Mark McLoughlin","email":"markmc@redhat.com","username":"markmc"},
     "approvals":
       [{"type":"CRVW","description":"Code Review","value":"2"},{"type":"APRV","description":"Approved","value":"0"}],
   "comment":"Hmm, I actually thought this was in Essex already.\n\nIt\u0027s a pretty annoying little issue for folks migrating for nova auth. Fix is small and pretty safe. Good choice for backporting"}

For most purposes you will want to trigger on ``patchset-created`` for when a
new patchset has been uploaded.

Further documentation on how to use the events stream can be found in `Gerrit's stream event documentation page <http://gerrit-documentation.googlecode.com/svn/Documentation/2.3/cmd-stream-events.html>`_.

Posting Result To Gerrit
------------------------

External testing systems can give non-gating votes to Gerrit by means
of a -1/+1 verify vote.  OpenStack Jenkins has extra permissions to
give a +2/-2 verify vote which is gating.  Comments should also be
provided to explain what kind of test failed.  We do also ask that the
comments contain public links to the failure so that the developer can
see what caused the failure.

An example of how to post this is as follows:

.. code-block:: bash

   $ ssh -p 29418 USERNAME@review.openstack.org gerrit review -m '"Test failed on MegaTestSystem <http://megatestsystem.org/tests/1234>"' --verified=-1 c0ff33

In this example ``c0ff33`` is the commit ID for the review.  You can
set the verified to either `-1` or `+1` depending on whether or not it
passed the tests.

Further documentation on the `review` command in Gerrit can be found in the `Gerrit review documentation page <http://gerrit-documentation.googlecode.com/svn/Documentation/2.3/cmd-review.html>`_.

We do suggest cautious testing of these systems and have a development Gerrit
setup to test on if required.  In SmokeStack's case all failures are manually
reviewed before getting pushed to OpenStack, while this may not scale it is
advisable during the initial testing of the setup.

There are several triggers that gerrit will match to alter the
formatting of comments.  The raw regular expressions can be seen in
`gerrit.pp <https://git.openstack.org/cgit/openstack-infra/system-config/tree/modules/openstack_project/manifests/gerrit.pp>`_.
For example, to have your test results formatted in the same manner as
the upstream Jenkins results, use a template for each result matching::

  * test-name-no-spaces http://link.to/result : [SUCCESS|FAILURE] some comment about the test

.. _request-account-label:

Creating a Service Account
--------------------------

In order to post comments as a Third Party CI System and eventually verify
your build status on Gerrit patches, you will need a dedicated Gerrit
CI account. You will need to create this account in our OpenID provider
`Launchpad <https://launchpad.net>`_. You may already have an existing
personal account in Launchpad, but you should create a new and entirely
separate account for this purpose.

Once you have created this account with the OpenID provider you can log
into Gerrit with that new account as you would with your normal user
account. Once logged in you will need to do several things:

  1. Set an SSH username at https://review.openstack.org/#/settings/ if
  it isn't already set. This is the username your CI system will use to
  SSH to Gerrit in order to read the event stream.

  2. Set the account's fullname at https://review.openstack.org/#/settings/contact
  This name should follow a few rules in order to make it clear in Gerrit
  comments what this CI system exists to test. The name should have three
  pieces ``Organization`` ``Product/technology`` ``CI designator``. The
  organization value should be your company name or other organization
  affiliation. Product/technology should describe the product or technology
  you are testing in conjunction with OpenStack. This should be the name of
  a component which cannot be tested in the official OpenStack
  infrastructure (requires particular physical hardware, proprietary
  software, some hypervisor feature not available in public clouds,
  et cetera). Note this should not be the name of an OpenStack project but
  rather the thing you are testing with OpenStack projects. And finally
  the CI designator is used to denote this is a CI system so that automatic
  Gerrit comment parsers can filter these comments out. This value should
  be ``CI`` for most CI systems but can be ``Bot`` if you are not
  performing continuous integration. An example of a proper name would be
  something like ``IBM DB2 CI``.

  3. Add the SSH public key you will be using to the Gerrit account at
  https://review.openstack.org/#/settings/ssh-keys You can generate an
  ssh key using ``ssh-keygen``. You want to give Gerrit the contents of
  the generated id_rsa.pub file.

Note you should also subscribe to the `third-party-announce
<http://lists.openstack.org/cgi-bin/mailman/listinfo/third-party-announce>`_
list to keep on top of announcements there which can include account
disablement notices.

It would also be a good idea to contact the `Third Party Coordinators
<https://review.openstack.org/#/admin/groups/440>`_ asking to add your account
to the `Third Party CI mail filter list
<https://review.openstack.org/#/admin/groups/270>`_. This is necessary to keep
Gerrit from sending email messages every time an account comments on a patch.

Once you have done this you will have everything you need to comment on
Gerrit changes from our CI system but you will not be able to vote +/-1
Verified on changes. To get voting rights you will need to get the release
group of the project you are testing to add you to their project specific
<project>-ci group. Please contact the project in question when you are
ready to start voting and they can add you to this group.

The Jenkins Gerrit Trigger Plugin Way
-------------------------------------

There is a Gerrit Trigger plugin for Jenkins which automates all of the
processes described in this document.  So if your testing system is Jenkins
based you can use it to simplify things.  You will still need an account to do
this as described in the :ref:`request-account-label` section above.

The Gerrit Trigger plugin for Jenkins can be found on `the Jenkins
repository`_.  You can install it using the Advanced tab in the
Jenkins Plugin Manager.

.. _the Jenkins repository: http://repo.jenkins-ci.org/repo/com/sonyericsson/hudson/plugins/gerrit/gerrit-trigger/

Once installed Jenkins will have a new `Gerrit Trigger` option in the `Manage
Jenkins` menu.  This should be given the following options::

  Hostname: review.openstack.org
  Frontend URL: https://review.openstack.org/
  SSH Port: 29418
  Username: (the Gerrit user)
  SSH Key File: (path to the user SSH key)

  Verify
  ------
  Started: 0
  Successful: 1
  Failed: -1
  Unstable: 0

  Code Review
  -----------
  Started: 0
  Successful: 0
  Failed: 0
  Unstable: 0

  (under Advanced Button):

  Stated: (blank)
  Successful: gerrit approve <CHANGE>,<PATCHSET> --message 'Build Successful <BUILDS_STATS>' --verified <VERIFIED> --code-review <CODE_REVIEW>
  Failed: gerrit approve <CHANGE>,<PATCHSET> --message 'Build Failed <BUILDS_STATS>' --verified <VERIFIED> --code-review <CODE_REVIEW>
  Unstable: gerrit approve <CHANGE>,<PATCHSET> --message 'Build Unstable <BUILDS_STATS>' --verified <VERIFIED> --code-review <CODE_REVIEW>

Note that it is useful to include something in the messages about what testing
system is supplying these messages.

When creating jobs in Jenkins you will have the option to add triggers.  You
should configure as follows::

  Trigger on Patchset Uploaded: ticked
  (the rest unticked)

  Type: Plain
  Pattern: openstack/project-name (where project-name is the name of the project)
  Branches:
    Type: Path
    Pattern: **

This job will now automatically trigger when a new patchset is
uploaded and will report the results to Gerrit automatically.

The Zuul Gerrit Trigger Way
---------------------------

`Zuul <http://ci.openstack.org/zuul.html>`_ is a tool that determines what jobs are run when.
Zuul listens to the Gerrit event stream, and first tries to match each event to one or more pipelines.
Zuul’s pipelines are configured in a single file called layout.yaml.
Here’s a snippet from that file that constructs the ``check`` pipeline taken from this
`Zuul sample layout.yaml file <https://git.openstack.org/cgit/openstack-infra/zuul/tree/etc/layout.yaml-sample>`_

.. code-block:: yaml

    pipelines:
      - name: check
        manager: IndependentPipelineManager
        trigger:
          gerrit:
            - event: patchset-created
        success:
          gerrit:
            verified: 1
        failure:
         gerrit:
            verified: -1


This pipeline is configured to trigger on any Gerrit event that represents a new
patch set created. The matching event will invoke the configured Jenkins job(s)
(discussed next). If all the Jenkins jobs are successful, Zuul will add a comment
to Gerrit with a ``verified +1`` vote, and if any one fails, with a ``verified -1``.

The sample includes other possible configurations, or you can configure your own by
following the `Zuul layout documentation <http://ci.openstack.org/zuul/zuul.html#layout-yaml>`_

After a Gerrit event matches a pipeline, Zuul will look at the project identified
in that Gerrit event and invoke the Jenkins jobs specified in the ``projects`` section
(for the matching pipeline) using the `Jenkins Gearman Plugin
<https://wiki.jenkins-ci.org/display/JENKINS/Gearman+Plugin>`_.

For example:

.. code-block:: yaml

    projects:
      - name: openstack-dev/ci-sandbox
        check:
          - my-sandbox-check
        test:
          - my-sandbox-test


In this case, any Gerrit event generated from the ``openstack-dev/ci-sandbox`` project, that matched
the ``check`` pipeline would run the ``my-sandbox-check`` job in Jenkins. If the
Gerrit event also matched the ``test`` pipeline, Zuul would also invoke the ``my-sandbox-test``
Jenkins job.

The `layout.yaml <https://git.openstack.org/cgit/openstack-infra/project-config/tree/zuul/layout.yaml>`_
used by OpenStack is a good reference for real world pipeline definitions,
and project-pipeline-job definitions.

Managing Jenkins Jobs
---------------------
When code is pushed to Gerrit, a series of jobs are triggered that run a series
of tests against the proposed code. `Jenkins <http://ci.openstack.org/jenkins.html>`_
is the server that executes and
manages these jobs. It is a Java application with an extensible architecture
that supports plugins that add functionality to the base server.

Each job in Jenkins is configured separately. Behind the scenes, Jenkins stores
this configuration information in an XML file in its data directory.
You may manually edit a Jenkins job as an administrator in Jenkins. However,
in a testing platform as large as the upstream OpenStack CI system,
doing so manually would be virtually impossible and fraught with errors.
Luckily, there is a helper tool called `Jenkins Job Builder (JJB)
<http://ci.openstack.org/jenkins-job-builder/>`_ that
constructs and manages these XML configuration files after reading a
set of YAML files and job templating rules. These references provide more details:

* `A basic overview of using JJB to define projects, templates, and jobs in yaml
  format is available here. <http://ci.openstack.org/jjb.html>`_

* `The official documentation to define Jenkins jobs using JJB is here.
  <http://ci.openstack.org/jenkins-job-builder/definition.html>`_

* `The JJB description of all jobs used by OpenStack are defined in this folder.
  <https://git.openstack.org/cgit/openstack-infra/project-config/tree/jenkins/jobs>`_
  (The projects.yaml file is a good starting point)

Testing your CI setup
---------------------

You can use the ``openstack-dev/ci-sandbox`` project to test your external CI
infrastructure with OpenStack's Gerrit. By using the sandbox project you
can test your CI system without affecting regular OpenStack reviews.

Once you confirm your CI system works as you expect, change your
configuration of the gerrit trigger plugin or zuul to subscribe to gerrit
events from your target project.

Permissions on your Third Party System
--------------------------------------

When you create your CI account it will have no special permissions.
This means it can comment on changes but generally not vote +/-1
Verified on any changes. The exception to this is on the
``openstack-dev/ci-sandbox`` project. Any account is able to vote +/-1
Verified on that account and it provides a way to test your CI's voting
abilities before you vote on other projects.

.. _openstack-dev/ci-sandbox: https://git.openstack.org/cgit/openstack-dev/ci-sandbox/

The OpenStack Infrastructure team disables mis-behaving third-party ci
accounts at its discretion. This documentation endeavours to outline specific
circumstances that may lead to an account being disabled. There have been
times when third-party ci systems behave in ways we didn't envision
and therefore were unable to document prior to the event. If your
third-party ci system has been disabled, check the archives of the
`third-party-announce
<http://lists.openstack.org/cgi-bin/mailman/listinfo/third-party-announce>`_
mailing list to which you hopefully are subscribed. The email that notifies
this list that your account has been disabled will include instructions for
getting your system re-enabled. You are also welcome to join us in the
#openstack-infra irc channel on freenode to discuss your situation.

In order to get your Third Pary CI account to have voting permissions on
repos in gerrit in addition to ``openstack-dev/ci-sandbox`` you have a greater
chance of success if you follow these steps:

* Set up your system and test it according to "Testing your CI setup" outlined
  above (this will create a history of activity associated with your account
  which will be evaluated when you apply for voting permissions).

* Post comments, that adhere to the "Requirements" listed above, that
  demonstrate the format for your system communication to the repos
  you want your system to test.

* Once your Third Party Account has a history on gerrit so that others
  can evaluate your format for comments, and the stability of your
  voting pattern (in the sandbox repo):

  * send an email to the openstack-dev mailing list nominating your
    system for voting permissions

      * openstack-dev@lists.openstack.org
      * use tags [Infra][Nova] for the Nova program, please replace
        [Nova] with [Program], where [Program] is the name of the
        program your CI account will test

  * present your account history
  * address any questions and concerns with your system

* If the members of the program you want voting permissions from agree
  your system should be able to vote, the release group for that program
  or project can add you to the <project>-ci group specific to that
  program/project.

FAQ (Frequently Asked Questions)
--------------------------------

* Q: How do you serve the content of compressed logs so they are rendered within
     the browser, rather than presenting a download prompt to the user?

  A: Add the following lines to your web server conf file::

        RewriteEngine On
        RewriteCond   %{HTTP:Accept-Encoding} gzip
        RewriteCond   %{LA-U:REQUEST_FILENAME}.gz -f
        RewriteRule   ^(.+)$ $1.gz [L]
        <FilesMatch ".*\.gz$">
          ForceType text/html
          AddDefaultCharset UTF-8
          AddEncoding x-gzip gz
        </FilesMatch>

