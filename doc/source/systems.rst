:title: Major Systems

Major Systems
#############

.. toctree::
   :maxdepth: 2

   cacti
   gerrit
   jenkins
   zuul
   jjb
   logstash
   elastic-recheck
   devstack-gate
   nodepool
   jeepyb
   irc
   etherpad
   paste
   planet
   puppet
   static
   bandersnatch
   lists
   wiki
   git
   openstackid
   storyboard
   kerberos
   afs
   askbot

.. NOTE(dhellmann): These projects were not listed above, or in any
   other toctree, which breaks the build. It's not clear why they were
   left out of the toctree but remained in the source dir. Rather than
   deleting them, I've added them to a hidden toctree to eliminate
   that build error.

.. toctree::
   :hidden:

   activity
   asterisk
