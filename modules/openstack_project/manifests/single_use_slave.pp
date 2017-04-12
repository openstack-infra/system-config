# == Class: openstack_project::single_use_slave
#
# This class configures single use Jenkins slaves with a few
# toggleable options. Most importantly sudo rights for the Jenkins
# user are by default off but can be enabled.
class openstack_project::single_use_slave (
  $certname = $::fqdn,
  $install_users = true,
  $install_resolv_conf = true,
  $sudo = false,
  $thin = true,
  $all_mysql_privs = false,
  $ssh_key = $openstack_project::jenkins_ssh_key,
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
) inherits openstack_project {
  class { 'openstack_project::template':
    certname                  => $certname,
    install_users             => $install_users,
    install_resolv_conf       => $install_resolv_conf,
    permit_root_login         => 'yes',
    iptables_rules4           =>
      [
        # Ports 69 and 6385 allow to allow ironic VM nodes to reach tftp and
        # the ironic API from the neutron public net
        '-p udp --dport 69 -s 172.24.4.0/23 -j ACCEPT',
        '-p tcp --dport 6385 -s 172.24.4.0/23 -j ACCEPT',
        # Ports 8000, 8003, 8004 from the devstack neutron public net to allow
        # nova servers to reach heat-api-cfn, heat-api-cloudwatch, heat-api
        '-p tcp --dport 8000 -s 172.24.4.0/23 -j ACCEPT',
        '-p tcp --dport 8003 -s 172.24.4.0/23 -j ACCEPT',
        '-p tcp --dport 8004 -s 172.24.4.0/23 -j ACCEPT',
        '-m limit --limit 2/min -j LOG --log-prefix "iptables dropped: "',
      ],
    iptables_public_tcp_ports => [19885],
  }

  include ::haveged
  include ::pip

  class { '::jenkins::jenkinsuser':
    ssh_key     => $ssh_key,
    gitfullname => $jenkins_gitfullname,
    gitemail    => $jenkins_gitemail,
  }

  class { 'openstack_project::slave_common':
    sudo                => $sudo,
  }

  if (! $thin) {
    notice("The openstack_project::single_use_slave::thin parameter has no effect.")
  }
}
