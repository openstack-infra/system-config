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
    command => '/usr/bin/php -q /usr/share/cacti/cli/import_template.php \
                  --filename=/var/lib/cacti/linux_host.xml \
                  --with-template-rras',
    cwd     => '/usr/share/cacti/cli',
    require => File['/var/lib/cacti/linux_host.xml'],
  }

  $cacti_hosts = [
    'community.openstack.org',
    'eavesdrop.openstack.org',
    'etherpad.openstack.org',
    'jenkins.openstack.org',
    'jenkins-dev.openstack.org',
    'lists.openstack.org',
    'paste.openstack.org',
    'planet.openstack.org',
    'pypi.openstack.org',
    'review.openstack.org',
    'review-dev.openstack.org',
    'static.openstack.org',
    'wiki.openstack.org',
  ]

  openstack_project::cacti_device { $cacti_hosts: }
}
