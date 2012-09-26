Meetbot
==============

Overview
--------

The OpenStack CI team run a slightly modified
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
have Puppet do the heavy lifting. The OpenStack CI Meetbot Puppet module creates
a configuration and documentation for that module is at
:ref:`Meetbot_Puppet_Module`.

One important config setting is ``supybot.reply.whenAddressedBy.chars``, which
sets the prefix character for this bot. This should be set to something other
than ``#`` as ``#`` will conflict with Meetbot (you can leave the setting blank
if you don't want a prefix character). 

Meetbot
-------

The OpenStack CI Meetbot fork can be found at
https://github.com/openstack-ci/meetbot. Manual installation of the Meetbot
plugin is straightforward and documented in that repository's README.
OpenStack CI installs and configures Meetbot through Puppet. Documentation for
the Puppet module that does that can be found at :ref:`Meetbot_Puppet_Module`.

Voting
^^^^^^

The OpenStack CI Meetbot fork adds simple voting features. After a meeting has
been started a meeting chair can begin a voting block with the ``#startvote``
command. The command takes two arguments, a question posed to voters (ending
with a ``?``), and the valid voting options. If the second argument is missing
the default options are "Yes" and "No". For example:

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
