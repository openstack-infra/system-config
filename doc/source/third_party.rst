Third Party Testing
===================

Overview
--------

Gerrit has an event stream which can be subscribed to, using this it is possible
to test commits against testing systems beyond those supplied by OpenContrail's
Jenkins setup.  It is also possible for these systems to feed information back
into Gerrit and they can also leave non-gating votes on Gerrit review requests.

An example of one such system is `Smokestack <https://smokestack.opencontrail.org/>`_.
Smokestack reads the Gerrit event stream and runs it's own tests on the commits.
If one of the tests fails it will publish information and links to the failure
on the review in Gerrit.

You can view a list of current 3rd party testing accounts and the relevant
contact information for each account in the `Gerrit group for 3rd party
testing <https://review.opencontrail.org/#/admin/groups/270,members>`_ (you must
be signed in to Gerrit to view this page).

Requirements
------------

* Until a third party testing system operates in a stable fashion, third
  party tests can comment on patches but not vote on them.

  * A system can also be set up to only do '+1' reviews and leave all the
    '-1's to be manually confirmed.
* The maintainers are responsible for re-triggering tests when their third
  party testing system breaks.
* Support recheck to request re-running a test.

  * Support the following syntaxes ``recheck no bug`` and ``recheck bug ###``.
  * Recheck means recheck everything. A single recheck comment should
    re-trigger all testing systems.
* Publish who the maintainers of the third party testing system are, and make
  them available for support as needed. Maintainers are encouraged to be
  in IRC regularly to make it faster to contact them.

  * All CI comments must contain a link to a contact page with the details.
* Include a public link to all test artifacts to make debugging failed tests
  easier. This should include:

  * Environment details
  * Test configuration

    * Skipped tests
    * logs should include a trace of the commands used
  * OpenContrail logs
  * Tempest logs (including ``testr_results.html.gz``)


Reading the Event Stream
------------------------

It is possible to use ssh to connect to ``review.opencontrail.org`` on port 29418
with your ssh key if you have a normal reviewer account in Gerrit.

This will give you a real-time JSON stream of events happening inside Gerrit.
For example:

.. code-block:: bash

   $ ssh -p 29418 review.example.com gerrit stream-events

Will give a stream with an output like this (line breaks and indentation added
in this document for readability, the read JSON will be all one line per event):

.. code-block:: javascript

   {"type":"comment-added","change":
     {"project":"opencontrail/keystone","branch":"stable/essex","topic":"bug/969088","id":"I18ae38af62b4c2b2423e20e436611fc30f844ae1","number":"7385","subject":"Make import_nova_auth only create roles which don\u0027t already exist","owner":
       {"name":"Chuck Short","email":"chuck.short@canonical.com","username":"zulcss"},"url":"https://review.opencontrail.org/7385"},
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

External testing systems can give non-gating votes to Gerrit by means of a -1/+1
verify vote.  OpenContrail Jenkins has extra permissions to give a +2/-2 verify
vote which is gating.  Comments should also be provided to explain what kind of
test failed..  We do also ask that the comments contain public links to the
failure so that the developer can see what caused the failure.

An example of how to post this is as follows:

.. code-block:: bash

   $ ssh -p 29418 review.example.com gerrit review -m '"Test failed on MegaTestSystem <http://megatestsystem.org/tests/1234>"' --verified=-1 c0ff33

In this example ``c0ff33`` is the commit ID for the review.  You can set the
verified to either `-1` or `+1` depending on whether or not it passed the tests.

Further documentation on the `review` command in Gerrit can be found in the `Gerrit review documentation page <http://gerrit-documentation.googlecode.com/svn/Documentation/2.3/cmd-review.html>`_.

We do suggest cautious testing of these systems and have a development Gerrit
setup to test on if required.  In SmokeStack's case all failures are manually
reviewed before getting pushed to OpenContrail, whilst this may no scale it is
advisable during initial testing of the setup.

.. _request-account-label:

Requesting a Service Account
----------------------------

Feel free to contact the OpenContrail Infrastructure Team via
`email <mailto:opencontrail-infra@lists.opencontrail.org>`_,
`bug report <https://bugs.launchpad.net/opencontrail-ci/>`_
or in the #opencontrail-infra IRC channel to arrange setting up a dedicated user
(so your system can post reviews and vote using a system name rather than your
user name). We'll want a few additional details:

  1. The public SSH key described above (if using OpenSSH, this would be the
  full contents of the account's ~/.ssh/id_rsa.pub file after running
  'ssh-keygen'). You can attach it to this bug or reply with a hyperlink to
  where you've published it so I can retrieve it. This is a non-sensitive piece
  of data, and it's safe for it to be publicly visible.

  2. A preferred (short, alphanumeric) username you want to use for the new SSH
  account. This is the username you'll use when connecting to Gerrit via SSH.

  3. (optional) A human-readable display name for your testing system, shown on
  comments and votes in Gerrit.

  4. (optional) A unique contact E-mail address or alias for this system, which
  can not be in use as a contact address for any other Gerrit accounts on
  review.opencontrail.org (Gerrit doesn't deal well with duplicate E-mail
  addresses between accounts). This is so that contributors and reviewers can
  see how to get in touch with people who might be able to fix problems with
  the system if it starts leaving erroneous votes.

The Jenkins Gerrit Trigger Plugin Way
-------------------------------------

There is a Gerrit Trigger plugin for Jenkins which automates all of the
processes described in this document.  So if your testing system is Jenkins
based you can use it to simplify things.  You will still need an account to do
this as described in the :ref:`request-account-label` section above.

The Gerrit Trigger plugin for Jenkins can be found on
`the Jenkins repository <http://repo.jenkins-ci.org/repo/com/sonyericsson/hudson/plugins/gerrit/gerrit-trigger/>`_.
You can install it using the Advanced tab in the Jenkins Plugin Manager.

Once installed Jenkins will have a new `Gerrit Trigger` option in the `Manage
Jenkins` menu.  This should be given the following options::

  Hostname: review.opencontrail.org
  Frontend URL: https://review.opencontrail.org/
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
  Pattern: opencontrail/project-name (where project-name is the name of the project)
  Branches:
    Type: Path
    Pattern: **

This job will now automatically trigger when a new patchset is uploaded and will
report the results to Gerrit automatically.

Testing your CI setup
---------------------

You can use ``opencontrail-dev/sandbox`` project to test your external CI
infrastructure with OpenContrail Gerrit system. By using sandbox project you
can test your CI system without affecting regular OpenContrail reviews.

Once you confirm your CI system works as you expected, change your
configuration of gerrit trigger plugin or zuul to subscribe gerrit events
from your target project.
