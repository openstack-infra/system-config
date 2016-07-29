# Copyright 2016 OpenStack Foundation
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
# Class to install dependencies for uploading releases to pypi, maven and
# similar external repositories
#
class openstack_project::signing_node (
  $jenkins_ssh_public_key,
  $pubring,
  $secring,
  $gitfullname = 'OpenStack Release Bot',
  $gitemail = 'infra-root@openstack.org',
  $gitpgpkey = 'infra-root@openstack.org',
  $gerrituser = 'release',
  $gerritkey = undef,
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
  $packaging_keytab = '',
) {
  class { 'openstack_project::slave':
    thin                => true,
    ssh_key             => $jenkins_ssh_public_key,
    jenkins_gitfullname => $gitfullname,
    jenkins_gitemail    => $gitemail,
    jenkins_gitpgpkey   => $gitpgpkey,
    jenkins_gerrituser  => $gerrituser,
    jenkins_gerritkey   => $gerritkey,
    project_config_repo => $project_config_repo,
    afs                 => true,
  }

  file { '/etc/packaging.keytab':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    content => $packaging_keytab,
  }

  package { 'gnupg':
    ensure => present,
  }

  file { '/home/jenkins/.gnupg':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.gnupg/pubring.gpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    content => $pubring,
    require => File['/home/jenkins/.gnupg'],
  }

  file { '/home/jenkins/.gnupg/secring.gpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    content => $secring,
    require => File['/home/jenkins/.gnupg'],
  }

}
