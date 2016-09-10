# == Class: openstack_project::wiki
#
class openstack_project::wiki (
  $site_hostname,
  $sysadmins = [],
  $bup_user = undef,
  $serveradmin = undef,
  $ssl_cert_file_contents = undef,
  $ssl_key_file_contents = undef,
  $ssl_chain_file_contents = undef,
  $wg_dbserver = undef,
  $wg_dbname = undef,
  $wg_dbuser = undef,
  $wg_dbpassword = undef,
  $wg_secretkey = undef,
  $wg_upgradekey = undef,
  $wg_recaptchasitekey = undef,
  $wg_recaptchasecretkey = undef,
  $wg_googleanalyticsaccount = undef,
  $disallow_robots = undef,
) {

  package { ['openssl', 'ssl-cert', 'subversion']:
    ensure => present;
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  realize (
    User::Virtual::Localuser['rlane'],
    User::Virtual::Localuser['mkiss'],
    User::Virtual::Localuser['maxwell'],
  )

  class { 'mediawiki':
    role                       => 'all',
    mediawiki_location         => '/srv/mediawiki/w',
    mediawiki_images_location  => '/srv/mediawiki/images',
    serveradmin                => $serveradmin,
    site_hostname              => $site_hostname,
    ssl_cert_file_contents     => $ssl_cert_file_contents,
    ssl_key_file_contents      => $ssl_key_file_contents,
    ssl_chain_file_contents    => $ssl_chain_file_contents,
    wg_dbserver                => $wg_dbserver,
    wg_dbname                  => $wg_dbname,
    wg_dbuser                  => $wg_dbuser,
    wg_dbpassword              => $wg_dbpassword,
    wg_secretkey               => $wg_secretkey,
    wg_upgradekey              => $wg_upgradekey,
    wg_recaptchasitekey        => $wg_recaptchasitekey,
    wg_recaptchasecretkey      => $wg_recaptchasecretkey,
    wg_googleanalyticsaccount  => $wg_googleanalyticsaccount,
    wg_sitename                => 'OpenStack',
    wg_logo                    => "https://${site_hostname}/w/images/thumb/c/c4/OpenStack_Logo_-_notext.png/30px-OpenStack_Logo_-_notext.png",
    disallow_robots            => $disallow_robots,
  }
  class { 'memcached':
    max_memory => 2048,
    listen_ip  => '127.0.0.1',
    tcp_port   => 11000,
    udp_port   => 11000,
  }

  mysql_backup::backup_remote { 'wiki':
    database_host     => $wg_dbserver,
    database_user     => $wg_dbuser,
    database_password => $wg_dbpassword,
  }
  file { '/root/.my.cnf':
    ensure  => link,
    target  => '/root/.wiki_db.cnf',
    require => Mysql_backup::Backup_remote['wiki'],
  }

  if $bup_user != undef {
    include bup
    bup::site { 'rs-ord':
      backup_user   => $bup_user,
      backup_server => 'ci-backup-rs-ord.openstack.org',
    }
  }

  class { '::elasticsearch':
    es_template_config => {
      'bootstrap.mlockall'               => true,
      'discovery.zen.ping.unicast.hosts' => ['localhost'],
    },
    version            => '1.3.2',
    heap_size          => '1g',
  }

}
