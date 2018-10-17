Install and configure Ansible on a host via pip with support for enabling the
ARA callback plugin.

** Role Variables **

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
