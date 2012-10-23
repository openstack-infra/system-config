class openstack_project::cacti (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins => $sysadmins
  }

  include apache

  package { 'cacti':
    ensure => present
  }

  file { "/usr/local/share/cacti/resource/snmp_queries":
    ensure => directory,
    owner  => "root",
  }	

  file { "/usr/local/share/cacti/resource/snmp_queries/net-snmp_devio.xml":
    source  => "puppet:///modules/openstack_project/cacti/net-snmp_devio.xml",
    mode    => 644,
    owner   => "root",
    group   => "root",
    require => File["/usr/local/share/cacti/resource/snmp_queries"],
  }

  file { "/var/lib/cacti/linux_host.xml":
    source  => "puppet:///modules/openstack_project/cacti/linux_host.xml",
    mode    => 644,
    owner   => "root",
    group   => "root",
    require => File["/usr/local/share/cacti/resource/snmp_queries/net-snmp_devio.xml"],
  }

  file { "/usr/local/bin/create_graphs.sh":
    source  => "puppet:///modules/openstack_project/cacti/create_graphs.sh",
    mode    => 744,
    owner   => "root",
    group   => "root",
  }

  exec { "cacti_import_xml":
    command      => "/usr/bin/php -q /usr/share/cacti/cli/import_template.php \
                       --filename=/var/lib/cacti/linux_host.xml \
                       --with-template-rras",
    cwd          => "/usr/share/cacti/cli",
    require      => File["/var/lib/cacti/linux_host.xml"],
  }

  class {'cacti_device': hostname=> "etherpad.openstack.org"}
  class {'cacti_device': hostname=> "jenkins.openstack.org"}
  class {'cacti_device': hostname=> "review.openstack.org"}
}

class cacti_device(
  $hostname
){
  exec { "cacti_create_$hostname":
    command      => "/usr/local/bin/create_graphs.sh $hostname",
    require      => Exec["cacti_import_xml"]
  }
}

