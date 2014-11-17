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

An example of one such system is `Smokestack <https://smokestack.openstack.org/>`_.
Smokestack reads the Gerrit event stream and runs its own tests on the commits.
If one of the tests fails it will publish information and links to the failure
on the review in Gerrit.

You can view a list of current 3rd party testing accounts and the relevant
contact information for each account in the `Gerrit group for 3rd party
testing <https://review.openstack.org/#/admin/groups/270,members>`_ (you must
be signed in to Gerrit to view this page). All accounts must have a wikipage
entry `on this page <https://wiki.openstack.org/wiki/ThirdPartySystems>`_.
Details are below under Requirements.

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

  * Follow the instructions on the `ThirdPartySystems wiki page
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

Requesting a Service Account
----------------------------

In order to post comments as a Third Party CI System and eventually verify
your build status on Gerrit patches, you will need a dedicated Gerrit
system account. This account is created by a member of the OpenStack
Infrastructure team, you are unable to create this account yourself. This
account has no access via the GUI to modify settings.

You will need to subscribe to two mailing lists `third-party-announce
<http://lists.openstack.org/cgi-bin/mailman/listinfo/third-party-announce>`_
to be aware if your system is disabled and `third-party-requests
<http://lists.openstack.org/cgi-bin/mailman/listinfo/third-party-requests>`_
to request your dedicated third party gerrit account.

When submitting your request to the third-party-requests mailing list, the
following information is necessary:

  1. The public SSH key described above (if using OpenSSH, this would be the
  full contents of the account's ~/.ssh/id_rsa.pub file after running
  'ssh-keygen'). You can attach it to the email or include a hyperlink to
  where you've published it so it can be retrieved. This is a
  non-sensitive piece of data, and it's safe for it to be publicly
  visible.

  2. Your company/organization name or acronym. If you don't have a
  company or organization name please identify this in your email,
  we will need to find an equivalent.

  3. What you are verifying: this could be a product, driver or
  application. (If this is the sole external CI for a specific
  project, run by that project's community, it's acceptable to use
  that project's name for #2 and #3 since it both indicates the
  responsible group of people and the software being tested.)

Requests typically take a week to handle after any issues/questions are
resolved. Please plan accordingly and be patient. Use an ordinary reviewer
account for testing purposes.

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

Testing your CI setup
---------------------

You can use the ``openstack-dev/sandbox`` project to test your external CI
infrastructure with OpenStack's Gerrit. By using the sandbox project you
can test your CI system without affecting regular OpenStack reviews.

Once you confirm your CI system works as you expect, change your
configuration of the gerrit trigger plugin or zuul to subscribe to gerrit
events from your target project.

Permissions on your Third Party System
--------------------------------------

When your CI account is created it will be in the `Third-Party CI Gerrit
group <https://review.openstack.org/#/admin/groups/270,members>`_.
The permissions on this group allow for commenting and voting on the
`openstack-dev/sandbox`_
repo as well as commenting without voting on other repos in gerrit.

.. _openstack-dev/sandbox: https://git.openstack.org/cgit/openstack-dev/sandbox/

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
repos in gerrit in addition to ``openstack-dev/sandbox`` you have a greater
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
  your system should be able to vote, the ptl or a core-reviewer from
  the program communicates this decision to the OpenStack
  Infrastructure team who will move your Third Party CI System to the
  `Voting Third-Party CI Gerrit group
  <https://review.openstack.org/#/admin/groups/91,members>`_.
