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
# Class to configure cgit on a CentOS node.
#
# == Class: openstack_project::git
class openstack_project::git (
  $sysadmins = [],
  $git_gerrit_ssh_key = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 9418],
    sysadmins                 => $sysadmins,
  }

  include jeepyb
  include pip

  class { '::cgit':
    ssl_cert_file           => '/etc/pki/tls/certs/git.openstack.org.pem',
    ssl_key_file            => '/etc/pki/tls/private/git.openstack.org.key',
    ssl_chain_file          => '/etc/pki/tls/certs/intermediate.pem',
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
  }

  # We don't actually use these, but jeepyb requires them.
  $local_git_dir = '/var/lib/git'
  $ssh_project_key = ''

  file { '/etc/cgitrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/git/cgitrc'
  }

  file { '/home/cgit/.ssh/':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0700',
    require => User['cgit'],
  }

  file { '/home/cgit/.ssh/authorized_keys':
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0600',
    content => $git_gerrit_ssh_key,
    replace => true,
    require => File['/home/cgit/.ssh/']
  }

  file { '/home/cgit/projects.yaml':
    ensure  => present,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0444',
    content => template('openstack_project/review.projects.yaml.erb'),
    replace => true,
  }

  exec { 'create_cgitrepos':
    command     => 'create-cgitrepos',
    path        => '/bin:/usr/bin:/usr/local/bin',
    require     => File['/home/cgit/projects.yaml'],
    subscribe   => File['/home/cgit/projects.yaml'],
    refreshonly => true,
  }

  class { 'selinux':
    mode => 'enforcing'
  }

  file { '/var/www/cgit/static/openstack.png':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack.png',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/favicon.ico':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/status/favicon.ico',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/openstack-page-bkg.jpg':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack-page-bkg.jpg',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/openstack.css':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/git/openstack.css',
    require => File['/var/www/cgit/static'],
  }

}
