# == Class: openstack_project::debrepo
#
class openstack_project::debrepo (
  $sysadmins = []
  ) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [22, 80],
    sysadmins                 => $sysadmins
  }

  include apache

  package {
    ['gnupg', 'reprepro', 'inoticoming']:
      ensure => installed,
      provider => apt;
  }

  file {

    [ '/srv/debrepo',
      '/srv/debrepo/conf',
      '/srv/debrepo/pub',
      '/srv/debrepo/pub/uca',
      '/srv/debrepo/logs',
      '/srv/debrepo/logs/incoming',
      '/srv/debrepo/tmp',
      '/srv/debrepo/morgue']:
      ensure => directory,
      mode => '0755', owner => debrepo, group => debrepo,
      require => [ User['debrepo'], Group['debrepo'] ];

    '/srv/debrepo/incoming':
      ensure => directory,
      mode => '0775', owner => debrepo, group => debupload,
      require => [ User['debrepo'], Group['debupload'] ];

    '/srv/debrepo/conf/distributions':
      source => [ 'puppet:///modules/openstack_project/debrepo/distributions' ],
      mode => '0644', owner => root, group => root;

    '/srv/debrepo/conf/incoming':
      source => [ 'puppet:///modules/openstack_project/debrepo/incoming' ],
      mode => '0644', owner => root, group => root;

    '/srv/debrepo/conf/updates':
      source => [ 'puppet:///modules/openstack_project/debrepo/updates' ],
      mode => '0644', owner => root, group => root;

    '/srv/debrepo/ubuntu-cloud-key.asc':
      source => [ 'puppet:///modules/openstack_project/debrepo/ubuntu-cloud-key.asc' ],
      mode => '0644', owner => root, group => root;

    '/etc/systemd/system/inoticoming.service':
      source => [ 'puppet:///modules/openstack_project/debrepo/inoticoming.service' ],
      mode => '0644', owner => root, group => root;
  }

  exec { 'import_ubuntu_cloud_key':
    command => '/bin/su - debrepo -c "/usr/bin/gpg --import /srv/debrepo/ubuntu-cloud-key.asc"',
    creates => '/home/debrepo/.gnupg/pubring.gpg',
    require => [ File['/srv/debrepo/ubuntu-cloud-key.asc'],
      Package['gnupg'],
      User['debrepo']
      ];
  }

  user {
    ['debrepo', 'debupload']:
    ensure => present,
    managehome => true;
  }

  group {
    ['debrepo', 'debupload']:
    ensure => present;
  }

  cron { 'update-reprepro-mirror':
    user    => 'debrepo',
    hour    => '8',
    minute  => '17',
    command => '/usr/bin/reprepro -b /srv/debrepo --outdir "+b/pub/uca" --export=changed update',
    require => [ User['debrepo'] ];
  }

  service { 'inoticoming':
    ensure => running,
    enable => true,
    require => [ File['/etc/systemd/system/inoticoming.service'] ];
  }

  apache::vhost { 'debrepo.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/debrepo/pub',
    options  => 'Indexes MultiViews',
    require  => File['/srv/debrepo/pub'],
  }

}
