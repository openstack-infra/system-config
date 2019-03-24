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
# == Class: openstack_project::git_backend
class openstack_project::git_backend (
  $vhost_name = $::fqdn,
  $git_gerrit_ssh_key = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $git_zuul_ci_org_ssl_cert_file_contents = '',
  $git_zuul_ci_org_ssl_key_file_contents = '',
  $git_zuul_ci_org_ssl_chain_file_contents = '',
  $git_airshipit_org_ssl_cert_file_contents = '',
  $git_airshipit_org_ssl_key_file_contents = '',
  $git_airshipit_org_ssl_chain_file_contents = '',
  $git_starlingx_io_ssl_cert_file_contents = '',
  $git_starlingx_io_ssl_key_file_contents = '',
  $git_starlingx_io_ssl_chain_file_contents = '',
  $behind_proxy = false,
  $project_config_repo = '',
  $selinux_mode = 'enforcing',
) {

  package { 'lsof':
    ensure => present,
  }

  class { 'project_config':
    url  => $project_config_repo,
  }

  include jeepyb
  include pip

  if ($::osfamily == 'RedHat') {
    class { 'selinux':
      mode => $selinux_mode
    }
  }

  class { '::cgit':
    vhost_name              => $vhost_name,
    ssl_cert_file           => "/etc/pki/tls/certs/${vhost_name}.pem",
    ssl_key_file            => "/etc/pki/tls/private/${vhost_name}.key",
    ssl_chain_file          => '/etc/pki/tls/certs/intermediate.pem',
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    behind_proxy            => $behind_proxy,
    cgitrc_settings         => {
        'clone-prefix'   => 'https://git.openstack.org https://git.openstack.org',
        'commit-filter'  => '/usr/local/bin/commit-filter.sh',
        'css'            => '/static/openstack.css',
        'favicon'        => '/static/favicon.ico',
        'logo'           => '/static/openstack.svg',
        'root-title'     => 'OpenStack git repository browser',
        'max-repo-count' => 2500,
        'robots'         => 'index',
    },
    manage_cgitrc           => true,
    selinux_mode            => $selinux_mode
  }

  ::cgit::site { 'git.zuul-ci.org':
    cgit_vhost_name         => 'git.zuul-ci.org',
    ssl_cert_file           => "/etc/pki/tls/certs/git.zuul-ci.org.pem",
    ssl_key_file            => "/etc/pki/tls/private/git.zuul-ci.org.key",
    ssl_chain_file          => '/etc/pki/tls/certs/git.zuul-ci.org.intermediate.pem',
    ssl_cert_file_contents  => $git_zuul_ci_org_ssl_cert_file_contents,
    ssl_key_file_contents   => $git_zuul_ci_org_ssl_key_file_contents,
    ssl_chain_file_contents => $git_zuul_ci_org_ssl_chain_file_contents,
    behind_proxy            => $behind_proxy,
    cgitrc_settings         => {
        'clone-prefix'   => 'https://git.zuul-ci.org',
        'commit-filter'  => '/usr/local/bin/commit-filter.sh',
        'css'            => '/cgit-data/cgit.css',
        'favicon'        => '/cgit-data/favicon.ico',
        'logo'           => '/cgit-data/cgit.png',
        'root-title'     => 'Zuul git repository browser',
        'max-repo-count' => 2500,
        'robots'         => 'index',
        'include'        => '/etc/cgitrepos_git.zuul-ci.org',
    },
    manage_cgitrc           => true,
    cgitrc_path             => '/etc/cgitrc_git.zuul-ci.org',
    local_git_dir           => '/var/lib/git-alias/git.zuul-ci.org',
    cgitdir                 => '/var/www/cgit_git.zuul-ci.org',
    staticfiles             => '/var/www/cgit_git.zuul-ci.org/static',
    selinux_mode            => $selinux_mode
  }

  ::cgit::site { 'git.airshipit.org':
    cgit_vhost_name         => 'git.airshipit.org',
    ssl_cert_file           => "/etc/pki/tls/certs/git.airshipit.org.pem",
    ssl_key_file            => "/etc/pki/tls/private/git.airshipit.org.key",
    ssl_chain_file          => '/etc/pki/tls/certs/git.airshipit.org.intermediate.pem',
    ssl_cert_file_contents  => $git_airshipit_org_ssl_cert_file_contents,
    ssl_key_file_contents   => $git_airshipit_org_ssl_key_file_contents,
    ssl_chain_file_contents => $git_airshipit_org_ssl_chain_file_contents,
    behind_proxy            => $behind_proxy,
    cgitrc_settings         => {
        'clone-prefix'   => 'https://git.airshipit.org',
        'commit-filter'  => '/usr/local/bin/commit-filter.sh',
        'css'            => '/cgit-data/cgit.css',
        'favicon'        => '/cgit-data/favicon.ico',
        'logo'           => '/cgit-data/cgit.png',
        'root-title'     => 'Airship git repository browser',
        'max-repo-count' => 2500,
        'robots'         => 'index',
        'include'        => '/etc/cgitrepos_git.airshipit.org',
    },
    manage_cgitrc           => true,
    cgitrc_path             => '/etc/cgitrc_git.airshipit.org',
    local_git_dir           => '/var/lib/git-alias/git.airshipit.org',
    cgitdir                 => '/var/www/cgit_git.airshipit.org',
    staticfiles             => '/var/www/cgit_git.airshipit.org/static',
    selinux_mode            => $selinux_mode
  }

  ::cgit::site { 'git.starlingx.io':
    cgit_vhost_name         => 'git.starlingx.io',
    ssl_cert_file           => "/etc/pki/tls/certs/git.starlingx.io.pem",
    ssl_key_file            => "/etc/pki/tls/private/git.starlingx.io.key",
    ssl_chain_file          => '/etc/pki/tls/certs/git.starlingx.io.intermediate.pem',
    ssl_cert_file_contents  => $git_starlingx_io_ssl_cert_file_contents,
    ssl_key_file_contents   => $git_starlingx_io_ssl_key_file_contents,
    ssl_chain_file_contents => $git_starlingx_io_ssl_chain_file_contents,
    behind_proxy            => $behind_proxy,
    cgitrc_settings         => {
        'clone-prefix'   => 'https://git.starlingx.io',
        'commit-filter'  => '/usr/local/bin/commit-filter.sh',
        'css'            => '/cgit-data/cgit.css',
        'favicon'        => '/cgit-data/favicon.ico',
        'logo'           => '/cgit-data/cgit.png',
        'root-title'     => 'StarlingX git repository browser',
        'max-repo-count' => 2500,
        'robots'         => 'index',
        'include'        => '/etc/cgitrepos_git.starlingx.io',
    },
    manage_cgitrc           => true,
    cgitrc_path             => '/etc/cgitrc_git.starlingx.io',
    local_git_dir           => '/var/lib/git-alias/git.starlingx.io',
    cgitdir                 => '/var/www/cgit_git.starlingx.io',
    staticfiles             => '/var/www/cgit_git.starlingx.io/static',
    selinux_mode            => $selinux_mode
  }

  # We don't actually use these variables in this manifest, but jeepyb
  # requires them to exist.
  $local_git_dir = '/var/lib/git'
  $ssh_project_key = ''

  file { '/home/cgit/.ssh/':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0700',
    require => User['cgit'],
  }

  ssh_authorized_key { 'gerrit-replication-2014-04-25':
    ensure  => present,
    user    => 'cgit',
    type    => 'ssh-rsa',
    key     => $git_gerrit_ssh_key,
    require => File['/home/cgit/.ssh/']
  }
  ssh_authorized_key { '/home/cgit/.ssh/authorized_keys':
    ensure  => absent,
    user    => 'cgit',
  }

  file { '/home/cgit/projects.yaml':
    ensure  => present,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0444',
    source  => $::project_config::jeepyb_project_file,
    require => $::project_config::config_dir,
    replace => true,
  }

  exec { 'create_cgitrepos':
    command     => 'create-cgitrepos',
    path        => '/bin:/usr/bin:/usr/local/bin',
    environment => [
      'SCRATCH_SUBPATH=zuul',
      'SCRATCH_OWNER=zuul',
      'SCRATCH_GROUP=zuul',
    ],
    require     => [
      File['/home/cgit/projects.yaml'],
      User['zuul'],
      Class['jeepyb'],
    ],
    subscribe   => File['/home/cgit/projects.yaml'],
    refreshonly => true,
  }

  cron { 'mirror_repack':
    ensure      => absent,
    user        => 'cgit',
  }

  cron { 'mirror_gitgc':
    user        => 'cgit',
    hour        => '4',
    minute      => '7',
    command     => 'find /var/lib/git/ -not -path /var/lib/git/zuul -type d -name "*.git" -print -exec git --git-dir="{}" gc \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => User['cgit'],
  }

  file { '/var/www/cgit/static/openstack.svg':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack.svg',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/favicon.ico':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/status/favicon.ico',
    require => File['/var/www/cgit/static'],
  }

  file { '/var/www/cgit/static/openstack.css':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/git/openstack.css',
    require => File['/var/www/cgit/static'],
  }

  file { '/usr/local/bin/commit-filter.sh':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/git/commit-filter.sh',
  }

  user { 'zuul':
    ensure     => present,
    home       => '/home/zuul',
    shell      => '/bin/bash',
    gid        => 'zuul',
    managehome => true,
    require    => Group['zuul'],
  }

  group { 'zuul':
    ensure => present,
  }

  file {'/home/zuul':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0755',
    require => User['zuul'],
  }

  file { '/var/lib/git/zuul':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0755',
    require => [
      User['zuul'],
      File['/var/lib/git'],
    ]
  }

  file { '/home/zuul/.ssh':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0700',
    require => User['zuul'],
  }

  file { '/home/zuul/.ssh/authorized_keys':
    ensure => absent,
  }

  cron { 'mirror_gitgc_zuul':
    user        => 'zuul',
    weekday     => '0',
    hour        => '4',
    minute      => '7',
    command     => 'find /var/lib/git/zuul -type d -name "*.git" -print -exec git --git-dir="{}" git gc \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => User['zuul'],
  }

}
