Configure users on a server

Configure users on a server.  Users are given sudo access

**Role Variables**

.. zuul:rolevar:: all_users
   :default: {}

   Dictionary of all users.  Each user needs a ``uid``, ``gid`` and ``key``

.. zuul:rolevar:: base_users
   :default: []

   Users to install on all hosts

.. zuul:rolevar:: extra_users
   :default: []

   Extra users to install on a specific host or group

.. zuul:rolevar:: disabled_users
   :default: []

   Users who should be removed from all hosts

