Configure an authoritative nameserver

This role installs and configures nsd to be an authoritative
nameserver.

**Role Variables**

.. zuul:rolevar:: tsig_key
   :type: dict

   The TSIG key used to authenticate connections between nameservers.

   .. zuul:rolevar:: algorithm

      The algorithm used by the key.

   .. zuul:rolevar:: secret

      The secret portion of the key.

.. zuul:rolevar:: dns_zones
   :type: list

   A list of zones that should be served by named.  Each item in the
   list is a dictionary with the following keys:

   .. zuul:rolevar:: name

      The name of the zone.

   .. zuul:rolevar:: source

      The repo name and path of the directory containing the zone
      file.  For example if a repo was provided to
      :zuul:rolevar:`master-nameserver.dns_repos.name` with the name
      ``example.com``, and within that repo, the ``zone.db`` file was
      located at ``zones/example_com/zone.db``, then the value here
      should be ``example.com/zones/example_com``.

.. zuul:rolevar:: dns_master

   The IP addresses of the master nameserver.
