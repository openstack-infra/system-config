class pypimirror ( $base_url,
                   $log_filename = "/var/log/pypimirror.log",
                   $mirror_file_path = "/var/lib/pypimirror",
                   $pip_download = "/var/lib/pip-download",
                   $pip_cache = "/var/cache/pip",
                   $projects = [] )
{

  include pip

  package { 'nginx':
    ensure => present,
  }

  package { 'pip':
    ensure => latest,  # okay to use latest for pip
    provider => 'pip',
    require => Class[pip]
  }

  file { '/usr/local/mirror_scripts':
    ensure => 'directory',
    mode => 755,
    owner => 'root',
    group => 'root',
  }
    
  file { $pip_download:
    ensure => 'directory',
    mode => 755,
    owner => 'root',
    group => 'root',
  }
    
  file { $pip_cache:
    ensure => 'directory',
    mode => 755,
    owner => 'root',
    group => 'root',
  }
    
  file { '/usr/local/mirror_scripts/run-mirror.sh':
    ensure => present,
    mode => 755,
    owner => 'root',
    group => 'root',
    content => template('pypimirror/run-mirror.sh.erb'),
    require => File['/usr/local/mirror_scripts'],
  }

  file { '/usr/local/mirror_scripts/pull-repo.sh':
    ensure => present,
    mode => 755,
    owner => 'root',
    group => 'root',
    source => "puppet:///modules/pypimirror/pull-repo.sh",
    require => File['/usr/local/mirror_scripts'],
  }

  file { '/usr/local/mirror_scripts/process_cache.py':
    ensure => present,
    mode => 755,
    owner => 'root',
    group => 'root',
    source => "puppet:///modules/pypimirror/process_cache.py",
    require => File['/usr/local/mirror_scripts'],
  }

  # Add cron job to update the mirror

  cron { "update_mirror":
    user => root,
    minute => "0",
    command => '/usr/local/mirror_scripts/run-mirror.sh',
    require => File["/usr/local/mirror_scripts/run-mirror.sh"],
  }

  # Rotate the mirror log file

  include logrotate
  logrotate::file {"pypimirror":
    log => $log_filename,
    options => ["compress", "delaycompress", "missingok", "rotate 7", "daily", "notifempty"],
    require => Cron["update_mirror"],
  }

  # Setup the web server

  service { "nginx":
    ensure => running,
    hasrestart => true
  }

  file { "/etc/nginx/sites-available/default":
    ensure => present,
    content => template('pypimirror/nginx_default.erb'),
    replace => true,
    owner => "root",
    group => "root",
    require => Package["nginx"],
    notify => Service["nginx"],
  }
}
