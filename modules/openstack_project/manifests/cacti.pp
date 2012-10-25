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
    cwd     => 'usr/share/cacti/cli',
    require => File['/var/lib/cacti/linux_host.xml'],
  }

  openstack_project::cacti_device { 'cacti_community':
    hostname=> 'community.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_eavesdrop':
    hostname=> 'eavesdrop.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_etherpad':
    hostname=> 'etherpad.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_jenkins':
    hostname=> 'jenkins.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_jenkins-dev':
    hostname=> 'jenkins-dev.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_lists':
    hostname=> 'lists.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_paste':
    hostname=> 'paste.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_planet':
    hostname=> 'planet.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_pypi':
    hostname=> 'pypi.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_review':
    hostname=> 'review.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_review-dev':
    hostname=> 'review-dev.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_static':
    hostname=> 'static.openstack.org',
  }
  openstack_project::cacti_device { 'cacti_wiki':
    hostname=> 'wiki.openstack.org',
  }
}
