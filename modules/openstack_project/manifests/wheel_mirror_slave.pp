# Copyright 2015  Hewlett-Packard Development Company, L.P.
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
class openstack_project::wheel_mirror_slave (
  $jenkins_ssh_public_key,
) {
  class { 'openstack_project::slave':
    ssh_key => $jenkins_ssh_public_key,
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

  vcsrepo { '/opt/pypi-mirror':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/pypi-mirror',
  }

  exec { 'install_pypi_mirror' :
    command     => 'pip install .',
    cwd         => '/opt/pypi-mirror',
    path        => '/usr/local/bin:/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/pypi-mirror'],
  }

  # below follows a rough list of things required to build binary
  # wheels.

  # TODO: global-requirements keeps other-requirements that can be
  # parsed by bindep.  We should have some sort of bindep provider
  # that can interact with that

  case $::osfamily {
    'Debian': {
      ensure_packages(['build-essential',
                       'python-all-dev', 'python3-all-dev',
                       'libxml2-dev', 'libxslt-dev',
                       'libffi-dev', 'libreadline-dev',
                       'libssl-dev', 'libyaml-dev', 'zlib1g-dev',
                       'libldap2-dev', 'libmysqlclient-dev',
                       'libnspr4-dev', 'libpq-dev', 'libsasl2-dev',
                       'libsqlite3-dev', 'libvirt-dev', 'libzmq-dev',
                       'pkg-config', 'swig', 'uuid-dev'])
      }
     'Redhat': {
       ensure_packages(['gcc', 'gcc-c++', 'make',
                        'python-devel', 'python3-devel',
                        'libxml2-devel', 'libxslt-devel'
                        'libffi-devel', 'readline-devel',
                        'openssl-devel', 'libyaml-devel', 'zlib-devel',
                        'openldap-devel', 'mariadb-devel',
                        'nspr-devel', 'postgresql-devel', 'cyrus-sasl-devel',
                        'sqlite-devel', 'libvirt-devel', 'zeromq-devel',
                        'pkgconfig', 'swig', 'uuid-devel'])
    }
    default: {
      err "${::osfamily} not supported yet"
    }
  }

}
