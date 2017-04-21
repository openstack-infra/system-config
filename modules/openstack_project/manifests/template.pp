# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::template (
  $pin_puppet                = '3.',
  $install_resolv_conf       = true,
  $certname                  = $::fqdn,
  $ca_server                 = undef,
  $afs                       = false,
  $puppetmaster_server       = 'puppetmaster.openstack.org',
  $sysadmins                 = [],
  $permit_root_login         = 'no',
) {

  ###########################################################
  # Classes for all hosts


  if ($::osfamily == 'Debian') {
    # NOTE(pabelanger): Puppetlabs only support Ubuntu Trusty and below,
    # anything greater will use the OS version of puppet.
    if ($::operatingsystemrelease < '15.04') {
      include ::apt
      apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        repos    => 'main',
        key      => {
          'id'     =>'47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
          'server' => 'pgp.mit.edu',
        },
      }
    }
  }

  if ($::operatingsystem == 'CentOS') {
    file { '/etc/yum.repos.d/puppetlabs.repo':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/centos7-puppetlabs.repo',
      replace => true,
    }
  }

  ###########################################################

}
