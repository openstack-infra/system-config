class jenkins_master($site, $serveradmin, $logo,
      $ssl_cert_file='',
      $ssl_key_file='',
      $ssl_chain_file=''
  ) {

  include pip
  include apt

  #This key is at http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key
  apt::key { "jenkins":
    key        => "D50582E6",
    key_source => "http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key",
    require    => Package["wget"]
  }

  apt::source { 'jenkins':
    location => "http://pkg.jenkins-ci.org/debian",
    release => "binary/",
    repos => "",
    require => Apt::Key['jenkins'],
    notify => Class['Apt::Update']
  }

  file { '/etc/apache2/sites-available/jenkins':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    content => template("jenkins_master/jenkins.vhost.erb"),
    replace => 'true',
    require => Package['apache2'],
  }

  file { '/etc/apache2/sites-enabled/jenkins':
    target => '/etc/apache2/sites-available/jenkins',
    ensure => link,
    require => [
      File['/etc/apache2/sites-available/jenkins'],
      File['/etc/apache2/mods-enabled/ssl.conf'],
      File['/etc/apache2/mods-enabled/ssl.load'],
      File['/etc/apache2/mods-enabled/rewrite.load'],
      File['/etc/apache2/mods-enabled/proxy.conf'],
      File['/etc/apache2/mods-enabled/proxy.load'],
      File['/etc/apache2/mods-enabled/proxy_http.load'],
    ],
  }

  file { '/etc/apache2/sites-enabled/000-default':
    require => File['/etc/apache2/sites-available/jenkins'],
    ensure => absent,
  }

  file { '/etc/apache2/mods-enabled/ssl.conf':
    target => '/etc/apache2/mods-available/ssl.conf',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/ssl.load':
    target => '/etc/apache2/mods-available/ssl.load',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/rewrite.load':
    target => '/etc/apache2/mods-available/rewrite.load',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/proxy.conf':
    target => '/etc/apache2/mods-available/proxy.conf',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/proxy.load':
    target => '/etc/apache2/mods-available/proxy.load',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/proxy_http.load':
    target => '/etc/apache2/mods-available/proxy_http.load',
    ensure => link,
    require => Package['apache2'],
  }

  $packages = [
    "python-babel",
    "apache2",
    "wget",
  ]

  package { $packages:
    ensure => "present",
  }

  package { "jenkins":
    ensure => "present",
    require => Apt::Source['jenkins'],
  }

  service { "versions":
    provider => upstart,
    ensure => running,
  }

  file { '/etc/init/versions.conf':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => "puppet:///modules/jenkins_master/versions.conf",
    replace => 'true',
    notify => Service["versions"]
  }

  package { "apache-libcloud":
    ensure => present,
    provider => pip,
    require => Class[pip]
  }

  package { "git-review":
    ensure => latest,
    provider => pip,
    require => Class[pip]
  }

  package { "tox":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Class[pip],
  }

  exec { "update apt cache":
    subscribe => [ File["/etc/apt/sources.list.d/jenkins.list"]],
    refreshonly => true,
    path => "/bin:/usr/bin",
    command => "apt-get update",
  }

  exec { "gracefully restart apache":
    subscribe => [ File["/etc/apache2/sites-available/jenkins"]],
    refreshonly => true,
    path => "/bin:/usr/bin:/usr/sbin",
    command => "apache2ctl graceful",
  }

  file { "/var/lib/jenkins/plugins/simple-theme-plugin":
    ensure => directory,
    owner => 'jenkins',
    group => 'nogroup'
  }

  file { "/var/lib/jenkins/plugins/simple-theme-plugin/openstack.css":
    ensure => present,
    source => "puppet:///modules/jenkins_master/openstack.css",
    require => File["/var/lib/jenkins/plugins/simple-theme-plugin"]
  }

  file { "/var/lib/jenkins/plugins/simple-theme-plugin/openstack.js":
    ensure => present,
    content => template("jenkins_master/openstack.js.erb"),
    require => File["/var/lib/jenkins/plugins/simple-theme-plugin"]
  }

  file { "/var/lib/jenkins/plugins/simple-theme-plugin/openstack-page-bkg.jpg":
    ensure => present,
    source => "puppet:///modules/jenkins_master/openstack-page-bkg.jpg",
    require => File["/var/lib/jenkins/plugins/simple-theme-plugin"]
  }

  file { "/var/lib/jenkins/plugins/simple-theme-plugin/title.png":
    ensure => present,
    source => "puppet:///modules/jenkins_master/${logo}",
    require => File["/var/lib/jenkins/plugins/simple-theme-plugin"]
  }

  file { '/usr/local/jenkins':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
  }

  file { '/usr/local/jenkins/slave_scripts':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    require => File['/usr/local/jenkins'],
    source => [
                "puppet:///modules/jenkins_slave/slave_scripts",
              ],
  }
}
