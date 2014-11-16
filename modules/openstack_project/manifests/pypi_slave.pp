# Copyright 2012  Hewlett-Packard Development Company, L.P.
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
# Class to install dependencies for uploading python packages to pypi and
# maven repositories
#
class openstack_project::pypi_slave (
  $pypi_password,
  $jenkins_ssh_public_key,
  $pypi_username = 'openstackci',
  $jenkinsci_username,
  $jenkinsci_password,
  $mavencentral_username,
  $mavencentral_password,
  $puppet_forge_username,
  $puppet_forge_password,
) {
  class { 'openstack_project::slave':
    ssh_key => $jenkins_ssh_public_key,
  }

  include pip

  package { 'twine':
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }

  package { 'wheel':
    ensure   => latest,
    provider => pip,
    require  => Class['pip'],
  }

  file { '/home/jenkins/.pypirc':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/pypirc.erb'),
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.jenkinsci-curl':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/jenkinsci-curl.erb'),
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.mavencentral-curl':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/mavencentral-curl.erb'),
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.puppetforge.yml':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/puppetforge.yml.erb'),
    require => File['/home/jenkins'],
  }

}
