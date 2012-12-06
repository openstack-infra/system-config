# == Class: graphite
#
class graphite(
  $vhost_name = $::fqdn,
  $graphite_admin_user = '',
  $graphite_admin_email = '',
  $graphite_admin_password = '',
) {
  $packages = [ 'python-django',
                'python-django-tagging',
                'python-cairo',
                'nodejs' ]

  include apache
  include pip

  package { $packages:
    ensure => present,
  }

  vcsrepo { '/opt/graphite-web':
    ensure   => latest,
    provider => git,
    revision => '0.9.x',
    source   => 'https://github.com/graphite-project/graphite-web.git',
  }

  exec { 'install_graphite_web' :
    command     => 'python setup.py install --install-scripts=/usr/local/bin --install-lib=/usr/local/lib/python2.7/dist-packages --install-data=/var/lib/graphite',
    cwd         => '/opt/graphite-web',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/graphite-web'],
    require     => [Exec['install_carbon'],
                    File['/var/lib/graphite/storage']]
  }

  vcsrepo { '/opt/carbon':
    ensure   => latest,
    provider => git,
    revision => '0.9.x',
    source   => 'https://github.com/graphite-project/carbon.git',
  }

  exec { 'install_carbon' :
    command     => 'python setup.py install --install-scripts=/usr/local/bin --install-lib=/usr/local/lib/python2.7/dist-packages --install-data=/var/lib/graphite',
    cwd         => '/opt/carbon',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/carbon'],
    require     => [Exec['install_whisper'],
                    File['/var/lib/graphite/storage']]
  }

  vcsrepo { '/opt/whisper':
    ensure   => latest,
    provider => git,
    revision => '0.9.x',
    source   => 'https://github.com/graphite-project/whisper.git',
  }

  exec { 'install_whisper' :
    command     => 'python setup.py install',
    cwd         => '/opt/whisper',
    path        => '/bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/whisper'],
  }

  user { 'statsd':
    ensure     => present,
    home       => '/home/statsd',
    shell      => '/bin/bash',
    gid        => 'statsd',
    managehome => true,
    require    => Group['statsd'],
  }

  group { 'statsd':
    ensure => present,
  }

  file { '/var/lib/graphite':
    ensure  => directory,
  }

  file { '/var/lib/graphite/storage':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    require => [Package['apache2'],
                File['/var/lib/graphite']]
  }

  file { '/var/log/graphite':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package['apache2'],
  }

  file { '/etc/graphite':
    ensure  => directory,
  }

  exec { 'graphite_sync_db':
    user    => 'www-data',
    command => 'python /usr/local/bin/graphite-init-db.py /etc/graphite/admin.ini',
    cwd     => '/usr/local/lib/python2.7/dist-packages/graphite',
    path    => '/bin:/usr/bin',
    onlyif  => 'test ! -f /var/lib/graphite/graphite.db',
    require => [ Exec['install_graphite_web'],
      File['/var/lib/graphite'],
      Package['apache2'],
      File['/usr/local/lib/python2.7/dist-packages/graphite/local_settings.py'],
      File['/usr/local/bin/graphite-init-db.py'],
      File['/etc/graphite/admin.ini']],
  }

  apache::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => '/var/lib/graphite/webapp',
    template => 'graphite/graphite.vhost.erb',
  }

  vcsrepo { '/opt/statsd':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/etsy/statsd.git',
  }

  file { '/etc/statsd':
    ensure  => directory,
  }

  file { '/etc/statsd/config.js':
    owner   => 'statsd',
    group   => 'statsd',
    mode    => '0444',
    content => template('graphite/config.js.erb'),
    require => File['/etc/statsd'],
  }

  file { '/etc/graphite/carbon.conf':
    mode    => '0444',
    content => template('graphite/carbon.conf.erb'),
    require => File['/etc/graphite'],
  }

  file { '/etc/graphite/graphite.wsgi':
    mode    => '0444',
    content => template('graphite/graphite.wsgi.erb'),
    require => File['/etc/graphite'],
  }

  file { '/etc/graphite/storage-schemas.conf':
    mode    => '0444',
    content => template('graphite/storage-schemas.conf.erb'),
    require => File['/etc/graphite'],
  }

  file { '/usr/local/lib/python2.7/dist-packages/graphite/local_settings.py':
    mode    => '0444',
    content => template('graphite/local_settings.py.erb'),
    require => Exec['install_graphite_web'],
  }

  file { '/usr/local/bin/graphite-init-db.py':
    mode    => '0555',
    source  => 'puppet:///modules/graphite/graphite-init-db.py'
  }

  file { '/etc/graphite/admin.ini':
    mode    => '0400',
    owner   => 'www-data',
    group   => 'www-data',
    content => template('graphite/admin.ini'),
    require => [ File['/etc/graphite'],
      Package['apache2']],
  }

  file { '/etc/init.d/carbon-cache':
    mode    => '0555',
    source  => 'puppet:///modules/graphite/carbon-cache.init'
  }

  file { '/etc/init.d/statsd':
    mode    => '0555',
    source  => 'puppet:///modules/graphite/statsd.init'
  }

  file { '/etc/default/statsd':
    mode    => '0444',
    source  => 'puppet:///modules/graphite/statsd.default'
  }

  service { 'carbon-cache':
    name       => 'carbon-cache',
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/carbon-cache'],
                    File['/etc/graphite/carbon.conf'],
                    Exec['install_carbon']],
  }

  service { 'statsd':
    name       => 'statsd',
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/statsd'],
                    File['/etc/statsd/config.js'],
                    Vcsrepo['/opt/statsd']],
  }

}

