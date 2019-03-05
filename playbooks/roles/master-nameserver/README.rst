Configure a hidden master nameserver

This role installs and configures bind9 to be a hidden master
nameserver.

**Role Variables**

.. zuul:rolevar:: tsig_key
   :type: dict

   The TSIG key used to control named.

   .. zuul:rolevar:: algorithm

      The algorithm used by the key.

   .. zuul:rolevar:: secret

      The secret portion of the key.

.. zuul:rolevar:: dnssec_keys
   :type: dict

   This is a dictionary of DNSSEC keys.  Each entry is a dnssec key,
   where the dictionary key is the dnssec key id and the value is the
   a dictionary with the following contents:

   .. zuul:rolevar:: zone

      The name of the zone for this key.

   .. zuul:rolevar:: public

      The public portion of this key.

   .. zuul:rolevar:: private

      The private portion of this key.

.. zuul:rolevar:: dns_repos
   :type: list

   A list of zone file repos to check out on the server.  Each item in
   the list is a dictionary with the following keys:

   .. zuul:rolevar:: name

      The name of the repo.

   .. zuul:rolevar:: url

      The URL of the git repository.

   .. zuul:rolevar:: refspec

      Add an additonial refspec to be fetched

   .. zuul:rolevar:: version

      An additional version passed to git checkout

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

   .. zuul:rolevar:: unmanaged
      :type: bool
      :default: False

      If ``True`` the zone is considered unmanaged.  The ``source``
      file will be put in place if it does not exist, but will
      otherwise be left alone.

.. zuul:rolevar:: dns_notify
   :type: list

   A list of IP addresses of nameservers which named should notify on
   updates.
