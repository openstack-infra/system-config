# Class to configure cacti on a node.
# Takes a list of sysadmin email addresses as a parameter. Exim will be
# configured to email cron spam and other alerts to this list of admins.
class openstack_project::cacti (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  include apache

  package { 'cacti':
    ensure => present,
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
    # community is currently not running puppet.
    #'community.openstack.org',
    'ci-puppetmaster.openstack.org',
    'eavesdrop.openstack.org',
    'elasticsearch.openstack.org',
    'elasticsearch2.openstack.org',
    'elasticsearch3.openstack.org',
    'elasticsearch4.openstack.org',
    'elasticsearch5.openstack.org',
    'elasticsearch6.openstack.org',
    'etherpad.openstack.org',
    'etherpad-dev.openstack.org',
    'git.openstack.org',
    'git01.openstack.org',
    'git02.openstack.org',
    'git03.openstack.org',
    'git04.openstack.org',
    'graphite.openstack.org',
    'jenkins.openstack.org',
    'jenkins01.openstack.org',
    'jenkins02.openstack.org',
    'jenkins03.openstack.org',
    'jenkins04.openstack.org',
    'jenkins-dev.openstack.org',
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
    'nodepool.openstack.org',
    'paste.openstack.org',
    'pbx.openstack.org',
    'planet.openstack.org',
    'puppet-dashboard.openstack.org',
    'pypi.openstack.org',
    'review.openstack.org',
    'review-dev.openstack.org',
    'static.openstack.org',
    'wiki.openstack.org',
    'zuul.openstack.org',
  ]

  openstack_project::cacti_device { $cacti_hosts: }
}
