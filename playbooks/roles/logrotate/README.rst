Add log rotation file

.. note:: This role does not manage the ``logrotate`` package or
          configuration directory, and it is assumed to be installed
          and available.

This role installs a log rotation file in ``/etc/logrotate.d/`` for a
given file.

For information on the directives see ``logrotate.conf(5)``.  This is
not an exhaustive list of directives (contributions are welcome).

** Role Variables **

.. zuul:rolevar:: logrotate_file_name

   The log file on disk to rotate

.. zuul:rolevar:: logrotate_config_file_name
   :default: Unique name based on :zuul:rolevar::`logrotate.logrotate_file_name`

   The name of the configuration file in ``/etc/logrotate.d``

.. zuul:rolevar:: logrotate_compress
   :default: yes

.. zuul:rolevar:: logrotate_copytruncate
   :default: yes

.. zuul:rolevar:: logrotate_delaycompress
   :default: yes

.. zuul:rolevar:: logrotate_missingok
   :default: yes

.. zuul:rolevar:: logrotate_rotate
   :default: 7

.. zuul:rolevar:: logrotate_daily
   :default: yes

.. zuul:rolevar:: logrotate_notifempty
   :default: yes
