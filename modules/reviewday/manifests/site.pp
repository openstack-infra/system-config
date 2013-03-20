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
# == Define: reviewday
#
define reviewday::site(
  $reviewday_user = '',
  $reviewday_group = '',
  $gerrit_url = '',
  $gerrit_port = '',
  $gerrit_user = '',
  $reviewday_rsa_key_contents = '',
  $reviewday_rsa_pubkey_contents = '',
  $reviewday_gerrit_ssh_key = '',
  $git_url = '',
  $httproot = '',
  $serveradmin = ''
) {

  group { $reviewday_group:
    ensure => present,
  }

  user { $reviewday_user:
    ensure     => present,
    home       => "/var/lib/${name}",
    shell      => '/bin/bash',
    gid        => $reviewday_group,
    managehome => true,
    require    => Group[$reviewday_group],
  }

  file { "/var/lib/${name}/.ssh/":
    ensure  => directory,
    owner   => $reviewday_user,
    group   => $reviewday_group,
    mode    => '0700',
    require => User[$reviewday_user],
  }

  if $reviewday_rsa_key_contents != '' {
    file { "/var/lib/${name}/.ssh/id_rsa":
      owner   => $reviewday_user,
      group   => $reviewday_group,
      mode    => '0600',
      content => $reviewday_rsa_key_contents,
      replace => true,
      require => File["/var/lib/${name}/.ssh/"]
    }
  }

  if $reviewday_rsa_pubkey_contents != '' {
    file { "/var/lib/${name}/.ssh/id_rsa.pub":
      owner   => $reviewday_user,
      group   => $reviewday_group,
      mode    => '0600',
      content => $reviewday_rsa_pubkey_contents,
      replace => true,
      require => File["/var/lib/${name}/.ssh/"]
    }
  }

  if $reviewday_gerrit_ssh_key != '' {
    file { "/var/lib/${name}/.ssh/known_hosts":
      owner   => $reviewday_user,
      group   => $reviewday_group,
      mode    => '0600',
      content => $reviewday_gerrit_ssh_key,
      replace => true,
      require => File["/var/lib/${name}/.ssh/"]
    }
  }

  vcsrepo { "/var/lib/${name}/reviewday":
    ensure   => present,
    provider => git,
    source   => $git_url,
  }

  apache::vhost { $name:
    docroot  => $httproot,
    port     => 80,
    priority => '50',
    require  => File[$httproot],
    template => 'reviewday.vhost.erb',
  }

  file { $httproot:
    ensure => directory,
    owner  => $reviewday_user,
    group  => $reviewday_group,
    mode   => '0644',
  }

  file { "/var/lib/${name}/.ssh/config":
    ensure   => present,
    content  => template('ssh_config.erb'),
    owner    => $reviewday_user,
    group    => $reviewday_group,
    mode     => '0644',
  }

  cron { "update ${name} reviewday":
    command => "cd /var/lib/${name}/reviewday && PYTHONPATH=\$PWD python bin/reviewday -o /${httproot}",
    minute  => '*/15',
    user    => $reviewday_user,
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
