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
# Class to install and configure an instance of the elastic-recheck
# service.
#
class elastic_recheck (
) {

  # For all static page generation scripts we want to run them
  # both on a cron schedule (see elastic_recheck::cron) and on
  # any commit. So we need to define commands in a way that
  # we can trigger an exec here, as well as on cron.
  $recheck_state_dir = '/var/lib/elastic-recheck'
  $graph_cmd = 'elastic-recheck-graph /opt/elastic-recheck/queries -o graph-new.json && mv graph-new.json graph.json'
  $uncat_cmd = 'elastic-recheck-uncategorized -d /opt/elastic-recheck/queries -t /usr/local/share/templates -o uncategorized-new.html && mv uncategorized-new.html uncategorized.html'

  group { 'recheck':
    ensure => 'present',
  }

  user { 'recheck':
    ensure  => present,
    home    => '/home/recheck',
    shell   => '/bin/bash',
    gid     => 'recheck',
    require => Group['recheck'],
  }

  vcsrepo { '/opt/elastic-recheck':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/elastic-recheck',
  }

  exec { 'run_er_graph':
    command     => "cd ${recheck_state_dir} && er_safe_run.sh ${graph_cmd}",
    path        => '/usr/local/bin:/usr/bin:/bin/',
    user        => 'recheck',
    refreshonly => true,
    require     => File['/usr/local/bin/er_safe_run.sh'],
    subscribe   => Vcsrepo['/opt/elastic-recheck'],
  }

  exec { 'run_er_uncat':
    command     => "cd ${recheck_state_dir} && er_safe_run.sh ${uncat_cmd}",
    path        => '/usr/local/bin:/usr/bin:/bin/',
    user        => 'recheck',
    refreshonly => true,
    require     => File['/usr/local/bin/er_safe_run.sh'],
    subscribe   => Vcsrepo['/opt/elastic-recheck'],
  }

  include pip
  exec { 'install_elastic-recheck' :
    command     => 'pip install /opt/elastic-recheck',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/elastic-recheck'],
    require     => Class['pip'],
  }

  file { '/usr/local/bin/er_safe_run.sh':
    ensure  => present,
    source  => 'puppet:///modules/elastic_recheck/er_safe_run.sh',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { '/var/run/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/var/lib/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/var/log/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/etc/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/etc/elastic-recheck/logging.config':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    source  => 'puppet:///modules/elastic_recheck/logging.config',
    require => File['/etc/elastic-recheck'],
  }

  file { '/etc/elastic-recheck/recheckwatchbot.yaml':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    source  => 'puppet:///modules/elastic_recheck/recheckwatchbot.yaml',
    require => File['/etc/elastic-recheck'],
  }

  file { '/etc/elastic-recheck/queries':
    ensure  => link,
    target  => '/opt/elastic-recheck/queries',
    require => [
      Vcsrepo['/opt/elastic-recheck'],
      File['/etc/elastic-recheck'],
    ],
  }
}
