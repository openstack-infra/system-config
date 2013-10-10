# == define: openstack_project::base_install_package
#
define openstack_project::base_install_package(
  $package_name = $title,
)
{
  if ! defined(Package[$package_name])
  {
    package { $package_name:
      ensure => present
    }
  }
}
