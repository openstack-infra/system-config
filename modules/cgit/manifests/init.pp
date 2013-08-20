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
# Class: cgit
#
class cgit(
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $cgitdir = '/var/www/cgit',
  $daemon_port = '29418',
  $staticfiles = '/var/www/cgit/static',
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $balance_git = false,
  $proxy_git_daemon = false,
  $balancer_member_names = [],
  $balancer_member_ips = []
) {

  include apache

  package { [
      'cgit',
      'git-daemon',
    ]:
    ensure => present,
  }

  user { 'cgit':
    ensure     => present,
    home       => '/home/cgit',
    shell      => '/bin/bash',
    gid        => 'cgit',
    managehome => true,
    require    => Group['cgit'],
  }

  group { 'cgit':
    ensure => present,
  }

  file {'/home/cgit':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0755',
    require => User['cgit'],
  }

  file { '/var/lib/git':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0644',
    require => User['cgit'],
  }

  exec { 'restorecon -R -v /var/lib/git':
    path        => '/sbin',
    require     => File['/var/lib/git'],
    subscribe   => File['/var/lib/git'],
    refreshonly => true,
  }

  selboolean { 'httpd_enable_cgi':
    persistent => true,
    value      => on
  }

  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'cgit/git.vhost.erb',
    ssl      => true,
    require  => [ File[$staticfiles], Package['cgit'] ],
  }

  file { '/etc/httpd/conf.d/ssl.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/cgit/ssl.conf',
    require => Package['mod_ssl'],
  }

  file { $cgitdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { $staticfiles:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$cgitdir],
  }

  file { '/etc/xinetd.d/git':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/cgit/git.xinetd',
  }

  service { 'xinetd':
    ensure    => stopped,
    subscribe => File['/etc/xinetd.d/git'],
  }

  file { '/etc/init.d/git-daemon':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/cgit/git-daemon.init',
  }

  service { 'git-daemon':
    ensure    => running,
    subscribe => File['/etc/init.d/git-daemon'],
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $balance_git == true {
    include haproxy
    haproxy::listen { 'balance_git_http':
      ipaddress        => $::ipaddress,
      ports            => ['80'],
      mode             => 'tcp',
      collect_exported => false,
      options          => {
        'redirect' => "location https://${vhost_name}",
        'option'  => [
          'tcplog',
        ],
      },
    }
    haproxy::listen { 'balance_git_https':
      ipaddress        => $::ipaddress,
      ports            => ['443'],
      mode             => 'tcp',
      collect_exported => false,
      options          => {
        'option'  => [
          'tcplog',
        ],
      },
    }
    # Warning: git daemon is composed of layers like ogers and onions.
    haproxy::listen { 'balance_git_daemon':
      ipaddress        => $::ipaddress,
      ports            => ['9418'],
      mode             => 'tcp',
      collect_exported => false,
      options          => {
        'option'  => [
          'tcplog',
        ],
      },
    }
    # TODO pass in ipaddresses and server names to balance across.
    haproxy::balancermember { 'balance_git_https_member':
      listening_service => 'balance_git_https',
      server_names      => $balancer_member_names,
      ipaddresses       => $balancer_memeber_names,
      ports             => '4443',
    }
    haproxy::balancermember { 'balance_git_daemon_member':
      listening_service => 'balance_git_daemon',
      server_names      => $balancer_member_names,
      ipaddresses       => $balancer_memeber_names,
      ports             => '19418',
    }
  }
  if $proxy_git_daemon == true {
    include haproxy
    haproxy::listen { 'gitdaemon':
      ipaddress        => $::ipaddress,
      ports            => '19418',
      mode             => 'tcp',
      collect_exported => false,
      options          => {
        'maxconn' => '32',
        'backlog' => '512',
        'option'  => [
          'tcplog',
        ],
      },
    }
    haproxy::balancermember { 'proxy_git_daemon_member':
      listening_service => 'gitdaemon',
      server_names      => $::hostname,
      ipaddresses       => '127.0.0.1',
      ports             => '29418',
    }
  }
}
