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
  $auth_openid = undef,
  $docroot = '/var/www',
  $runtime_dir_mode = '0755',
  $download_url = 'https://github.com/LimeSurvey/LimeSurvey/archive/',
  $version = '3.7.0+180418',
  $www_group = 'www-data',
  $www_user = 'www-data',
  # These are required for bootstrapping, so do not have defaults.
  $adminuser,
  $adminpass,
  $adminmail,
) {

  $distro_packages = [
    'libapache2-mod-php',
    'php',
    'php-gd',
    'php-imap',
    'php-ldap',
    'php-mbstring',
    'php-mcrypt',
    'php-mysql',
    'php-xml',
    'php-zip',
    'ssl-cert',
  ]

  package { $distro_packages:
    ensure => present,
  }

  exec { 'limesurvey-download':
    path    => '/bin:/usr/bin',
    creates => "${docroot}/tmp/runtime",
    command => "bash -c 'cd /tmp; wget ${download_url}${version}.tar.gz'",
    require => File[$docroot],
    user    => $www_user,
  }

  exec { 'limesurvey-unzip':
    path    => '/bin:/usr/bin',
    cwd     => '/tmp',
    creates => "${docroot}/tmp/runtime",
    command => "bash -c 'cd /tmp; tar zxf /tmp/${version}.tar.gz -C ${docroot} --strip-components=1'",
    notify  => Exec['limesurvey-install'],
    require => Exec['limesurvey-download'],
    user    => $www_user,
  }

  exec { 'limesurvey-install':
    command     => "/usr/bin/php console.php install ${adminuser} ${adminpass} 'Default Administrator' ${adminmail}",
    cwd         => "${docroot}/application/commands",
    refreshonly => true,
    require     => [
      File["${docroot}/application/config/config.php"],
      Package[$distro_packages],
    ]
    user        => $www_user,
  }

  file { "/tmp/${version}.tar.gz":
    ensure  => absent,
    require => Exec['limesurvey-unzip'],
  }

  file { "${docroot}/tmp/runtime/":
    ensure  => directory,
    mode    => $runtime_dir_mode,
    require => Exec['limesurvey-install'],
  }

  file { "${docroot}/application/config/config.php":
    ensure  => present,
    owner   => $www_user,
    group   => $www_group,
    mode    => '0660',
    content => template ('openstack_project/survey.config.php.erb'),
    replace => true,
    require => Exec['limesurvey-unzip'],
  }

  include ::httpd
  ::httpd::vhost { $vhost_name:
    port     => 443,
    docroot  => $docroot,
    priority => '50',
    template => 'openstack_project/survey.vhost.erb',
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

  file { $docroot:
    ensure => directory,
    owner  => $www_user,
    group  => $www_group,
  }

  file { "${docroot}/robots.txt":
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
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
