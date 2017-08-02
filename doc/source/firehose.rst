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
 * **8883** - The default SSL/TLS MQTT port
 * **8080** - Uses websockets for SSL/TLS encrypted MQTT communication

.. note::

 The websockets ports are currently disabled due to `Mosquitto bug #278`_.
 Once this is resolved the websockets ports will be reopened.

.. _Mosquitto bug #278: https://github.com/eclipse/mosquitto/issues/278

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

+----------------+-----------------+---------------------------+
| Service        | Base Topic      | Source of Messages        |
+================+=================+===========================+
| ansible        | ansible         | `ansible_mqtt_plugin`_    |
+----------------+-----------------+---------------------------+
| gerrit         | gerrit          | `germqtt`_                |
+----------------+-----------------+---------------------------+
| launchpad      | launchpad       | `lpmqtt`_                 |
+----------------+-----------------+---------------------------+
| subunit worker | gearman-subunit | `subunit-gearman-worker`_ |
+----------------+-----------------+---------------------------+

.. _germqtt: http://git.openstack.org/cgit/openstack-infra/germqtt/
.. _lpmqtt: http://git.openstack.org/cgit/openstack-infra/lpmqtt/
.. _subunit-gearman-worker: http://git.openstack.org/cgit/openstack-infra/puppet-subunit2sql/tree/files/subunit-gearman-worker.py
.. _ansible_mqtt_plugin: http://git.openstack.org/cgit/openstack-infra/system-config/tree/modules/openstack_project/files/puppetmaster/mqtt.py

For a full schema description see :ref:`firehose_schema`

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

MQTT Protocol Example
---------------------
Interacting with firehose on the unecrpyted MQTT port is normally pretty easy in
most language bindings. Here are some examples that will have the same behavior
as the CLI example above and will subscribe to all topics on the firehose and
print it to STDOUT.


Python
''''''
.. code-block:: python

    import paho.mqtt.client as mqtt


    def on_connect(client, userdata, flags, rc):
        print("Connected with result code " + str(rc))
        client.subscribe('#')

    def on_message(client, userdata, msg):
        print(msg.topic+" "+str(msg.payload))

    # Create a websockets client
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    # Connect to the firehose
    client.connect('firehose.openstack.org')
    # Listen forever
    client.loop_forever()

Haskell
'''''''
This requires the `mqtt-hs`_ library to be installed.

.. _mqtt-hs: https://hackage.haskell.org/package/mqtt-hs

.. code-block:: haskell


  {-# Language DataKinds, OverloadedStrings #-}

  module Subscribe where

  import Control.Concurrent
  import Control.Concurrent.STM
  import Control.Monad (unless, forever)
  import System.Exit (exitFailure)
  import System.IO (hPutStrLn, stderr)

  import qualified Network.MQTT as MQTT

  topic :: MQTT.Topic
  topic = "#"

  handleMsg :: MQTT.Message MQTT.PUBLISH -> IO ()
  handleMsg msg = do
      let t = MQTT.topic $ MQTT.body msg
          p = MQTT.payload $ MQTT.body msg
      print t
      print p

  main :: IO ()
  main = do
    cmds <- MQTT.mkCommands
    pubChan <- newTChanIO
    let conf = (MQTT.defaultConfig cmds pubChan)
                { MQTT.cHost = "firehose.openstack.org" }
    _ <- forkIO $ do
      qosGranted <- MQTT.subscribe conf [(topic, MQTT.Handshake)]
      forever $ atomically (readTChan pubChan) >>= handleMsg
    terminated <- MQTT.run conf
    print terminated

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

Using SSL/TLS
-------------
If you would like to connect to the firehose using ssl to encrypt the events you
recieve from MQTT you just need to connect with ssl enabled via either of the
encypted ports. If you'd like to verify the server ssl certificate when
connecting you'll need to provide a CA bundle to use as most MQTT clients do
not know how to use the system trusted CA bundle like most http clients.

To connect to the firehose and subscribe to all topics you can use the
mosquitto CLI client::

  mosquitto_sub --topic '#' -h firehose.openstack.org --cafile /etc/ca-certificates/extracted/tls-ca-bundle.pem -p 8883

You can use python:

.. code-block:: python
   :emphasize-lines: 15,20

    import paho.mqtt.client as mqtt


    def on_connect(client, userdata, flags, rc):
        print("Connected with result code " + str(rc))
        client.subscribe('#')


    def on_message(client, userdata, msg):
        print(msg.topic+" "+str(msg.payload))


    # Create an SSL encrypted websockets client
    client = mqtt.Client()
    client.tls_set(ca_certs='/etc/ca-certificates/extracted/tls-ca-bundle.pem')
    client.on_connect = on_connect
    client.on_message = on_message

    # Connect to the firehose
    client.connect('firehose.openstack.org', port=8883)
    client.loop_forever()


Or with ruby:

.. code-block:: ruby
   :emphasize-lines: 6,7,8

    require 'rubygems'
    require 'mqtt'

    client = MQTT::Client.new
    client.host = 'firehose.openstack.org'
    client.ssl = true
    client.cert_file = '/etc/ca-certificates/extracted/tls-ca-bundle.pem'
    client.port = 8883
    client.connect()
    client.subscribe('#')

    client.get do |topic,message|
        puts message
        end

Example Use Cases
=================

Event Notifications
-------------------

A common use case for the event bus is to get a notification when an event
occurs. There is an open source tool, `mqttwarn`_ that makes setting this up
off the firehose (or any other mqtt broker) very straightforward.

.. _mqttwarn: https://github.com/jpmens/mqttwarn

You can use mqttwarn to setup custom notifications to a large number of tools
and services. (both local and remote). You can read the full docs on how to
configure and use mqttwarn at https://github.com/jpmens/mqttwarn/wiki and
https://github.com/jpmens/mqttwarn/blob/master/README.md


IMAP and MX
===========

We're using Cyrus as an IMAP server in order to consume launchpad bug
events via email. The configuration of the admin password account and
creation of the lpmqtt user for Cyrus were completed using the
following::

    $ sudo saslpasswd2 cyrus
    $ cyradm --user=cyrus --server=localhost
    Password:
    localhost> create user.lpmqtt

An MX record has also been set up to point to the firehose server.
