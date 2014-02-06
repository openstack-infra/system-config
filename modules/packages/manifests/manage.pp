# == Class: packages:manage
#
# Handles bulk package management via hiera.
#

class packages::manage (
  $install_packages = hiera_array('packages::install',undef),
  $latest_packages = hiera_array('packages::latest',undef),
  $remove_packages = hiera_array('packages::remove',undef),
  $install_version = hiera_hash('packages::versioned',undef)
) {

  if $install_packages {
    packages::handle { $install_packages:
      ensure => installed,
    }
  }

  if $latest_packages {
    packages::handle { $latest_packages:
      ensure => latest,
    }
  }

  if $remove_packages {
    packages::handle { $remove_packages:
      ensure => absent,
    }
  }

  $install_defaults = {
    ensure => 'installed',
  }

  if $install_version {
      create_resources(package, $install_version, $install_defaults)
  }

}

