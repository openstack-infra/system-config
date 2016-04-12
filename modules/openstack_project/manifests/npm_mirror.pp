# == Class: openstack_project::npm_mirror
#
class openstack_project::npm_mirror (
  $uri_rewrite,
  $data_directory,
) {

  file { $data_directory:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
  }

  class { '::nodejs':
    repo_url_suffix => 'node_4.x',
  }

  group { 'mirror-npm':
    ensure => present,
  }

  user { 'mirror-npm':
    ensure     => present,
    managehome => true,
    groups     => ['mirror-npm', 'mirror-admin'],
    require    => Group['mirror-npm'],
  }

  file { '/etc/npm.keytab':
    owner   => 'mirror-npm',
    group   => 'mirror-npm',
    mode    => '0400',
    content => $npm_keytab,
    require => User['mirror-npm'],
  }

  file { '/usr/local/bin/npm-mirror-update':
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    content  => template('openstack_project/npm-mirror-update.sh'),
  }

  cron { 'npm-mirror-update':
    user        => 'mirror-npm',
    minute      => '*/5',
    command     => 'flock -n /var/run/npm-mirror-update/mirror.lock npm-mirror-update >>/var/log/npm-mirror-update/mirror.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
      File['/usr/local/bin/npm-mirror-update'],
      File['/etc/afsadmin.keytab'],
      File['/etc/npm.keytab'],
      Class['openstack_project::npm_mirror'],
    ]
    require => User['mirror-npm'],
  }

  # See: https://github.com/davglass/registry-static/pull/45
  package { 'patch-package-json':
    ensure   => '0.0.4',
    provider => 'npm',
    require  => Class['nodejs'],
  }

  package { 'follow-registry':
    ensure   => '2.0.0',
    provider => 'npm',
    require  => [
      Class['nodejs'],
    ]
  }

  # The registry mirroring script.
  package { 'registry-static':
    ensure   => '2.2.0',
    provider => 'npm',
    require  => [
      Class['nodejs'],
      Package['follow-registry'],
      Package['patch-package-json'],
    ]
  }

  # The afs-blob-store file structure rewriter.
  package { 'afs-blob-store':
    ensure   => '1.0.1',
    provider => 'npm',
    require  => [
      Class['nodejs'],
    ]
  }
}
