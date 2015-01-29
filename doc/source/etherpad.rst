:title: Etherpad

.. _etherpad:

Etherpad
########

Etherpad (previously known as "etherpad-lite") is installed on
etherpad.openstack.org to facilitate real-time collaboration on
documents.  It is used extensively during OpenStack Developer
Summits.

At a Glance
===========

:Hosts:
  * http://etherpad.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-etherpad_lite/tree/
  * :file:`modules/openstack_project/manifests/etherpad.pp`
  * :file:`modules/openstack_project/manifests/etherpad_dev.pp`
:Projects:
  * http://etherpad.org/
  * https://github.com/ether/etherpad-lite
:Bugs:
  * https://storyboard.openstack.org/#!/project/748
  * https://github.com/ether/etherpad-lite/issues

Overview
========

Apache is configured as a reverse proxy and there is a MySQL database
backend.

Manual Administrative Tasks
===========================

The following sections describe tasks that individuals with root
access may need to perform on rare occasions.

Deleting a Pad
--------------

On occasion it may be necessary to delete a pad, so as to redact
sensitive or illegal data posted to it (the revision history it keeps
makes this harder than just clearing the current contents through a
browser). This is fairly easily accomplished via the `HTTP API`_, but
you need the key which is saved in a file on the server so it's easiest
if done when SSH'd into it locally::

  wget -qO- 'http://localhost:9001/api/1/deletePad?apikey='$(cat \
  /opt/etherpad-lite/etherpad-lite/APIKEY.txt)'&padID=XXXXXXXXXX'

...where XXXXXXXXXX is the pad's name as it appears at the end of its
URL. If all goes well, you should receive a response like::

  {"code":0,"message":"ok","data":null}

Browse to the original pad's URL and you should now see the fresh
welcome message boilerplate for a new pad. Check the pad's history and
note that it has no authors and no prior revisions.

.. _HTTP API: https://github.com/ether/etherpad-lite/wiki/HTTP-API
