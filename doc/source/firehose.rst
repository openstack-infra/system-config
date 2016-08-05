:title: Firehose

.. _firehose:

Firehose
########

The unified message bus for Infra services.

At a Glance
===========

:Hosts:
  * firehose*.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-mosquitto
  * https://git.openstack.org/cgit/openstack-infra/puppet-germqtt
  * :file:`modules/openstack_project/manifests/firehose.pp`
:Projects:
  * https://mosquitto.org/
  * http://git.openstack.org/cgit/openstack-infra/germqtt/

Overview
========

The firehose is an infra run MQTT broker that is a place for any infra run
service to publish events to. The concept behind it is that if anything needs
to consume an event from an infra run service we should have a single place
to go for consuming them.

firehose.openstack.org hosts an instance of Mosquitto to be the MQTT broker
and also locally runs an instance of germqtt to publish the gerrit event
stream over MQTT.

Connection Info
---------------

firehose.openstack.org has 2 open ports for MQTT traffic:

 * **1883** - The default MQTT port
 * **80** - Uses websockets for the MQTT communication

Topics
------

Topics at a top level are set based on the name of the service publishing the
messages. The higher levels are specified by the publisher. For example::

    gerrit/openstack-infra/germqtt/comment-added

is a typical message topic on firehose. The top level 'gerrit' specifies the
service the message is from, and the rest of the message comes from germqtt
(the daemon used for publishing the gerrit events)

MQTT topics are hierarchical and you can filter your subscription on part of the
hierarchy. `[1]`_

.. _[1]: https://mosquitto.org/man/mqtt-7.html
