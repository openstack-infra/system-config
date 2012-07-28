# Install and maintain Gerrit Code Review.
# params:
#   virtual_hostname:
#     used in the Apache virtual host, eg., review.example.com
#   canonicalweburl:
#     Used in the Gerrit config to generate links, eg., https://review.example.com/
#   ssl_cert_file:
#   ssl_key_file:
#     Used in the Apache virtual host to specify the SSL cert and key files.
#   ssl_chain_file:
#     Optional, if you have an intermediate cert Apache should serve.
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
#   replicate_github:
#     A boolean enabling replication to github
#   replicate_local:
#     A boolean enabling local replication for apache acceleration
#   testmode:
#     Set this to true to disable cron jobs and replication,
#     which can interfere with testing.
# TODO: make more gerrit options configurable here

class gerrit($virtual_hostname=$fqdn,
      $canonicalweburl="https://$fqdn/",
      $ssl_cert_file='/etc/ssl/certs/ssl-cert-snakeoil.pem',
      $ssl_key_file='/etc/ssl/private/ssl-cert-snakeoil.key',
      $ssl_chain_file='',
      $openidssourl="https://login.launchpad.net/+openid",
      $email='',
      $database_poollimit='',
      $container_heaplimit='',
      $core_packedgitopenfiles='',
      $core_packedgitlimit='',
      $core_packedgitwindowsize='',
      $sshd_threads='',
      $httpd_acceptorthreads='',
      $httpd_minthreads='',
      $httpd_maxthreads='',
      $httpd_maxwait='',
      $commentlinks = [],
      $war,
      $enable_melody = 'false',
      $melody_session = 'false',
      $mysql_password,
      $mysql_root_password,
      $email_private_key,
      $replicate_github=false,
      $replicate_local=true,
      $replication_targets=[],
      $testmode=false
      ) {

  include apache
  require apache::dev

  $java_home = $lsbdistcodename ? {
      "precise" => "/usr/lib/jvm/java-6-openjdk-amd64/jre",
      "oneiric" => "/usr/lib/jvm/java-6-openjdk/jre",
      "natty" => "/usr/lib/jvm/java-6-openjdk/jre",
    }

  user { "gerrit2":
    ensure => present,
    comment => "Gerrit",
    home => "/home/gerrit2",
    shell => "/bin/bash",
    gid => "gerrit2",
    managehome => true,
    require => Group["gerrit2"]
  }

  group { "gerrit2":
    ensure => present
  }

  $packages = ["gitweb",
	       "openjdk-6-jre-headless"]

  package { $packages:
    ensure => present,
  }

  file { "/var/log/gerrit":
    ensure => "directory",
    owner => 'gerrit2'
  }

  # Prepare gerrit directories.  Even though some of these would be created
  # by the init command, we can go ahead and create them now and populate them.
  # That way the config files are already in place before init runs.

  file { "/home/gerrit2/review_site":
    ensure => "directory",
    owner => "gerrit2",
    require => User["gerrit2"]
  }

  file { "/home/gerrit2/review_site/etc":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  file { "/home/gerrit2/review_site/bin":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  file { "/home/gerrit2/review_site/static":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  file { "/home/gerrit2/review_site/hooks":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  # Skip replication if we're in test mode
  if ($testmode == false) {
# TODO: The local repos need
# to be managed in here when we get project creation handled
    file { '/home/gerrit2/review_site/etc/replication.config':
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      content => template('gerrit/replication.config.erb'),
      replace => 'true',
      require => File["/home/gerrit2/review_site/etc"]
    }
  }

  # Gerrit sets these permissions in 'init'; don't fight them.
  file { '/home/gerrit2/review_site/etc/gerrit.config':
    owner => 'gerrit2',
    group => 'gerrit2',
    mode => 644,
    ensure => 'present',
    content => template('gerrit/gerrit.config.erb'),
    replace => 'true',
    require => File["/home/gerrit2/review_site/etc"]
  }

  # Secret files.

  # Gerrit sets these permissions in 'init'; don't fight them.  If
  # these permissions aren't set correctly, gerrit init will write a
  # new secure.config file and lose the mysql password.
  file { '/home/gerrit2/review_site/etc/secure.config':
    owner => 'gerrit2',
    group => 'gerrit2',
    mode => 600,
    ensure => 'present',
    content => template('gerrit/secure.config.erb'),
    replace => 'true',
    require => File["/home/gerrit2/review_site/etc"]
  }

# Set up MySQL.

  class {"mysql::server":
    config_hash => {
      'root_password' => "${mysql_root_password}",
      'default_engine' => 'InnoDB',
      'bind_address' => '127.0.0.1',
    }
  }

  mysql::db { "reviewdb":
    user => "gerrit2",
    password => "${mysql_password}",
    host => "localhost",
    grant => "all",
    charset => "latin1",
  }

# Set up apache.

  apache::vhost { $virtual_hostname:
    port => 443,
    docroot => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'gerrit/gerrit.vhost.erb',
    ssl => true,
  }
  a2mod { 'rewrite':
    ensure => present
  }
  a2mod { 'proxy':
    ensure => present
  }
  a2mod { 'proxy_http':
    ensure => present
  }

  # Install Gerrit itself.

  # The Gerrit WAR is specified as a url like 'http://tarballs.openstack.org/ci/gerrit-2.2.2-363-gd0a67ce.war'
  # Set $basewar so that we can work with filenames like gerrit-2.2.2-363-gd0a67ce.war'.

  if $war =~ /.*\/(.*)/ {
    $basewar = $1
  } else {
    $basewar = $war
  }

  # This directory is used to download and cache gerrit war files.
  # That way the download and install steps are kept separate.
  file { "/home/gerrit2/gerrit-wars":
    ensure => "directory",
    require => User["gerrit2"]
  }

  # If we don't already have the specified WAR, download it.
  exec { "download:$war":
    command => "/usr/bin/wget $war -O /home/gerrit2/gerrit-wars/$basewar",
    creates => "/home/gerrit2/gerrit-wars/$basewar",
    require => File["/home/gerrit2/gerrit-wars"],
  }

  # If gerrit.war isn't the same as $basewar, install it.
  file { "/home/gerrit2/review_site/bin/gerrit.war":
    source => "file:///home/gerrit2/gerrit-wars/$basewar",
    require => Exec["download:$war"],
    ensure => present,
    replace => 'true',
    # user, group, and mode have to be set this way to avoid retriggering gerrit-init on every run
    # because gerrit init sets them this way
    owner => 'gerrit2',
    group => 'gerrit2',
    mode => 644,
  }

  # If gerrit.war was just installed, run the Gerrit "init" command.
  # Stop is included here because it may not be running or the init
  # script may not exist, and in those cases, we don't care if it fails.
  # Running the init script as the gerrit2 user _does_ work.
  exec { "gerrit-init":
    user => 'gerrit2',
    command => "/etc/init.d/gerrit stop; /usr/bin/java -jar /home/gerrit2/review_site/bin/gerrit.war init -d /home/gerrit2/review_site --batch --no-auto-start",
    subscribe => File["/home/gerrit2/review_site/bin/gerrit.war"],
    refreshonly => true,
    require => [Package["openjdk-6-jre-headless"],
                User["gerrit2"],
                Mysql::Db["reviewdb"],
                File["/home/gerrit2/review_site/etc/gerrit.config"],
                File["/home/gerrit2/review_site/etc/secure.config"]],
    notify => Exec["gerrit-start"],
  }

  # Symlink the init script.
  file { "/etc/init.d/gerrit":
    ensure => link,
    target => '/home/gerrit2/review_site/bin/gerrit.sh',
    require => Exec['gerrit-init'],
  }

  # The init script requires the path to gerrit to be set.
  file { "/etc/default/gerritcodereview":
    source => 'puppet:///modules/gerrit/gerritcodereview.default',
    ensure => present,
    replace => 'true',
    owner => 'root',
    group => 'root',
    mode => 444,
  }

  # Make sure the init script starts on boot.
  file { ['/etc/rc0.d/K10gerrit',
          '/etc/rc1.d/K10gerrit',
          '/etc/rc2.d/S90gerrit',
          '/etc/rc3.d/S90gerrit',
          '/etc/rc4.d/S90gerrit',
          '/etc/rc5.d/S90gerrit',
          '/etc/rc6.d/K10gerrit']:
    ensure => link,
    target => '/etc/init.d/gerrit',
    require => File['/etc/init.d/gerrit'],
  }

  exec { "gerrit-start":
      command => '/etc/init.d/gerrit start',
      require => File['/etc/init.d/gerrit'],
      refreshonly => true,
  }

  file { '/usr/local/gerrit':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
  }

  file { '/usr/local/gerrit/scripts':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    require => File['/usr/local/gerrit'],
    source => [
                "puppet:///modules/gerrit/scripts",
              ],
  }
}
