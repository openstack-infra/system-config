# == Class: openstack_project::tripleo_slave
#
# This class configures single use Jenkins slaves for running TripleO jobs.
# Most behaviour is inherited from single_use_slave.
class openstack_project::tripleo_slave (
  $install_users = $openstack_project::single_use_slave::install_users,
  $sudo = $openstack_project::single_use_slave::sudo,
  $thin = $openstack_project::single_use_slave::thin,
  $python3 = $openstack_project::single_use_slave::python3,
  $include_pypy = $openstack_project::single_use_slave::include_pypy,
  $all_mysql_privs = $openstack_project::single_use_slave::all_mysql_privs,
  $ssh_key = $openstack_project::single_use_slave::ssh_key
) inherits openstack_project::single_use_slave {
  class { 'openstack_project::template':
    install_users       => $install_users,
    iptables_rules4     =>
      [
        # Ports 69 and 6385 allow to allow ironic VM nodes to reach tftp and
        # the ironic API from the neutron public net
        '-p udp --dport 69 -s 172.24.4.0/24 -j ACCEPT',
        '-p tcp --dport 6385 -s 172.24.4.0/24 -j ACCEPT',
        # Ports 8000, 8003, 8004 from the devstack neutron public net to allow
        # nova servers to reach heat-api-cfn, heat-api-cloudwatch, heat-api
        '-p tcp --dport 8000 -s 172.24.4.0/24 -j ACCEPT',
        '-p tcp --dport 8003 -s 172.24.4.0/24 -j ACCEPT',
        '-p tcp --dport 8004 -s 172.24.4.0/24 -j ACCEPT',
        # Ports 27410:27510 allow communication between tripleo jumphost and
        # the CI host running the devtest_seed configuration
        '-p tcp --dport 27410 -s 192.168.1.0/24 -j ACCEPT',
      ],
  }
}
