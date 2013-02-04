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
  $git_url = '',
  $httproot = '',
  $serveradmin = '',
) {
  include apache

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
    owner  => 'reviewday',
    group  => 'reviewday',
    mode   => '0644',
  }

  file { "/var/lib/${name}/.ssh/config":
    ensure   => present,
    content  => template('ssh_config.erb'),
    owner    => reviewday,
    group    => reviewday,
    mode     => '0644',
  }

  cron { "update ${name} reviewday":
    command => "cd /var/lib/${name}/reviewday && PYTHONPATH=\$PWD python bin/reviewday -o /${httproot}",
    minute  => '*/15',
    user    => 'reviewday',
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
