# Class to configure cgit on a CentOS node.
# Takes a list of sysadmin email addresses as a parameter. Exim will be
# configured to email cron spam and other alerts to this list of admins.
class openstack_project::git (
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 9418],
    sysadmins                 => $sysadmins,
  }

include cgit

  class { 'selinux':
    mode => 'enforcing'
  }
