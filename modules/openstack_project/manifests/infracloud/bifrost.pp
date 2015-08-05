# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
class openstack_project::infracloud::bifrost (
  $ironic_db_password,
  $mysql_password,
  $region,
  $ipmi_passwords,
) {

  include ::ansible

  class { '::mysql::server':
    root_password => $mysql_password,
  }

  vcsrepo { '/opt/stack/bifrost':
    ensure   => 'latest',
    provider => 'git',
    revision => 'master',
    source   => 'https://git.openstack.org/openstack/bifrost',
  }

  file { '/etc/bifrost':
    ensure => directory,
  }

  file { '/etc/bifrost/bifrost_global_vars':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/bifrost/bifrost_global_vars',
    require => File['/etc/bifrost'],
  }

  file { '/opt/stack/baremetal.json':
    ensure  => file,
    content => template("openstack_project/bifrost/inventory.${region}.json.erb"),
    require => Vcsrepo['/opt/stack/bifrost'],
  }

  package { 'uuid-runtime':
    ensure => installed
  }

  exec { 'install bifrost dependencies':
    command => "pip install -U -r /opt/stack/bifrost/requirements.txt",
    path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin",
    require => Vcsrepo['/opt/stack/bifrost'],
  }

  exec { 'install bifrost':
    environment => ["BIFROST_INVENTORY_SOURCE=/opt/stack/baremetal.json", "HOME=/root"],
    command => "ansible-playbook -e @/etc/bifrost/bifrost_global_vars -vvvv -i /opt/stack/bifrost/playbooks/inventory/bifrost_inventory.py /opt/stack/bifrost/playbooks/install.yaml && touch /var/run/bifrost_install_succeeded",
    path => "/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin",
    require => [ Exec['install bifrost dependencies'], File['/etc/bifrost/bifrost_global_vars'], Vcsrepo['/opt/stack/bifrost'], Package['uuid-runtime'] ],
    creates => "/var/run/bifrost_install_succeeded"
  }
}
