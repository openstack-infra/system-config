define openstack_project::master_zone (
) {
  concat::fragment { "dns_zones+10_${name}.dns":
    target  => $::dns::publicviewpath,
    content => template('openstack_project/nameserver/bind.zone.erb'),
    order   => "10-${name}",
  }
  file { "/var/lib/bind/zones/${name}":
    require => File['/var/lib/bind/zones'],
    ensure  => directory,
  }
  file { "/etc/bind/keys/${name}":
    require => File['/etc/bind/keys'],
    ensure  => directory,
  }
}

class openstack_project::master_nameserver (
) {

  class { '::haveged': }
  include ::dns

  file { '/etc/bind/keys':
    require => Class['dns'],
    ensure  => directory,
  }
  file { '/var/lib/bind/zones':
    require => Class['dns'],
    ensure  => directory,
  }
  openstack_project::master_zone { 'zuul-ci.org':
  }
}
