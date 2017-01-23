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
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
  $sysadmins = [],
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
  $wheel_keytab = undef,
) {

  if( $wheel_keytab ) {
    file { "/etc/wheel.keytab":
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0400',
      content => $wheel_keytab,
    }
  }

  class { 'openstack_project::slave':
    sysadmins           => $sysadmins,
    ssh_key             => $jenkins_ssh_public_key,
    jenkins_gitfullname => $jenkins_gitfullname,
    jenkins_gitemail    => $jenkins_gitemail,
    project_config_repo => $project_config_repo,
    afs                 => true,
    thin                => true,
  }

  # Create a working directory for the wheel slave, and give it to jenkins to
  # work with
  file { "/opt/wheel":
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0750',
  }

  # below follows a rough list of things required to build binary
  # wheels.

  case $::osfamily {
    'Debian': {
      ensure_packages(['build-essential',
                       'python-all-dev', 'python3-all-dev',
                       'libxml2-dev', 'libxslt-dev',
                       'libffi-dev', 'libreadline-dev',
                       'libssl-dev', 'libyaml-dev', 'zlib1g-dev',
                       'libldap2-dev', 'libmysqlclient-dev',
                       'libpq-dev', 'libsasl2-dev',
                       'libsqlite3-dev', 'libvirt-dev', 'libzmq-dev',
                       'pkg-config', 'swig', 'uuid-dev'])
      }
     'Redhat': {
       ensure_packages(['gcc', 'gcc-c++', 'make',
                        'python-devel', 'python34-devel',
                        'libxml2-devel', 'libxslt-devel',
                        'libffi-devel', 'readline-devel',
                        'openssl-devel', 'libyaml-devel', 'zlib-devel',
                        'openldap-devel', 'mariadb-devel',
                        'postgresql-devel', 'cyrus-sasl-devel',
                        'sqlite-devel', 'libvirt-devel', 'zeromq-devel',
                        'pkgconfig', 'swig', 'uuid-devel'])
    }
    default: {
      err "${::osfamily} not supported yet"
    }
  }

  # This mostly mirrors setting up bindep in /usr/bindep-env just as
  # project-config:nodepool/elements/cache-bindep/ element does for
  # regular nodes.  This way we can use the regular jenkins macros
  # which expect bindep to be there.
  #
  # NOTE that installing pacakges on long-lived slaves like this is
  # particular to this wheel-build job and likely should not be
  # replicated.

  vcsrepo { '/opt/bindep':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/bindep.git',
  }

  python::virtualenv { '/usr/bindep-env':
    ensure       => present,
    owner        => 'root',
    group        => 'root',
    timeout      => 0,
  }

  exec { 'bindep-env-update':
    command     => '/usr/bindep-env/bin/pip --log /usr/bindep-env/pip.log install /opt/bindep',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/bindep'],
    require     => Python::Virtualenv['/usr/bindep-env'],
  }

}
