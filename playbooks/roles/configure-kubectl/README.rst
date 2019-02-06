Configure kube config files

Configure kubernetes files needed by kubectl.

**Role Variables**

.. zuul:rolevar:: kube_config_dir
   :default: /root/.kube

.. zuul:rolevar:: kube_config_owner
   :default: root

.. zuul:rolevar:: kube_config_group
   :default: root

.. zuul:rolevar:: kube_config_file
   :default: {{ kube_config_dir }}/config

.. zuul:rolevar:: kube_config_template
