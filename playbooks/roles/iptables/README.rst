Install and configure iptables

**Role Variables**

.. zuul:rolevar:: iptables_allowed_hosts
   :default: []

   A list of dictionaries, each item in the list is a rule to add for
   a host/port combination.  The format of the dictionary is:

   .. zuul:rolevar:: hostname

      The hostname to allow.  It will automatically be resolved, and
      all IP addresses will be added to the firewall.

   .. zuul:rolevar:: protocol

      One of "tcp" or "udp".

   .. zuul:rolevar:: port

      The port number.

.. zuul:rolevar:: iptables_public_tcp_ports
   :default: []

   A list of public TCP ports to open.

.. zuul:rolevar:: iptables_public_udp_ports
   :default: []

   A list of public UDP ports to open.

.. zuul:rolevar:: iptables_rules_v4
   :default: []

   A list of iptables v4 rules.  Each item is a string containing the
   iptables command line options for the rule.

.. zuul:rolevar:: iptables_rules_v6
   :default: []

   A list of iptables v6 rules.  Each item is a string containing the
   iptables command line options for the rule.
