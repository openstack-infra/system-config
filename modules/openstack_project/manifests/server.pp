# == Class: openstack_project::server
#
# A server that we expect to run for some time
class openstack_project::server (
  $pin_puppet                = '3.',
  $ca_server                 = undef,
  $afs                       = false,
  $afs_cache_size            = 500000,
  $pypi_index_url            = 'https://pypi.python.org/simple',
) {

  # Include ::apt while we work on the puppet->ansible transition
  if ($::osfamily == 'Debian') {
    include ::apt
  }

  ###########################################################
  # Process if ( $high_level_directive ) blocks

  if $afs {
    class { 'openafs::client':
      cell         => 'openstack.org',
      realm        => 'OPENSTACK.ORG',
      admin_server => 'kdc.openstack.org',
      cache_size   => $afs_cache_size,
      kdcs         => [
        'kdc01.openstack.org',
        'kdc03.openstack.org',
        'kdc04.openstack.org',
      ],
    }
  }

}
