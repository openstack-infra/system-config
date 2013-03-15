# Copyright 2013  OpenStack Foundation
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
# Install a host that manages the devstack node pool.

class openstack_project::devstack_launch_slave (
  $jenkins_api_user,
  $jenkins_api_key
) {

  class { 'openstack_project::slave':
    bare => true,
  }

  package { [ 'python-novaclient',
              'python-jenkins',
              'rackspace-auth-openstack',
              'statsd',
              'paramiko']:
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }

  package { [ 'python-sqlalchemy',
              'sqlite3']:
    ensure   => present,
  }

  file { '/home/jenkins/devstack-gate-secure.conf':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/devstack-gate-secure.conf.erb'),
    require => File['/home/jenkins'],
  }
}
