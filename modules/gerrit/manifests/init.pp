# Install and maintain Gerrit Code Review.
# params:
#   vhost_name:
#     used in the Apache virtual host, eg., review.example.com
#   canonicalweburl:
#     Used in the Gerrit config to generate links,
#       eg., https://review.example.com/
#   ssl_cert_file:
#   ssl_key_file:
#     Used in the Apache virtual host to specify the SSL cert and key files.
#   ssl_chain_file:
#     Optional, if you have an intermediate cert Apache should serve.
#   ssl_*_file_contents:
#     Optional, the contents of the respective cert files as a string. Will be
#     used to have Puppet ensure the contents of these files. Default value of
#     '' means Puppet should not manage these files.
#   openidssourl:
#     The URL to use for OpenID in SSO mode.
#   email:
#     The email address Gerrit should use when sending mail.
#   database_poollimit:
#   container_heaplimit:
#   core_packedgitopenfiles:
#   core_packedgitlimit:
#   core_packedgitwindowsize:
#   sshd_threads:
#   sshd_listen_address:
#   httpd_acceptorthreads:
#   httpd_minthreads:
#   httpd_maxthreads:
#   httpd_maxwait:
#     Gerrit configuration options; see Gerrit docs.
#   commentlinks:
#     A list of regexes Gerrit should hyperlink.
#   war:
#     The URL of the Gerrit WAR that should be downloaded and installed.
#     Note that only the final component is used for comparing to the most
#     recently installed WAR.  In other words, if you update the war from:
#
#       http://tarballs.openstack.org/ci/gerrit.war
#     to:
#       http://somewhereelse.example.com/gerrit.war
#
#     Gerrit won't be updated unless you delete gerrit.war from
#     ~gerrit2/gerrit-wars.  But if you change the URL from:
#
#       http://tarballs.openstack.org/ci/gerrit-2.2.2.war
#     to:
#       http://tarballs.openstack.org/ci/gerrit-2.3.0.war
#     Gerrit will be upgraded on the next puppet run.
#   contactstore:
#     A boolean enabling the contact store feature
#   contactstore_appsec:
#     An application shared secret for the contact store protocol
#   contactstore_pubkey:
#     A public key with which to encrypt contact information
#   contactstore_url:
#     A URL for the remote contact store application
#   replicate_local:
#     A boolean enabling local replication for apache acceleration
#   gitweb:
#     A boolean enabling gitweb
#   cgit:
#     A boolean enabling cgit
#   web_repo_url:
#     Url for setting the location of an external git browser
#   testmode:
#     Set this to true to disable cron jobs and replication,
#     which can interfere with testing.
# TODO: make more gerrit options configurable here
#
class gerrit(
  $war = '',
  $mysql_password = '',
  $mysql_root_password = '',
  $email_private_key = '',
  $vhost_name = $::fqdn,
  $canonicalweburl = "https://${::fqdn}/",
  $robots_txt_source = '', # If left empty, the gerrit default will be used.
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $ssh_dsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_dsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_project_rsa_key_contents = '', # If left empty will not create file.
  $ssh_project_rsa_pubkey_contents = '', # If left empty will not create file.
  $openidssourl = 'https://login.launchpad.net/+openid',
  $email = '',
  $database_poollimit = '',
  $container_heaplimit = '',
  $core_packedgitopenfiles = '',
  $core_packedgitlimit = '',
  $core_packedgitwindowsize = '',
  $sshd_threads = '',
  $sshd_listen_address = '*:29418',
  $httpd_acceptorthreads = '',
  $httpd_minthreads = '',
  $httpd_maxthreads = '',
  $httpd_maxwait = '',
  $commentlinks = [],
  $contactstore = false,
  $contactstore_appsec = '',
  $contactstore_pubkey = '',
  $contactstore_url = '',
  $enable_melody = false,
  $melody_session = false,
  $replicate_local = false,
  $replication = [],
  $replication_targets = [],
  $gitweb = true,
  $cgit = false,
  $web_repo_url = '',
  $testmode = false
) {
  include apache
  include jeepyb
  include pip

  $java_home = $::lsbdistcodename ? {
    'precise' => '/usr/lib/jvm/java-7-openjdk-amd64/jre',
  }

  user { 'gerrit2':
    ensure     => present,
    comment    => 'Gerrit',
    home       => '/home/gerrit2',
    shell      => '/bin/bash',
    gid        => 'gerrit2',
    managehome => true,
    require    => Group['gerrit2'],
  }

  group { 'gerrit2':
    ensure => present,
  }

  if ($gitweb) {
    package { 'gitweb':
      ensure => present,
    }
  }

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  package { 'openjdk-6-jre-headless':
    ensure  => purged,
    require => Package['openjdk-7-jre-headless'],
  }

  if ! defined(Package['gerritlib']) {
    package { 'gerritlib':
      ensure   => latest,
      provider => 'pip',
      require  => Class[pip],
    }
  }

  file { '/var/log/gerrit':
    ensure => directory,
    owner  => 'gerrit2',
  }

  # Prepare gerrit directories.  Even though some of these would be created
  # by the init command, we can go ahead and create them now and populate them.
  # That way the config files are already in place before init runs.

  file { '/home/gerrit2/review_site':
    ensure  => directory,
    owner   => 'gerrit2',
    require => User['gerrit2'],
  }

  file { '/home/gerrit2/review_site/etc':
    ensure  => directory,
    owner   => 'gerrit2',
    require => File['/home/gerrit2/review_site'],
  }

  file { '/home/gerrit2/review_site/bin':
    ensure  => directory,
    owner   => 'gerrit2',
    require => File['/home/gerrit2/review_site'],
  }

  file { '/home/gerrit2/review_site/static':
    ensure  => directory,
    owner   => 'gerrit2',
    require => File['/home/gerrit2/review_site'],
  }

  file { '/home/gerrit2/review_site/hooks':
    ensure  => directory,
    owner   => 'gerrit2',
    require => File['/home/gerrit2/review_site'],
  }

  file { '/home/gerrit2/review_site/lib':
    ensure  => directory,
    owner   => 'gerrit2',
    require => File['/home/gerrit2/review_site'],
  }

  # Skip replication if we're in test mode
  if ($testmode == false) {
    file { '/home/gerrit2/review_site/etc/replication.config':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/replication.config.erb'),
      replace => true,
      require => File['/home/gerrit2/review_site/etc'],
    }
  }

  # Gerrit sets these permissions in 'init'; don't fight them.
  file { '/home/gerrit2/review_site/etc/gerrit.config':
    ensure  => present,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0644',
    content => template('gerrit/gerrit.config.erb'),
    replace => true,
    require => File['/home/gerrit2/review_site/etc'],
  }

  # Secret files.

  # Gerrit sets these permissions in 'init'; don't fight them.  If
  # these permissions aren't set correctly, gerrit init will write a
  # new secure.config file and lose the mysql password.
  file { '/home/gerrit2/review_site/etc/secure.config':
    ensure  => present,
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0600',
    content => template('gerrit/secure.config.erb'),
    replace => true,
    require => File['/home/gerrit2/review_site/etc'],
  }

  # Set up MySQL.

  class { 'mysql::server':
    config_hash => {
      'root_password'  => $mysql_root_password,
      'default_engine' => 'InnoDB',
      'bind_address'   => '127.0.0.1',
    }
  }
  include mysql::server::account_security

  mysql::db { 'reviewdb':
    user     => 'gerrit2',
    password => $mysql_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'latin1',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  # Set up apache.

  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'gerrit/gerrit.vhost.erb',
    ssl      => true,
  }
  a2mod { 'rewrite':
    ensure => present,
  }
  a2mod { 'proxy':
    ensure => present,
  }
  a2mod { 'proxy_http':
    ensure => present,
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $robots_txt_source != '' {
    file { '/home/gerrit2/review_site/static/robots.txt':
      owner    => 'root',
      group    => 'root',
      mode     => '0444',
      source   => $robots_txt_source,
      require  => File['/home/gerrit2/review_site/static'],
    }
  }

  if $ssh_dsa_key_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_host_dsa_key':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $ssh_dsa_key_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_dsa_pubkey_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_host_dsa_key.pub':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $ssh_dsa_pubkey_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_rsa_key_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_host_rsa_key':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $ssh_rsa_key_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_rsa_pubkey_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_host_rsa_key.pub':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $ssh_rsa_pubkey_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_project_rsa_key_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_project_rsa_key':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $ssh_project_rsa_key_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_project_rsa_pubkey_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_project_rsa_key.pub':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $ssh_project_rsa_pubkey_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  # Install Gerrit itself.

  # The Gerrit WAR is specified as a url like
  #   'http://tarballs.openstack.org/ci/gerrit-2.2.2-363-gd0a67ce.war'
  # Set $basewar so that we can work with filenames like
  #   gerrit-2.2.2-363-gd0a67ce.war'.

  if $war =~ /.*\/(.*)/ {
    $basewar = $1
  } else {
    $basewar = $war
  }

  # This directory is used to download and cache gerrit war files.
  # That way the download and install steps are kept separate.
  file { '/home/gerrit2/gerrit-wars':
    ensure  => directory,
    require => User['gerrit2'],
  }

  # If we don't already have the specified WAR, download it.
  exec { "download:${war}":
    command => "/usr/bin/wget ${war} -O /home/gerrit2/gerrit-wars/${basewar}",
    creates => "/home/gerrit2/gerrit-wars/${basewar}",
    require => File['/home/gerrit2/gerrit-wars'],
  }

  # If gerrit.war isn't the same as $basewar, install it.
  file { '/home/gerrit2/review_site/bin/gerrit.war':
    ensure  => present,
    source  => "file:///home/gerrit2/gerrit-wars/${basewar}",
    require => Exec["download:${war}"],
    replace => true,
    # user, group, and mode have to be set this way to avoid retriggering
    # gerrit-init on every run because gerrit init sets them this way
    owner   => 'gerrit2',
    group   => 'gerrit2',
    mode    => '0644',
  }


  # If gerrit.war was just installed, run the Gerrit "init" command.
  exec { 'gerrit-initial-init':
    user      => 'gerrit2',
    command   => '/usr/bin/java -jar /home/gerrit2/review_site/bin/gerrit.war init -d /home/gerrit2/review_site --batch --no-auto-start',
    subscribe => File['/home/gerrit2/review_site/bin/gerrit.war'],
    require   => [Package['openjdk-7-jre-headless'],
                  User['gerrit2'],
                  Mysql::Db['reviewdb'],
                  File['/home/gerrit2/review_site/etc/gerrit.config'],
                  File['/home/gerrit2/review_site/etc/secure.config']],
    notify    => Exec['gerrit-start'],
    unless    => '/usr/bin/test -f /etc/init.d/gerrit',
  }

  # If a new gerrit.war was just installed, run the Gerrit "init" command.
  # Stop is included here because it may not be running or the init
  # script may not exist, and in those cases, we don't care if it fails.
  # Running the init script as the gerrit2 user _does_ work.
  exec { 'gerrit-init':
    user        => 'gerrit2',
    command     => '/etc/init.d/gerrit stop; /usr/bin/java -jar /home/gerrit2/review_site/bin/gerrit.war init -d /home/gerrit2/review_site --batch --no-auto-start',
    subscribe   => File['/home/gerrit2/review_site/bin/gerrit.war'],
    refreshonly => true,
    require     => [Package['openjdk-7-jre-headless'],
                    User['gerrit2'],
                    Mysql::Db['reviewdb'],
                    File['/home/gerrit2/review_site/etc/gerrit.config'],
                    File['/home/gerrit2/review_site/etc/secure.config']],
    notify      => Exec['gerrit-start'],
    onlyif      => '/usr/bin/test -f /etc/init.d/gerrit',
  }

  # Symlink the init script.
  file { '/etc/init.d/gerrit':
    ensure  => link,
    target  => '/home/gerrit2/review_site/bin/gerrit.sh',
    require => Exec['gerrit-initial-init'],
  }

  # The init script requires the path to gerrit to be set.
  file { '/etc/default/gerritcodereview':
    ensure  => present,
    source  => 'puppet:///modules/gerrit/gerritcodereview.default',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
  }

  # Make sure the init script starts on boot.
  file { ['/etc/rc0.d/K10gerrit',
          '/etc/rc1.d/K10gerrit',
          '/etc/rc2.d/S90gerrit',
          '/etc/rc3.d/S90gerrit',
          '/etc/rc4.d/S90gerrit',
          '/etc/rc5.d/S90gerrit',
          '/etc/rc6.d/K10gerrit']:
    ensure  => link,
    target  => '/etc/init.d/gerrit',
    require => File['/etc/init.d/gerrit'],
  }

  exec { 'gerrit-start':
    command     => '/etc/init.d/gerrit start',
    require     => File['/etc/init.d/gerrit'],
    refreshonly => true,
  }

  file { '/usr/local/gerrit':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/gerrit/scripts':
    ensure  => absent,
  }

  # Install Bouncy Castle's OpenPGP plugin and populate the contact store
  # public key file if we're using that feature.
  if ($contactstore == true) {
    package { 'libbcpg-java':
      ensure => present,
    }
    file { '/home/gerrit2/review_site/lib/bcpg.jar':
      ensure  => link,
      target  => '/usr/share/java/bcpg.jar',
      require => [
        Package['libbcpg-java'],
        File['/home/gerrit2/review_site/lib'],
      ],
    }
    file { '/home/gerrit2/review_site/etc/contact_information.pub':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/contact_information.pub.erb'),
      replace => true,
      require => File['/home/gerrit2/review_site/etc'],
    }
    file { '/home/gerrit2/review_site/lib/fakestore.cgi':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0555',
      source  => 'puppet:///modules/gerrit/fakestore.cgi',
      require => File['/home/gerrit2/review_site/lib'],
    }
  }
}
