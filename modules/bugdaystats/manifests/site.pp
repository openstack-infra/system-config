# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
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
# == Define: bugdaystats
#
define bugdaystats::site(
  $git_url = '',
  $configfile = '',
  $httproot = '',
  $serveradmin = ''
) {
  file { $configfile:
    mode    => '0444',
    source  => 'puppet:///modules/bugdaystats/config.js',
    require => File['/var/lib/bugdaystats'],
  }

  file { $httproot:
    ensure  => directory,
    owner   => 'bugdaystats',
    group   => 'bugdaystats',
    mode    => '0755',
  }

  vcsrepo { '/var/lib/bugdaystats/bugdaystats':
    ensure   => latest,
    provider => git,
    source   => 'https://git.openstack.org/openstack-infra/bugdaystats',
    revision => 'master',
    require  => File['/var/lib/bugdaystats'],
  }

  file { "${httproot}/js":
    ensure  => link,
    target  => '/var/lib/bugdaystats/bugdaystats/output/js',
    require => Vcsrepo['/var/lib/bugdaystats/bugdaystats'],
  }

  file { '/var/lib/bugdaystats/bugdaystats/config.js':
    ensure  => link,
    target  => $configfile,
    require => Vcsrepo['/var/lib/bugdaystats/bugdaystats'],
  }

  cron { 'update bugdaystats':
    command => "/var/lib/bugdaystats/bugdaystats/bugdaystats.py ${httproot}",
    minute  => '*/30',
    user    => 'bugdaystats',
  }
}
