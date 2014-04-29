# Class to configure cacti on a node.
# Takes a list of sysadmin email addresses as a parameter. Exim will be
# configured to email cron spam and other alerts to this list of admins.
class opencontrail_project::cacti (
  $sysadmins = []
) {
  class { 'opencontrail_project::server':
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

  file { '/etc/apache2/conf-available/cacti.conf':
    ensure  => present,
    source  => 'puppet:///modules/opencontrail_project/cacti/apache.conf',
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
    source  => 'puppet:///modules/opencontrail_project/cacti/net-snmp_devio.xml',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/usr/local/share/cacti/resource/snmp_queries'],
  }

  file { '/var/lib/cacti/linux_host.xml':
    ensure  => present,
    source  => 'puppet:///modules/opencontrail_project/cacti/linux_host.xml',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File[
        '/usr/local/share/cacti/resource/snmp_queries/net-snmp_devio.xml'
      ],
  }

  file { '/usr/local/bin/create_graphs.sh':
    ensure => present,
    source => 'puppet:///modules/opencontrail_project/cacti/create_graphs.sh',
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
    # community is currently not running puppet.
    #'community.opencontrail.org',
    'ci-puppetmaster.opencontrail.org',
    'eavesdrop.opencontrail.org',
    'elasticsearch01.opencontrail.org',
    'elasticsearch02.opencontrail.org',
    'elasticsearch03.opencontrail.org',
    'elasticsearch04.opencontrail.org',
    'elasticsearch05.opencontrail.org',
    'elasticsearch06.opencontrail.org',
    'etherpad.opencontrail.org',
    'etherpad-dev.opencontrail.org',
    'git.opencontrail.org',
    'git01.opencontrail.org',
    'git02.opencontrail.org',
    'git03.opencontrail.org',
    'git04.opencontrail.org',
    'git05.opencontrail.org',
    'graphite.opencontrail.org',
    'jenkins.opencontrail.org',
    'jenkins01.opencontrail.org',
    'jenkins02.opencontrail.org',
    'jenkins03.opencontrail.org',
    'jenkins04.opencontrail.org',
    'jenkins05.opencontrail.org',
    'jenkins06.opencontrail.org',
    'jenkins07.opencontrail.org',
    'jenkins-dev.opencontrail.org',
    'lists.opencontrail.org',
    'logstash.opencontrail.org',
    'logstash-worker01.opencontrail.org',
    'logstash-worker02.opencontrail.org',
    'logstash-worker03.opencontrail.org',
    'logstash-worker04.opencontrail.org',
    'logstash-worker05.opencontrail.org',
    'logstash-worker06.opencontrail.org',
    'logstash-worker07.opencontrail.org',
    'logstash-worker08.opencontrail.org',
    'logstash-worker09.opencontrail.org',
    'logstash-worker10.opencontrail.org',
    'logstash-worker11.opencontrail.org',
    'logstash-worker12.opencontrail.org',
    'logstash-worker13.opencontrail.org',
    'logstash-worker14.opencontrail.org',
    'logstash-worker15.opencontrail.org',
    'logstash-worker16.opencontrail.org',
    'nodepool.opencontrail.org',
    'paste.opencontrail.org',
    'pbx.opencontrail.org',
    'planet.opencontrail.org',
    'puppet-dashboard.opencontrail.org',
    'puppetdb.opencontrail.org',
    'pypi.opencontrail.org',
    'review.opencontrail.org',
    'review-dev.opencontrail.org',
    'static.opencontrail.org',
    'wiki.opencontrail.org',
    'zm01.opencontrail.org',
    'zm02.opencontrail.org',
    'zuul.opencontrail.org',
  ]

  opencontrail_project::cacti_device { $cacti_hosts: }
}
