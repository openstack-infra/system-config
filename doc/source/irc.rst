:title: IRC Services

.. _irc:

IRC Services
############

The infrastructure team runs a number of IRC bots that are active on
OpenContrail related channels.

At a Glance
===========

:Hosts:
  * http://eavesdrop.opencontrail.org/
  * http://review.opencontrail.org/
  * https://wiki.opencontrail.org/wiki/Infrastructure_Status
:Puppet:
  * :file:`modules/meetbot`
  * :file:`modules/statusbot`
  * :file:`modules/gerritbot`
  * :file:`modules/opencontrail_project/manifests/eavesdrop.pp`
  * :file:`modules/opencontrail_project/manifests/review.pp`
:Configuration:
  * :file:`modules/gerritbot/files/gerritbot_channel_config.yaml`
:Projects:
  * http://wiki.debian.org/MeetBot
  * http://sourceforge.net/projects/supybot/
  * https://git.opencontrail.org/cgit/opencontrail-infra/meetbot
  * https://git.opencontrail.org/cgit/opencontrail-infra/gerritbot
  * https://git.opencontrail.org/cgit/opencontrail-infra/statusbot
:Bugs:
  * http://bugs.launchpad.net/opencontrail-ci

Meetbot
=======

The OpenContrail Infrastructure team run a slightly modified
`Meetbot <http://wiki.debian.org/MeetBot>`_ to log IRC channel activity and
meeting minutes. Meetbot is a plugin for
`Supybot <http://sourceforge.net/projects/supybot/>`_ which adds meeting
support features to the Supybot IRC bot.

Supybot
-------

In order to run Meetbot you will need to get Supybot. You can find the latest
release `here <http://sourceforge.net/projects/supybot/files/>`_. Once you have
extracted the release you will want to read the ``INSTALL`` and
``doc/GETTING_STARTED`` files. Those two files should have enough information to
get you going, but there are other goodies in ``doc/``.

Once you have Supybot installed you will need to configure a bot. The
``supybot-wizard`` command can get you started with a basic config, or you can
have the OpenContrail meetbot puppet module do the heavy lifting.

One important config setting is ``supybot.reply.whenAddressedBy.chars``, which
sets the prefix character for this bot. This should be set to something other
than ``#`` as ``#`` will conflict with Meetbot (you can leave the setting blank
if you don't want a prefix character).

Meetbot
-------

The OpenContrail Infrastructure Meetbot fork can be found at
https://git.opencontrail.org/cgit/opencontrail-infra/meetbot. Manual installation of the Meetbot
plugin is straightforward and documented in that repository's README.
OpenContrail Infrastructure installs and configures Meetbot through Puppet.

Voting
^^^^^^

The OpenContrail Infrastructure Meetbot fork adds simple voting features. After
a meeting has been started a meeting chair can begin a voting block with the
``#startvote`` command. The command takes two arguments, a question posed to
voters (ending with a ``?``), and the valid voting options. If the second
argument is missing the default options are "Yes" and "No". For example:

``#startvote Should we vote now? Yes, No, Maybe``

Meeting participants vote using the ``#vote`` command. This command takes a
single argument, which should be one of the options listed for voting by the
``#startvote`` command. For example:

``#vote Yes``

Note that you can vote multiple times, but only your last vote will count.

One can check the current vote tallies useing the ``#showvote`` command, which
takes no arguments. This will list the number of votes and voters for each item
that has votes.

When the meeting chair(s) are ready to stop the voting process they can issue
the ``#endvote`` command, which takes no arguments. Doing so will report the
voting results and log these results in the meeting minutes.

A somewhat contrived voting example:

::

  foo     | #startvote Should we vote now? Yes, No, Maybe
  meetbot | Begin voting on: Should we vote now? Valid vote options are Yes, No, Maybe.
  meetbot | Vote using '#vote OPTION'. Only your last vote counts.
  foo     | #vote Yes
  bar     | #vote Absolutely
  meetbot | bar: Absolutely is not a valid option. Valid options are Yes, No, Maybe.
  bar     | #vote Yes
  bar     | #showvote
  meetbot | Yes (2): foo, bar
  foo     | #vote No
  foo     | #showvote
  meetbot | Yes (1): bar
  meetbot | No (1): foo
  foo     | #endvote
  meetbot | Voted on "Should we vote now?" Results are
  meetbot | Yes (1): bar
  meetbot | No (1): foo


.. _statusbot:

Statusbot
=========

Statusbot is used to distribute urgent information from the
Infrastructure team to OpenContrail channels.  It updates the
`Infrastructure Status wiki page
<https://wiki.opencontrail.org/wiki/Infrastructure_Status>`_.  It
supports the following public message commands when issued by
authenticated and whitelisted users from the channels the bot is
listening to, including #opencontrail-infra:

#status log MESSAGE
  Log a message to the wiki page.

#status notice MESSAGE
  Broadcast a message to all OpenContrail channels, and log to the wiki
  page.

#status alert MESSAGE
  Broadcast a message to all OpenContrail channels and change their
  topics, log to the wiki page, and set an alert box on the wiki
  page (eventually include this alert box on status.opencontrail.org
  pages).

#status ok [MESSAGE]
  Remove alert box and restore channel topics, optionally announcing
  and logging an "okay" message.


.. _gerritbot:

Gerritbot
=========

Gerritbot watches the Gerrit event stream (using the "stream-events"
Gerrit command) and announces events (such as patchset-created, or
change-merged) to relevant IRC channels.

Gerritbot's configuration is in
:file:`modules/gerritbot/files/gerritbot_channel_config.yaml`.

Teams can add their channel and go through the standard code review process to
get the bot added to their channel. The configuration is organized by channel,
with each project that a channel is interested in listed under the channel.

Please also add the opencontrailinfra account as a channel founder:

/msg chanserv access #channel add opencontrailinfra +AFRfiorstv
