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
  * :config:`accessbot/channels.yaml`
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

`Register the channel with ChanServ
<https://freenode.net/news/registering-a-channel-on-freenode>`_ and give the
infrastructure team account founder access to the channel with::

  /msg chanserv register #channel
  /msg chanserv set #channel guard on
  /msg chanserv access #channel add openstackinfra +AFRefiorstv

This is good practice project-wide to make sure we keep channels under
control and is a requirement if you want any of the project bots in
your channel.

Join #openstack-infra if you have any trouble with any of these commands.

NOTE: Channel admin should issue the access commands above BEFORE adding
channel to gerritbot and accessbot, otherwise Jenkins will fail tests.

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

Starting a Meeting
^^^^^^^^^^^^^^^^^^

To start a meeting, use the command ``#startmeeting`` followed by the
meeting name.  For instance, if you are having a meeting of the
marketing committee use the command ``#startmeeting Marketing
Committee``.  This will cause logs to automatically be placed in a
meeting-specific directory on the eavesdrop log server.  The output
directory will be automatically lowercased and non-alphanumeric
characters translated to '_', so the above example will record to the
``marketing_committee`` directory.  Be sure to use a consistent
meeting name to ensure logs are recorded to the same location.

This feature is specific to the OpenStack Infrastructure Meetbot fork.

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

One can check the current vote tallies using the ``#showvote`` command, which
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

The configuration for specific channel logging can be found in the
public Hiera data file, :file:`hiera/common.yaml`.

.. _statusbot:

Statusbot
=========

Statusbot is used to distribute urgent information from the
Infrastructure team to OpenStack channels.  It updates the
`Infrastructure Status wiki page
<https://wiki.openstack.org/wiki/Infrastructure_Status>`_.

It supports the following public message commands when issued by
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

It supports the following commands when issued by any IRC user from
the channels the bot is listening to:

#success [MESSAGE]
  Log a message of success to the "Successes" wiki page. This is meant
  as a collection mechanism for little celebration of small successes
  in OpenStack development.

A channel can be added to statusbot by editing the public Hiera data
file, :file:`hiera/common.yaml`.

The wiki password for the StatusBot account can be (re)set using the
`ChangePassword.php <https://www.mediawiki.org/wiki/Manual:ChangePassword.php>`_
maintenance script.

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

.. _accessbot:

Accessbot
=========

Accessbot defines access that should apply to all channels. Teams can add new
channel to accessbot/channels.yaml and optionally keep channel operator
permissions to the channel by specifying the full_mask option.

Accessbot's configuration is in :config:`accessbot/channels.yaml`

Example:

::

  - name: openstack-third-party-ci
    mask: full_mask

Basic Channel Operator Commands
===============================

This is not a comprehensive overview of commands available to individuals
running IRC channels on Freenode, but a basic overview of some of the common
commands which may be required for channel operators.

Operator status is sometimes required to perform certain commands in your
channel (though most everything can be done through `/msg chanserv` commands
instead if permission flags are set correctly). To give yourself operator
status in a channel, use the following command:

  /msg chanserv op #channel

You don't need to become an operator to change the topic, this can be done
via Chanserv:

  /msg chanserv topic #channel New topic goes here.

If you are curious as to who has access to a channel, you can issue this
command:

  /msg chanserv access #channel list

Visit the `Freenode Channel Guidelines <https://freenode.net/changuide>`_
for more information about recommended strategies for running channels on
Freenode.

Banning Disruptive Users
========================

The easiest and fastest solution to indefinitely ban an abusive user from a
channel is to add them to Chanserv's auto-kick list like so::

  /msg chanserv akick <channel_name> add <nick> [optional reason]

This will immediately and anonymously kick them from the channel, and prevent
them from rejoining until explicitly removed from the akick list again.

On some networks, the preferred mechanism for removing a user from a channel is
a kick. Freenode also supports the "remove" command which is a gentler way to
simply send a part-like command to the user's client. In most cases, this will
signal the client not to try to rejoin. Syntax for the removal command is as
follows (you must be an operator)::

  /quote remove #channel nickname :Reason goes here

Note the colon in the syntax, if this is omitted only the first word will
accompany the removal message.

Banning of disruptive users is also available with the `/ban` command, see your
client documentation for syntax.

Renaming an IRC Channel
=======================

First, follow the procedure for creating a new channel, including submitting
the appropriate changes to Gerrit for logging, accessbot, etc and adding the
proper credentials for the openstackinfra account.

The following commands start the process of renaming of the channel, they
need to be run by a founder of the channels or a member of infra-root::

  /MSG ChanServ op #openstack-project-old
  /MSG ChanServ op #openstack-project-new
  /TOPIC ##openstack-project-old We have moved to #openstack-project-new, please
    /part and then type /join #openstack-project-new to get to us
  /MSG ChanServ SET #openstack-project-old GUARD ON
  /MSG ChanServ SET #openstack-project-old MLOCK +tnsmif #openstack-project-new
  /MSG ChanServ SET #openstack-project-old TOPICLOCK ON
  /MSG ChanServ SET #openstack-project-old PRIVATE ON

Once that is complete, all new attempts to join the old channel will be
automatically redirected to the new channel. No one can rejoin the old
channel.

Tips
----

 * Collect the list of users and send a message in channel to each of them
   explaining that the channel has moved.
 * Some folks simply won't leave and join the new channel, you can /kick
   them after a bit of time (a day? a week?) to get their client to join
   the new channel.
 * Don't leave the channel until everything is done, it's non-trivial to
   rejoin because you've set up a forward!

Troubleshooting
===============

Bots may stop responding, common steps to troubleshoot the problem are:

1. Check status of the bot, with:

    service xxxbot status

If bot is stopped, start it again. Restart the bot if you see it's running
but not operating properly.

2. On bot restart, it may show problems connecting to chat.freenode.net.
If bot logs show it's stopped on connection, you can manually try with:

    telnet chat.freenode.net 6667

3. For bots on the eavesdrop server: if you don't have connection to that
port, check entries on /etc/hosts for chat.freenode.net, until you find one
server that is operative. Switch the entries on /etc/hosts to choose
the right one, and restart the service with:

    sudo service xxxbot restart
