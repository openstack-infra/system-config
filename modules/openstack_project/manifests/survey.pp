class openstack_project::survey (
  $vhost_name = $::fqdn,
  $ssl_cert_file = '/etc/ssl/certs/survey.openstack.org.pem',
  $ssl_key_file = '/etc/ssl/private/survey.openstack.org.key',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $dbpassword = '',
  $dbhost = '',
  # Table containing openid auth details. If undef not enabled
  # Example dict:
  # {
  #   banner         => "Welcome",
  #   singleIdp      => "https://openstackid.org",
  #   trusted        => '^https://openstackid.org/.*$',
  #   any_valid_user => false,
  #   users          => ['https://openstackid.org/foo',
  #                      'https://openstackid.org/bar'],
  # }
  # Note that if you care which users get access set any_valid_user to false
  # and then provide an explicit list of openids in the users list. Otherwise
  # set any_valid_user to true and any successfully authenticated user will
  # get access.
  $auth_openid             = undef,
) {
  class { '::limesurvey':
    install_path     => $docroot,
    download_url     => 'https://github.com/LimeSurvey/LimeSurvey/archive/',
    version          => '2.57.0+161202',
    runtime_dir_mode => 'whatisthis',
    www_group        => 'doIneedthis',
    www_user         => 'feelslikeIdontneedthis',
    dbname           => 'limesurvey',
    dbuser           => 'limesurvey',
    dbpassword       => '$dbpassword',
    dbhost           => '$dbhost',
    manage_database  => false,
    manage_webserver => false,
    manage_php       => true,
  }

  package { 'ssl-cert':
    ensure => present,
  }

  include ::httpd
  ::httpd::vhost { $vhost_name:
    port     => 443,
    docroot  => $docroot,
    priority => '50',
    template => 'survey/survey.vhost.erb',
    ssl      => true,
  }

  if !defined(Mod['rewrite']) {
    httpd::mod { 'rewrite':
      ensure => present,
    }
  }
  if !defined(Mod['proxy']) {
    httpd::mod { 'proxy':
      ensure => present,
    }
  }
  if !defined(Mod['proxy_http']) {
    httpd::mod { 'proxy_http':
      ensure => present,
    }
  }
  if ($auth_openid != undef) {
    if !defined(Package['libapache2-mod-auth-openid']) {
      package { 'libapache2-mod-auth-openid':
        ensure => present,
      }
    }
    if !defined(Mod['auth_openid']) {
      httpd::mod { 'auth_openid':
        ensure  => present,
        require => Package['libapache2-mod-auth-openid'],
      }
    }
  }

  file { '/etc/apache2':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  if ($::lsbdistcodename == 'xenial') {
    file { '/etc/apache2/conf.d':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/etc/apache2'],
    }
    file { '/etc/apache2/conf.d/connection-tuning':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/survey/apache-connection-tuning',
      notify  => Service['httpd'],
      require => File['/etc/apache2/conf.d'],
    }
  } else {
    file { '/etc/apache2/conf-available':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/etc/apache2'],
    }
    file { '/etc/apache2/conf-available/connection-tuning':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/survey/apache-connection-tuning',
      require => File['/etc/apache2/conf-available'],
    }

    file { '/etc/apache2/conf-enabled':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File['/etc/apache2'],
    }
    file { '/etc/apache2/conf-enabled/connection-tuning':
      ensure  => link,
      target  => '/etc/apache2/conf-available/connection-tuning.conf',
      notify  => Service['httpd'],
      require => [
        File['/etc/apache2/conf-enabled'],
        File['/etc/apache2/conf-available/connection-tuning'],
      ],
    }
  }

  file { $docroot:
    ensure => directory,
  }

  file { "${docroot}/robots.txt":
    ensure  => present,
    source  => 'puppet:///modules/survey/robots.txt',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => File[$docroot],
  }

  file { '/etc/ssl/certs':
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    mode   => '0700',
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }
}
