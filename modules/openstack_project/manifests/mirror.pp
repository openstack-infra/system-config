# == Class: openstack_project::mirror
#
class openstack_project::mirror (
  $vhost_name = $::fqdn,
) {

  # Some hosts are mirror01, but we need the host to respond to
  # "mirror."  Re-evaluate this if we end up doing multiple
  # mirrors/load balancing etc.
  $alias_name = regsubst($vhost_name, 'mirror\d*\.', 'mirror.')
  if $alias_name != $vhost_name {
    $serveraliases = [$alias_name]
  } else {
    $serveraliases = undef
  }

  class { 'openstackci::mirror':
    vhost_name    => $vhost_name,
    serveraliases => $serveraliases,
  }
}
