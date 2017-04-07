:title: Firehose Schema

.. _firehose_schema:

Firehose Schema
###############

This attempts todocuments the topic and payload schema for all the services
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
by gerrit's event stream command. The only difference is that the ``type:``
field is not present because it is used in the topic. Instead of repeating
the entire gerrit schema doc here just refer to gerrit's docs on the
`JSON payload`_ which documents the contents of each JSON object and refer to
the doc on `Gerrit events`_ for which JSON objects are included with which
event type.

.. _JSON payload: https://review.openstack.org/Documentation/json.html
.. _Gerrit events: https://review.openstack.org/Documentation/cmd-stream-events.html#events

