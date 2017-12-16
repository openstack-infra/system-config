define openstack_project::master_zone (
  $source = undef,
) {
  concat::fragment { "dns_zones+10_${name}.dns":
    target  => $::dns::publicviewpath,
    content => template('openstack_project/nameserver/bind.zone.erb'),
    order   => "10-${name}",
  }
  file { "/var/lib/bind/zones/${name}":
    ensure  => directory,
    owner   => 'bind',
    group   => 'bind',
    mode    => 'u+rwX,g+rX,o+rX',
    source  => $source,
    recurse => remote,
    require => File['/var/lib/bind/zones'],
    notify  => Service[$::dns::namedservicename],
  }
  file { "/etc/bind/keys/${name}":
    require => File['/etc/bind/keys'],
    ensure  => directory,
  }
}

define openstack_project::dnssec_key (
  $public = undef,
  $private = undef,
  $zone = undef,
) {
  file { "/etc/bind/keys/${zone}/K${zone}.+008+${name}.key":
    ensure  => present,
    content => $public,
    require => File["/etc/bind/keys/${zone}"],
  }
  file { "/etc/bind/keys/${zone}/K${zone}.+008+${name}.private":
    ensure  => present,
    content => $private,
    require => File["/etc/bind/keys/${zone}"],
  }
}

define openstack_project::bind_key (
  $key = undef,
) {
  file { "/etc/bind/${name}.key":
    require => Package[$::dns::dns_server_package],
    owner   => 'root',
    group   => 'bind',
    mode    => '0440',
    content => template('openstack_project/nameserver/bind.key.erb'),
  }
}

class openstack_project::master_nameserver (
  $tsig_key = undef,
  $notifies = undef,
) {

  $also_notify = join($notifies, ';')

  class { '::haveged': }

  class { '::dns':
    dns_notify         => yes,
    listen_on_v6       => "${::ipaddress6}",
    additional_directives => [
      'include "/etc/bind/tsig.key";',
    ],
    additional_options => {
      'listen-on' => "{ ${::ipaddress}; }",
      # Notify requests can also be TSIG signed, but the current version
      # of the NSD puppet module doesn't let us configure that easily.
      'also-notify' => "{ ${also_notify}; }",
      # Bind doesn't make it easy (or possible?) to restrict transfers by
      # ip address and TSIG, so we only use the TSIG key here.
      'allow-transfer' => "{ key tsig; }",
    }
  }

  file { '/etc/bind/keys':
    require => Package[$::dns::dns_server_package],
    ensure  => directory,
  }
  file { '/var/lib/bind/zones':
    require => Package[$::dns::dns_server_package],
    ensure  => directory,
  }

  openstack_project::bind_key { 'tsig':
    key => $tsig_key,
  }

  create_resources(openstack_project::dnssec_key, hiera_hash('dnssec_keys'))

  # Per zone configuration
  vcsrepo { '/opt/zone-zuul-ci.org':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/zone-zuul-ci.org',
  }
  openstack_project::master_zone { 'zuul-ci.org':
    source  => 'file:///opt/zone-zuul-ci.org/zones/zuul-ci.org',
    require => Vcsrepo['/opt/zone-zuul-ci.org'],
  }

}
