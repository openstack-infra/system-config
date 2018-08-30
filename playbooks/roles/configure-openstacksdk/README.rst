Configure openstacksdk files

Configure openstacksdk files needed by nodepool and ansible.

**Role Variables**

.. zuul:rolevar:: openstacksdk_config_dir
   :default: /etc/openstack

.. zuul:rolevar:: openstacksdk_config_owner
   :default: root

.. zuul:rolevar:: openstacksdk_config_group
   :default: root

.. zuul:rolevar:: openstacksdk_config_file
   :default: {{ openstacksdk_config_dir }}/clouds.yaml

.. zuul:rolevar:: openstacksdk_config_template
