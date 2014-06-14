# Class to configure graphite on a node.
class openstack_project::graphite (
  $sysadmins = [],
  $graphite_admin_user = '',
  $graphite_admin_email = '',
  $graphite_admin_password ='',
  $statsd_hosts = [],
) {

  # Turn a list of hostnames into a list of iptables rules
  $rules = regsubst ($statsd_hosts, '^(.*)$', '-m udp -p udp -s \1 --dport 8125 -j ACCEPT')

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    iptables_rules6           => $rules,
    iptables_rules4           => $rules,
    sysadmins                 => $sysadmins,
  }

  class { '::graphite':
    graphite_admin_user     => $graphite_admin_user,
    graphite_admin_email    => $graphite_admin_email,
    graphite_admin_password => $graphite_admin_password,
  }
}
