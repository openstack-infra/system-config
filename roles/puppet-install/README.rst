Install puppet on a host

.. note:: This role uses ``puppetlabs`` versions where available in
          preference to system packages.

This roles installs puppet on a host

**Role Variables**

.. zuul:rolevar:: puppet_install_version
   :default: 3

   The puppet version to install.  Platform support for various
   version varies.

.. zuul:rolevar:: puppet_install_system_config_modules
   :default: yes

   If we should clone and run `install_modules.sh
   <https://git.openstack.org/cgit/openstack-infra/system-config/tree/install_modules.sh>`__
   from OpenStack Infra ``system-config`` repository to populate
   required puppet modules on the host.

