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

Ansible
=======

Ansible is used in many places in the community infrastructure we have mqtt
events emitted from ansible being run on :ref:`puppetmaster.openstack.org`.
These are events are generated using a `MQTT Ansible Callback Plugin`_.

.. _MQTT Ansible Callback Plugin: http://git.openstack.org/cgit/openstack-infra/system-config/tree/modules/openstack_project/files/puppetmaster/mqtt.py

Topics
------

The topics for ansible are a bit more involved than some of the other services
publishing to firehose. It depends on the type of event that ansible just
finished. There are 3 categories of events which have slightly different topic
formulas (and payloads).

Playbook Events
'''''''''''''''
Whenever a playbook action occurs the callback plugin will emit an event for
it. The topics for playbook events fall into this pattern::

    ansible/playbook/<playbook uuid>/action/<playbook action>/<status>

``playbook uuid`` is pretty self explanatory here, it's the uuid ansible uses 
to uniquely identify the playbook being run. ``playbook action`` is the action
that the event is for, this is either going to be ``start`` or ``finish``.
``status`` is only set on ``finish`` and will be one of the following:

 * ``OK``
 * ``FAILED``
   
to indicate whether the playbook succesfully executed or not.

Playbook Stats Events
'''''''''''''''''''''

At the end of a playbook these events are emitted for each host that tasks were
run on. The topics for these events fall into the following pattern::

    ansible/playbook/<playbook uuid>/stats/<hostname>

In this case ``playbook uuid`` is the same as above and the internal ansible
unique playbook identifier. ``hostname`` here is the host that ansible was
running tasks on as part of the playbook.

Task Events
'''''''''''

At the end of each individual task the callback plugin will emit an event. Those
events' topics fall into the following pattern::

    ansible/playbook/<playbook uuid>/task/<hostname>/<status>

``playbook uuid`` is the same as in the previous 2 event types. ``hostname`` is
the hostname the task was executed on. ``status`` is the result of the task
and will be one of the following:

 * ``OK``
 * ``FAILED``
 * ``UNREACHABLE``

Payload
-------

Just as with the topics the message payloads depend on the event type. Each
event uses a JSON payload with slightly different fields.

Playbook Events
'''''''''''''''

For playbook events the payload falls into this schema on playbook starts::

    {
        'status': 'OK',
        'host': <hostname>
        'session': <session id>,
        'playbook_name': <playbook name>,
        'playbook_id': <playbook uuid>,
        'ansible_type': 'start',
    }

When a playbook finishes the payload is slightly smaller and the schema is::

    {
        'playbook_id': <playbook uuid>,
        'playbook_name': <playbook name>,
        'status': <status>,
    }

In both cases ``playbook uuid`` is the same field from the topic.
``playbook name`` is the human readable name for the playbook. If one is
set in the playbook this will be that. ``status`` will be whether the
playbook was successfully executed or not. It will always be 'OK' on starts
(otherwise the event isn't emitted) but on failures, just like in the topic,
this will be one of the following:

 * ``OK``
 * ``FAILED``

``session id`` is a UUID generated by the callback plugin to uniquely identify
the execution of the playbook. ``hostname`` is the hostname where the ansible
playbook was launched. (which is not necessarily where tasks are being run)


An example of this from the system is for a start event::

    {
        "status": "OK",
        "playbook_name": "localhost:!disabled",
        "ansible_type": "start",
        "host": "puppetmaster.openstack.org",
        "session": "14d6e568-2c75-11e7-bd24-bc764e048db9",
        "playbook_id": "5a95e9da-8d33-4dbb-a8b3-a77affc065d0"
    }

and for a finish::

    {
        "status": "FAILED",
        "playbook_name": "compute*.ic.openstack.org:!disabled",
        "playbook_id": "b259ac6d-6cb5-4403-bb8d-0ff2131c3d7a"
    }


Playbook Stats Events
'''''''''''''''''''''

The schema for stats events is::

    {
        'host': <hostname>,
        'ansible_host': <execute hostname>,
        'playbook_id': <playbook uuid>,
        'playbook_name': <playbook name>,
        'stats': {
            "unreachable": int,
            "skipped": int,
            "ok": int,
            "changed": int,
            "failures": int,
        }
    }

In both cases ``playbook uuid`` is the same field from the topic.
``playbook name`` is the human readable name for the playbook. If one is
set in the playbook this will be that.



An example from the running system is::

    {
        "playbook_name": "compute*.ic.openstack.org:!disabled",
        "host": "puppetmaster.openstack.org",
        "stats": {
            "unreachable": 0, 
            "skipped": 5,
            "ok": 13,
            "changed": 1,
            "failures": 0
        },
        "playbook_id": "b259ac6d-6cb5-4403-bb8d-0ff2131c3d7a",
        "ansible_host": "controller00.vanilla.ic.openstack.org"
    }


Task Events
'''''''''''

An example of a task event from the running system is::

    {
        "status": "OK",
        "host": "puppetmaster.openstack.org",
        "session": "092aa3fa-2c73-11e7-bd24-bc764e048db9",
        "playbook_name": "compute*.ic.openstack.org:!disabled",
        "ansible_result": {
            "_ansible_parsed": true,
            "_ansible_no_log": false,
            "stdout": "",
            "changed": false,
            "stderr": "",
            "rc": 0,
            "invocation": {
                "module_name": "puppet",
                "module_args": {
                    "logdest": "syslog",
                    "execute": null,
                    "facter_basename": "ansible",
                    "tags": null,
                    "puppetmaster": null,
                    "show_diff": false,
                    "certname": null,
                    "manifest": "/opt/system-config/production/manifests/site.pp",
                    "environment": "production",
                    "debug": false,
                    "noop": false,
                    "timeout": "30m",
                    "facts": null
                }
            },
            "stdout_lines": []
        },
        "ansible_type": "task",
        "ansible_task": "TASK: puppet : run puppet",
        "playbook_id": "b259ac6d-6cb5-4403-bb8d-0ff2131c3d7a",
        "ansible_host": "compute014.chocolate.ic.openstack.org"
    }

