# == Class: openstack_project::infracloud::base
#
# A template host with no running services
#
class openstack_project::infracloud::base (
) {
  class { '::unbound':
    install_resolv_conf => true,
  }
}
