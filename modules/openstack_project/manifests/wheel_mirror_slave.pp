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
  $pypi_mirror_dfw_host_key,
  $pypi_mirror_gra1_host_key,
  $pypi_mirror_iad_host_key,
  $pypi_mirror_ord_host_key,
  $pypi_mirror_hp1_host_key,
  $pypi_mirror_nyj_host_key,
  $pypi_mirror_openstack_host_key,
  $pypi_mirror_regionone_host_key,
  $wheel_mirror_ssh_public_key,
  $wheel_mirror_ssh_private_key,
  $sysadmins = [],
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
) {
  class { 'openstack_project::slave':
    sysadmins           => $sysadmins,
    ssh_key             => $jenkins_ssh_public_key,
    jenkins_gitfullname => $jenkins_gitfullname,
    jenkins_gitemail    => $jenkins_gitemail,
    project_config_repo => $project_config_repo,
  }

  file { '/home/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/home/jenkins/.ssh'],
    content => $wheel_mirror_ssh_private_key,
  }

  file { '/home/jenkins/.ssh/id_rsa.pub':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['/home/jenkins/.ssh'],
    content => $wheel_mirror_ssh_public_key,
  }

  file { '/home/jenkins/.ssh/known_hosts':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('openstack_project/wheel_mirror/known_hosts.erb')
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
                        'libxml2-devel', 'libxslt-devel',
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
