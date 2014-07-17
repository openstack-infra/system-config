# == Class: openstack_project::stunnel
#
class openstack_project::stunnel (
    $certificate = '',
    $private_key = '',
    $ca_file = '',
    $crl_file = '',
    $user = 'stunnel4',
    $group = 'stunnel4',
    $client = true,
    $accept = '',
    $connect = '',
    $service = 'geard'
) {
  include stunnel

  stunnel::tun { $service:
    chroot      => "/var/lib/stunnel4/${service}",
    certificate => $certificate,
    private_key => $private_key,
    ca_file     => $ca_file,
    crl_file    => $crl_file,
    user        => $user,
    group       => $group,
    client      => $client,
    accept      => $accept,
    connect     => $connect,
    require     => File['/var/lib/stunnel4'],
  }

  file { '/var/lib/stunnel4':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }
}
