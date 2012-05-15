class pypimirror ( $base_url,
                   $log_filename = "/var/log/pypimirror.log",
                   $mirror_file_path = "/var/lib/pypimirror",
                   $fetch_since_days = 1,
                   $package_matches = ["*"],
                   $external_links = true,
                   $follow_external_index_pages = false )
{

  if $external_links == true {
    $external_links_real = 'True'
  }
  else {
    $external_links_real = 'False'
  }

  if $follow_external_index_pages == true {
    $follow_external_index_pages_real = 'True'
  }
  else {
    $follow_external_index_pages_real = 'False'
  }

  $packages = [ 'mercurial',
                'nginx',
                'python-pip' ]

  package { $packages:
    ensure => present,
  }

  # Build the mirror config file based on options provided.

  file { 'pypimirror.cfg':
    path => '/etc/pypimirror.cfg',
    ensure => present,
    mode => 644,
    owner => 'root',
    group => 'root',
    content => template('pypimirror/config.erb'),
  }

  # if we already have the repo the pull updates

  exec { "update_z3c.pypimirror":
    command => "hg pull",
    cwd => "/usr/local/z3c.pypimirror",
    path => "/bin:/usr/bin",
    onlyif => "test -d /usr/local/z3c.pypimirror",
    before => Exec["get_z3c.pypimirror"],
  }

  # otherwise get a new clone of it

  exec { "get_z3c.pypimirror":
    command => "hg clone https://bitbucket.org/rsyring/z3c.pypimirror /usr/local/z3c.pypimirror",
    path => "/bin:/usr/bin",
    onlyif => "test ! -d /usr/local/z3c.pypimirror"
  }

  exec { "install_z3c.pypimirror":
    command => "python setup.py install",
    cwd => "/usr/local/z3c.pypimirror",
    path => "/bin:/usr/bin",
    subscribe => [ Exec["get_z3c.pypimirror"], Exec["update_z3c.pypimirror"] ],
  }

  exec { "initialize_mirror":
    command => "pypimirror --initial-fetch /etc/pypimirror.cfg",
    path => "/bin:/usr/bin:/usr/local/bin",
    onlyif => "test ! -d ${mirror_file_path}",
    require => [ Exec["get_z3c.pypimirror"], Exec["install_z3c.pypimirror"] ],
  }

  # Add cron job to update the mirror

  cron { "update_mirror":
    user => root,
    hour => 0,
    command => '/usr/local/bin/pypimirror --update-fetch /etc/pypimirror.cfg',
    require => Exec["install_z3c.pypimirror"],
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
