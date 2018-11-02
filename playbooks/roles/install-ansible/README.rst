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

.. zuul:rolevar:: install_openstacksdk_name
   :default: openstacksdk

   The name of the openstacksdk package to install.  To install from
   alternative sources, this can be a URL for a remote package;
   e.g. to install from a gerrit change
   ``git+https://git.openstack.org/openstack/openstacksdk@refs/changes/12/3456/1#egg=openstacksdk``

.. zuul:rolevar:: install_openstacksdk_version
   :default: latest

   The version of the library from
   :zuul:rolevar:`install-ansible.install_openstacksdk_name`.  Set
   this to empty (YAML ``null``) if specifying versions via
   :zuul:rolevar:`install-ansible.install_openstacksdk_name`.  The
   special value "latest" will ensure ``state: latest`` is set for the
   package and thus the latest version is always installed.
