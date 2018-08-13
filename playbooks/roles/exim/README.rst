Installs and configures the exim mail server

**Role Variables**

.. zuul:rolevar:: exim_aliases
   :default: {}

   A dictionary with keys being the email alias and the value being the
   address or comma separated list of addresses.

.. zuul:rolevar:: exim_routers
   :default: []

   A list of additional exim routers to define.

.. zuul:rolevar:: exim_transports
   :default: []

   A list of additional exim transports to define.

.. zuul:rolevar:: exim_local_domains
   :default: "@"

   Colon separated list of local domains.

.. zuul:rolevar:: exim_queue_interval
   :default: 30m

   How often should we run the queue.

.. zuul:rolevar:: exim_queue_run_max
   :default: 5

   Number of simultaneous queue runners.

.. zuul:rolevar:: exim_smtp_accept_max
   :default: null

   The maximum number of simultaneous incoming SMTP calls that Exim will
   accept. If the value is set to zero, no limit is applied. However, it
   is required to be non-zero if
   :zuul:rolevar:`exim_smtp_accept_max_per_host` is set.

.. zuul:rolevar:: exim_smtp_accept_max_per_host
   :default: null

   Restrict the number of simultaneous IP connections from a single host
   (strictly, from a single IP address) to the Exim daemon. The option is
   expanded, to enable different limits to be applied to different hosts
   by reference to ``$sender_host_address``. Once the limit is reached,
   additional connection attempts from the same host are rejected with error
   code 421. The option’s default value imposes no limit. If this option is
   set greater than zero, it is required that
   :zuul:rolevar:`exim_smtp_accept_max` be non-zero.
