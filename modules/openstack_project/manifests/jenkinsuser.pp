# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
# == Class: openstack_project::jenkinsuser
#
class openstack_project::jenkinsuser {

  file { '/home/jenkins/.gitconfig':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    source  => 'puppet:///modules/jenkins/gitconfig',
    require => File['/home/jenkins'],
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
    mode    => '0600',
    require => File['/home/jenkins/.gnupg'],
    source  => 'puppet:///modules/jenkins/pubring.gpg',
  }

  file { '/home/jenkins/.m2':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.m2/settings.xml':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => File['/home/jenkins/.m2'],
    source  => 'puppet:///modules/jenkins/settings.xml',
  }

}
