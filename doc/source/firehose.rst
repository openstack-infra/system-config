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
  * https://git.openstack.org/cgit/openstack-infra/puppet-lpmqtt
    * :file:`modules/openstack_project/manifests/firehose.pp`
:Projects:
  * https://mosquitto.org/
  * http://git.openstack.org/cgit/openstack-infra/germqtt/
  * http://git.openstack.org/cgit/openstack-infra/lpmqtt/

Overview
========

The firehose is an infra run MQTT broker that is a place for any infra run
service to publish events to. The concept behind it is that if anything needs
to consume an event from an infra run service we should have a single place
to go for consuming them.

firehose.openstack.org hosts an instance of Mosquitto to be the MQTT broker
and also locally runs an instance of germqtt to publish the gerrit event
stream over MQTT and lpmqtt to publish a launchpad event stream over MQTT.

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

Services Publishing to firehose
-------------------------------

As of right now the following services publish messages to the firehose:

+-----------+------------+-------------------------+
| Service   | Base Topic | Source of Messages      |
+===========+============+=========================+
| gerrit    | gerrit     | `germqtt`_              |
+-----------+------------+-------------------------+
| launchpad | launchpad  | `lpmqtt`_               |
+-----------+------------+-------------------------+
+ logstash  | logstash   | `logstash-output-mqtt`_ |
+-----------+------------+-------------------------+

.. _germqtt: http://git.openstack.org/cgit/openstack-infra/germqtt/
.. _lpmqtt: http://git.openstack.org/cgit/openstack-infra/lpmqtt/
.. _logstash-output-mqtt: https://github.com/kompa3/logstash-output-mqtt


Client Usage
============
There is no outside access to publishing messages to the firehose available,
however anyone is able to subscribe to any topic services publish to. To
interact with the firehose you need to use the MQTT protocol. The specific
contents of the payload are dictated by the service publishing the
messages. So this section only covers how to subscribe and receive the messages
not how to consume the content received.

Available Clients
-----------------
The MQTT community wiki maintains a page that lists available client bindings
for many languages here: https://github.com/mqtt/mqtt.github.io/wiki/libraries
For python using the `paho-mqtt`_ library is recommended

.. _paho-mqtt: https://pypi.python.org/pypi/paho-mqtt/

CLI Example
-----------
The mosquitto project also provides both a CLI publisher and subscriber client
that can be used to easily subscribe to any topic and receive the messages. On
debian based distributions these are included in the mosquitto-clients package.
For example, to subscribe to every topic on the firehose you would run::

    mosquitto_sub -h firehose.openstack.org --topic '#'

You can adjust the value of the topic parameter to make what you're subscribing
to more specific.

Websocket Example
-----------------
In addition to using the raw MQTT protocol firehose.o.o  provides a websocket
interface on port 80 that MQTT traffic can go through. This is especially useful
for web applications that intend to consume any events from MQTT. To see an
example of this in action you can try: http://mitsuruog.github.io/what-mqtt/
(the source is available here: https://github.com/mitsuruog/what-mqtt) and use
that to subscribe to any topics on firehose.openstack.org.

Another advantage of using websockets over port 80 is that it's much more
firewall friendly, especially in environments that are more locked down. If you
would like to consume events from the firehose and are concerned about a
firewall blocking your access, the websocket interface is a good choice.

You can also use the paho-mqtt python library to subscribe to mqtt over
websockets fairly easily. For example this script will subscribe to all topics
on the firehose and print it to STDOUT

.. code-block:: python
   :emphasize-lines: 12,17

    import paho.mqtt.client as mqtt


    def on_connect(client, userdata, flags, rc):
        print("Connected with result code " + str(rc))
            client.subscribe('#')

    def on_message(client, userdata, msg):
        print(msg.topic+" "+str(msg.payload))

    # Create a websockets client
    client = mqtt.Client(transport="websockets")
    client.on_connect = on_connect
    client.on_message = on_message

    # Connect to the firehose
    client.connect('firehose.openstack.org', port=80)
    # Listen forever
    client.loop_forever()

IMAP and MX
-----------

We're using Cyrus as an IMAP server in order to consume launchpad bug
events via email. The configuration of the admin password account and
creation of the lpmqtt user for Cyrus were completed using the
following::

    $ sudo saslpasswd2 cyrus
    $ cyradm --user=cyrus --server=localhost
    Password:
    localhost> create user.lpmqtt

An MX record has also been set up to point to the firehose server.
