:title: Firehose Schema

.. _firehose_schema:

Firehose Schema
###############

This attempts to document the topic and payload schema for all the services
reporting to the firehose. However since much of what is reported to firehose
is dynamically generated it is possible this document misses a case.

Gerrit
======

Messages on firehose for gerrit are generated using the `germqtt`_ project. For
the most part these are basically identical to what gerrit returns on it's
native event stream except over MQTT.

.. _germqtt: http://git.openstack.org/cgit/openstack-infra/germqtt/

Topics
------

The topics for gerrit are generated dynamically. However, they follow a fairly
straightforward pattern. The basic formula for this is::

  gerrit/<git namespace>/<repo name>/<gerrit event>

So for example a typical topic would be::

  gerrit/openstack/nova/comment-added

The ``git namespace`` and ``repo name`` are pretty self explanatory and are just
from the git repository the change in gerrit is for. The event is defined in the gerrit event stream. You can see the full reference for topics in the Gerrit
docs for `Gerrit events`_. However, for simplicity the possible values are:

 * change-abandoned
 * change-merged
 * change-restored
 * comment-added
 * draft-published
 * hashtags-changed
 * merge-failed
 * patchset-created
 * ref-updated
 * reviewer-added
 * topic-changed

Payload
-------
The payload for gerrit messages are basically the same JSON that gets returned
by gerrit's event stream command. Instead of repeating the entire gerrit schema
doc here just refer to gerrit's docs on the `JSON payload`_ which documents the
contents of each JSON object and refer to the doc on `Gerrit events`_ for which
JSON objects are included with which event type.

.. _JSON payload: https://review.openstack.org/Documentation/json.html
.. _Gerrit events: https://review.openstack.org/Documentation/cmd-stream-events.html#events

Launchpad
=========
The messages sent to firehose for launchpad are generated using `lpmqtt`_

.. _lpmqtt: http://git.openstack.org/cgit/openstack-infra/lpmqtt/

Topics
------

The topics for lpmqtt follow a pretty simple formula::

    launchpad/<project>/<event type>/<bug number>

the ``project`` is the launchpad project name, ``event type`` will always be
"bug" (or not present). The intent of this was to be "bug" or "blueprint", but
due to limitations in launchpad getting notifications from blueprints is not
possible. The flexibility was left in the schema just in case this ever changes.
The ``bug number`` is obviously the bug number from launchpad.

It's also worth noting that only the base topic is a guaranteed field. Depending
on the notification email from launchpad some of the other fields may not be
present. In those cases the topic will be populated left to right until a
missing field is encountered.

Payload
-------

The payload of messages is dynamically generated and dependent on the
notification recieved from launchpad, and launchpad isn't always consistent in
what fields are present in those notifications.

However, for bug event types there is a standard format. The fields which
are always present for bugs (which should normally be the only message for
firehose) are:

 * commenters
 * bug-reporter
 * bug-modifier
 * bug-number
 * event-type

The remaining fields are dynamic and depend on launchpad. An example message
payload (with the body trimmed) for a bug is::

  {
    "status": "Triaged",
    "project": "octavia",
    "assignee": "email@fakedomain.com",
    "bug-reporter": "Full name (username)",
    "event-type": "bug",
    "bug-number": "1680938",
    "commenters": ["username"]
    "tags": ["rfe"],
    "importance": "Medium",
    "bug-modifier": "Full Name (username)",
    "body": "notification body, often is just bug comment or summary",
  }

Subunit Workers
===============

The messages for the subunit workers are generated directly in the
`subunit gearman worker scripts`_.

.. _subunit gearman worker scripts: http://git.openstack.org/cgit/openstack-infra/puppet-subunit2sql/tree/files/subunit-gearman-worker.py

Topics
------

The topics for the subunit workers follow a simple pattern::

    gearman-subunit/<worker hostname>/<git namespace/<repo name>/<change number>

Where  ``worker hostname`` is the host which processed the subunit file, as
of right now there are 2, subunit-worker01 and subunit-worker02, but there may
be more (or fewer) in the future. The ``git namespace`` and ``repo name`` are
pretty self explanatory, and are just for the git repo under test that the
subunit was emitted from. ``change number`` is the gerrit change number for the
job that launched the tests the subunit is for.

Payload
-------
The payload for the messages from the subunit workers is pretty straightforward
json that contains 3 fields: ``status``, ``build_uuid``, and ``source_url``.

An example is::

    {
        'status': 'success',
        'build_uuid': '45f7c1ddbfd74c6aba94662623bd61b8'
        'source_url': 'A url',
    }
