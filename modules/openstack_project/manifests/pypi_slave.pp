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
# Class to install dependencies for uploading python packages to pypi.
#
class openstack_project::pypi_slave (
  $pypi_password,
  $pypi_username = 'openstackci'
) {
  include openstack_project::slave
  include pip

  package { 'pkginfo':
    ensure   => present,
    provider => 'pip',
    require  => Class['pip'],
  }

  file { '/home/jenkins/.pypicurl':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/pypicurl.erb'),
    require => File['/home/jenkins'],
  }
}
