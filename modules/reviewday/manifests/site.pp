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

  file { '/var/lib/reviewday/.ssh/':
    ensure  => directory,
    owner   => 'reviewday',
    group   => 'reviewday',
    mode    => '0700',
    require => User['reviewday'],
  }

  if $reviewday_rsa_key_contents != '' {
    file { '/var/lib/reviewday/.ssh/id_rsa':
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_rsa_key_contents,
      replace => true,
      require => File['/var/lib/reviewday/.ssh/']
    }
  }

  if $reviewday_rsa_pubkey_contents != '' {
    file { '/var/lib/reviewday/.ssh/id_rsa.pub':
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_rsa_pubkey_contents,
      replace => true,
      require => File['/var/lib/reviewday/.ssh/']
    }
  }

  if $reviewday_gerrit_ssh_key != '' {
    file { '/var/lib/reviewday/.ssh/known_hosts':
      owner   => 'reviewday',
      group   => 'reviewday',
      mode    => '0600',
      content => $reviewday_gerrit_ssh_key,
      replace => true,
      require => File['/var/lib/reviewday/.ssh/']
    }
  }

  vcsrepo { '/var/lib/reviewday/reviewday':
    ensure   => present,
    provider => git,
    source   => $git_url,
  }

  file { $httproot:
    ensure => directory,
    owner  => 'reviewday',
    group  => 'reviewday',
    mode   => '0644',
  }

  file { '/var/lib/reviewday/.ssh/config':
    ensure   => present,
    content  => template('ssh_config.erb'),
    owner    => 'reviewday',
    group    => 'reviewday',
    mode     => '0644',
  }

  cron { 'update reviewday':
    command => "cd /var/lib/reviewday/reviewday && PYTHONPATH=\$PWD python bin/reviewday -o ${httproot}",
    minute  => '*/15',
    user    => 'reviewday',
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
