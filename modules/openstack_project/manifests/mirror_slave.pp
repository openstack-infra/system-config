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
# Install a python mirror building slave.

class openstack_project::mirror_slave (
  $jenkins_ssh_private_key,
) {

  include openstack_project::slave
  include jeepyb

  file { '/home/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/home/jenkins/.ssh'],
    content => $jenkins_ssh_private_key,
  }

  file { '/home/jenkins/pypimirror':
    ensure  => directory,
    mode    => '0755',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/home/jenkins/pypimirror/etc':
    ensure  => directory,
    mode    => '0755',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/home/jenkins/pypimirror'],
  }

  file { '/home/jenkins/pypimirror/cache':
    ensure  => directory,
    mode    => '0755',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/home/jenkins/pypimirror'],
  }

  file { '/home/jenkins/pypimirror/mirror':
    ensure  => directory,
    mode    => '0755',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/home/jenkins/pypimirror'],
  }

  file { '/home/jenkins/pypimirror/etc/pypi-mirror.yaml':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/jenkins-pypi-mirror.yaml',
    require => File['/home/jenkins/pypimirror/etc'],
  }

}
