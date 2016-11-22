# Release afs volumes
class openstack_project::afsrelease (
) {
  include logrotate

  file { '/usr/local/bin/release-volumes':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openstack_project/openafs/release-volumes.py',
  }

  file { '/var/log/release':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  cron { 'release':
    user        => 'root',
    minute      => '*/5',
    command     => '/usr/local/bin/release-volumes >>/var/log/release/release.log 2>&1',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
       File['/usr/local/bin/release-volumes'],
    ]
  }

  logrotate::file { 'release':
    ensure  => present,
    log     => '/var/log/release/release.log',
    options => ['compress',
      'copytruncate',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Cron['release'],
  }
}
