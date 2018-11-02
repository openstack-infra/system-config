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
   :zuul:rolevar:`install-ansible.install_ansible_name`.  Set this to empty (YAML
   ``null``) if specifying versions via
   :zuul:rolevar:`install-ansible.install_ansible_name`
