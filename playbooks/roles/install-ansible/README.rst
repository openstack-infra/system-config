Install and configure Ansible on a host via pip

**Role Variables**

.. zuul:rolevar:: install_ansible_name
   :default: ansible

   The name of the ansible package to install.  To install from
   alternative sources, this can be a URL for a remote package;
   e.g. to install from upstream devel branch
   ``git+https://github.com/ansible/ansible.git@devel``

.. zuul:rolevar:: install_ansible_version
   :default: latest

   The version of the library from
   :zuul:rolevar:`install-ansible.install_ansible_name`.  Set this to
   empty (YAML ``null``) if specifying versions via URL in
   :zuul:rolevar:`install-ansible.install_ansible_name`.  The special
   value "latest" will ensure ``state: latest`` is set for the
   package and thus the latest version is always installed.

.. zuul:rolevar:: install_ansible_openstacksdk_name
   :default: openstacksdk

   The name of the openstacksdk package to install.  To install from
   alternative sources, this can be a URL for a remote package;
   e.g. to install from a gerrit change
   ``git+https://git.openstack.org/openstack/openstacksdk@refs/changes/12/3456/1#egg=openstacksdk``

.. zuul:rolevar:: install_ansible_openstacksdk_version
   :default: latest

   The version of the library from
   :zuul:rolevar:`install-ansible.install_ansible_openstacksdk_name`.  Set
   this to empty (YAML ``null``) if specifying versions via
   :zuul:rolevar:`install-ansible.install_ansible_openstacksdk_name`.  The
   special value "latest" will ensure ``state: latest`` is set for the
   package and thus the latest version is always installed.

.. zuul:rolevar:: install_ansible_ara_enable
   :default: false

   Whether or not to install the ARA Records Ansible callback plugin

.. zuul:rolevar:: install_ansible_ara_name
   :default: ara

   The name of the ARA package to install.  To install from
   alternative sources, this can be a URL for a remote package.

.. zuul:rolevar:: install_ansible_ara_version
   :default: latest

   Version of ARA to install.  Set this to empty (YAML ``null``) if
   specifying versions via URL in
   :zuul:rolevar:`install-ansible.install_ansible_ara_name`.  The
   special value "latest" will ensure ``state: latest`` is set for the
   package and hence the latest version is always installed.

.. zuul:rolevar:: install_ansible_ara_config
   :default: {"database": "sqlite:////var/cache/ansible/ara.sqlite"}

   A dictionary of key-value pairs to be added to the ARA
   configuration file

   *database*: Connection string for the database (ex: mysql+pymysql://ara:password@localhost/ara)

   For a list of available configuration options, see the `ARA documentation`_

.. _ARA documentation: https://ara.readthedocs.io/en/stable/configuration.html
