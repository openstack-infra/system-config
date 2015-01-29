# Class to configure cacti on a node.
class openstack_project::cacti (
  $sysadmins = []
) {

  if $::osfamily != 'Debian' {
    fail("${::osfamily} is not supported.")
  }

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  include apache

  a2mod { 'rewrite':
    ensure => present,
  }

  package { 'cacti':
    ensure => present,
  }

  file { '/etc/apache2/conf.d/cacti.conf':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/cacti/apache.conf',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['cacti'],
  }

  file { '/usr/local/share/cacti/resource/snmp_queries':
    ensure => directory,
    owner  => 'root',
  }

  file { '/usr/local/share/cacti/resource/snmp_queries/net-snmp_devio.xml':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/cacti/net-snmp_devio.xml',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/usr/local/share/cacti/resource/snmp_queries'],
  }

  file { '/var/lib/cacti/linux_host.xml':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/cacti/linux_host.xml',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File[
        '/usr/local/share/cacti/resource/snmp_queries/net-snmp_devio.xml'
      ],
  }

  file { '/usr/local/bin/create_graphs.sh':
    ensure => present,
    source => 'puppet:///modules/openstack_project/cacti/create_graphs.sh',
    mode   => '0744',
    owner  => 'root',
    group  => 'root',
  }

  exec { 'cacti_import_xml':
    command => '/usr/bin/php -q /usr/share/cacti/cli/import_template.php --filename=/var/lib/cacti/linux_host.xml --with-template-rras',
    cwd     => '/usr/share/cacti/cli',
    require => File['/var/lib/cacti/linux_host.xml'],
  }

  $cacti_hosts = [
    'afs01.dfw.openstack.org',
    'afs01.ord.openstack.org',
    'afsdb01.openstack.org',
    'afsdb02.openstack.org',
    'eavesdrop.openstack.org',
    'elasticsearch01.openstack.org',
    'elasticsearch02.openstack.org',
    'elasticsearch03.openstack.org',
    'elasticsearch04.openstack.org',
    'elasticsearch05.openstack.org',
    'elasticsearch06.openstack.org',
    'elasticsearch07.openstack.org',
    'etherpad.openstack.org',
    'etherpad-dev.openstack.org',
    'git-fe01.openstack.org',
    'git-fe02.openstack.org',
    'git01.openstack.org',
    'git02.openstack.org',
    'git03.openstack.org',
    'git04.openstack.org',
    'git05.openstack.org',
    'graphite.openstack.org',
    'groups.openstack.org',
    'groups-dev.openstack.org',
    'jenkins.openstack.org',
    'jenkins01.openstack.org',
    'jenkins02.openstack.org',
    'jenkins03.openstack.org',
    'jenkins04.openstack.org',
    'jenkins05.openstack.org',
    'jenkins06.openstack.org',
    'jenkins07.openstack.org',
    'jenkins-dev.openstack.org',
    'kdc01.openstack.org',
    'kdc02.openstack.org',
    'lists.openstack.org',
    'logstash.openstack.org',
    'logstash-worker01.openstack.org',
    'logstash-worker02.openstack.org',
    'logstash-worker03.openstack.org',
    'logstash-worker04.openstack.org',
    'logstash-worker05.openstack.org',
    'logstash-worker06.openstack.org',
    'logstash-worker07.openstack.org',
    'logstash-worker08.openstack.org',
    'logstash-worker09.openstack.org',
    'logstash-worker10.openstack.org',
    'logstash-worker11.openstack.org',
    'logstash-worker12.openstack.org',
    'logstash-worker13.openstack.org',
    'logstash-worker14.openstack.org',
    'logstash-worker15.openstack.org',
    'logstash-worker16.openstack.org',
    'logstash-worker17.openstack.org',
    'logstash-worker18.openstack.org',
    'logstash-worker19.openstack.org',
    'logstash-worker20.openstack.org',
    'nodepool.openstack.org',
    'openstackid.org',
    'paste.openstack.org',
    'pbx.openstack.org',
    'planet.openstack.org',
    'puppetdb.openstack.org',
    'puppetmaster.openstack.org',
    'pypi.openstack.org',
    'pypi.dfw.openstack.org',
    'pypi.iad.openstack.org',
    'pypi.ord.openstack.org',
    'pypi.region-b.geo-1.openstack.org',
    'review.openstack.org',
    'review-dev.openstack.org',
    'static.openstack.org',
    'subunit-worker01.openstack.org',
    'wiki.openstack.org',
    'zm01.openstack.org',
    'zm02.openstack.org',
    'zm03.openstack.org',
    'zm04.openstack.org',
    'zm05.openstack.org',
    'zm06.openstack.org',
    'zm07.openstack.org',
    'zm08.openstack.org',
    'zuul.openstack.org',
  ]

  openstack_project::cacti_device { $cacti_hosts: }
}
