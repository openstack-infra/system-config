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

.. zuul:rolevar:: ara_install
   :default: false

   Whether or not to install the ARA Records Ansible callback plugin

.. zuul:rolevar:: ara_install_pymysql
   :default: false

   Whether or not to install pymysql (required when using the mysql backend)

.. zuul:rolevar:: ara_version
   :default: "0.16.1"

   Version of ARA to install

.. zuul:rolevar:: ara_config
   :default: {"database": "sqlite:////var/cache/ansible/ara.sqlite"}

   *database*: Connection string for the database (ex: mysql+pymysql://ara:password@localhost/ara)

   For a list of available configuration options, see the `ARA documentation`_

.. _ARA documentation: https://ara.readthedocs.io/en/stable/configuration.html
