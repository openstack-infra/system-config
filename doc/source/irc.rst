:title: IRC Services

.. _irc:

IRC Services
############

The infrastructure team runs a number of IRC bots that are active on
OpenStack related channels.

At a Glance
===========

:Hosts:
  * http://eavesdrop.openstack.org/
  * http://review.openstack.org/
  * https://wiki.openstack.org/wiki/Infrastructure_Status
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-meetbot/tree/
  * https://git.openstack.org/cgit/openstack-infra/puppet-statusbot/tree/
  * https://git.openstack.org/cgit/openstack-infra/puppet-gerritbot/tree/
  * :file:`modules/openstack_project/manifests/eavesdrop.pp`
  * :file:`modules/openstack_project/manifests/review.pp`
:Configuration:
  * :config:`gerritbot/channels.yaml`
:Projects:
  * http://wiki.debian.org/MeetBot
  * http://sourceforge.net/projects/supybot/
  * https://git.openstack.org/cgit/openstack-infra/meetbot
  * https://git.openstack.org/cgit/openstack-infra/gerritbot
  * https://git.openstack.org/cgit/openstack-infra/statusbot
:Bugs:
  * https://storyboard.openstack.org/#!/project/748

Channel Requirements
====================

In general, discussion for OpenStack projects is preferred in #openstack-dev,
but there are many reasons why a team would like to have their own channel.

Access
------

Register the channel with ChanServ and give the infrastructure team account
founder access to the channel with::

  /msg chanserv access #channel add openstackinfra +AFRefiorstv

This is good practice project-wide to make sure we keep channels under
control and is a requirement if you want any of the project bots in
your channel.

Join #openstack-infra if you have any trouble with any of these commands.

Meetbot
=======

The OpenStack Infrastructure team run a slightly modified
`Meetbot <http://wiki.debian.org/MeetBot>`_ to log IRC channel activity and
meeting minutes. Meetbot is a plugin for
`Supybot <http://sourceforge.net/projects/supybot/>`_ which adds meeting
support features to the Supybot IRC bot.

Supybot
-------

In order to run Meetbot you will need to get Supybot. You can find the latest
release `here <http://sourceforge.net/projects/supybot/files/>`_. Once you have
extracted the release you will want to read the ``INSTALL`` and
``doc/GETTING_STARTED`` files. Those two files should have enough
information to get you going, but there are other goodies in ``doc/``.

Once you have Supybot installed you will need to configure a bot. The
``supybot-wizard`` command can get you started with a basic config, or you can
have the OpenStack meetbot puppet module do the heavy lifting.

One important config setting is ``supybot.reply.whenAddressedBy.chars``, which
sets the prefix character for this bot. This should be set to something other
than ``#`` as ``#`` will conflict with Meetbot (you can leave the setting blank
if you don't want a prefix character).

Meetbot
-------

The OpenStack Infrastructure Meetbot fork can be found at
https://git.openstack.org/cgit/openstack-infra/meetbot. Manual installation of the Meetbot
plugin is straightforward and documented in that repository's README.
OpenStack Infrastructure installs and configures Meetbot through Puppet.

Voting
^^^^^^

The OpenStack Infrastructure Meetbot fork adds simple voting features. After
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

Logging
^^^^^^^

Meetings are automatically logged and published at
http://eavesdrop.openstack.org/meetings/

The bot also has the ability to sit in a channel for the sole purpose
of logging channel activity, not just meetings. Standard channel logs
are sent to http://eavesdrop.openstack.org/irclogs/

The configuration for specific channel logging can be found in
:file:`modules/openstack_project/manifests/eavesdrop.pp`.

.. _statusbot:

Statusbot
=========

Statusbot is used to distribute urgent information from the
Infrastructure team to OpenStack channels.  It updates the
`Infrastructure Status wiki page
<https://wiki.openstack.org/wiki/Infrastructure_Status>`_.  It
supports the following public message commands when issued by
authenticated and whitelisted users from the channels the bot is
listening to, including #openstack-infra:

#status log MESSAGE
  Log a message to the wiki page.

#status notice MESSAGE
  Broadcast a message to all OpenStack channels, and log to the wiki
  page.

#status alert MESSAGE
  Broadcast a message to all OpenStack channels and change their
  topics, log to the wiki page, and set an alert box on the wiki
  page (eventually include this alert box on status.openstack.org
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

Gerritbot's configuration is in :config:`gerritbot/channels.yaml`

Teams can add their channel and go through the standard code review process to
get the bot added to their channel. The configuration is organized by channel,
with each project that a channel is interested in listed under the channel.
