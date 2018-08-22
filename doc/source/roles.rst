:title: Roles

Ansible Roles
#############

Documentation for roles included in `system-config`

There are two types of roles.  Top-level roles, kept in the ``roles/``
directory, are available to be used as roles in Zuul jobs.  This
places some constraints on the roles, such as not being able to use
plugins.  Add

.. code-block:: yaml

   roles:
     - zuul: openstack-infra/system-config

to your job definition to source these roles.

Roles in ``playbooks/roles`` are designed to be run on the
Infrastructure control-plane (i.e. from ``bridge.openstack.org``).
These roles are not available to be shared with Zuul jobs.

Role documentation
------------------


.. zuul:autoroles::
