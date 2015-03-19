# == Class: openstack_project::single_use_slave
#
# This class configures single use Jenkins slaves with a few
# toggleable options. Most importantly sudo rights for the Jenkins
# user are by default off but can be enabled. Also, automatic_upgrades
# are off by default as the assumption is the backing image for
# this single use slaves will be refreshed with new packages
# periodically.
class openstack_project::single_use_slave (
  $certname = $::fqdn,
  $install_users = true,
  $install_resolv_conf = true,
  $sudo = false,
  $thin = true,
  $automatic_upgrades = false,
  $all_mysql_privs = false,
  $enable_unbound = true,
  $ssh_key = $openstack_project::jenkins_ssh_key,
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
) inherits openstack_project {
  class { 'openstack_project::template':
    certname            => $certname,
    automatic_upgrades  => $automatic_upgrades,
    install_users       => $install_users,
    install_resolv_conf => $install_resolv_conf,
    enable_unbound      => $enable_unbound,
    iptables_rules4     =>
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
  }
  class { 'jenkins::slave':
    ssh_key         => $ssh_key,
  }

  class { 'openstack_project::slave_common':
    sudo                => $sudo,
    project_config_repo => $project_config_repo,
  }

  if (! $thin) {
    class { 'openstack_project::thick_slave':
      all_mysql_privs => $all_mysql_privs,
    }
  }

  package { 'cloud-init':
    ensure => 'absent',
  }

  case $::operatingsystem {
    'Fedora': {
      $ssh_user = 'fedora'
      $ssh_dir = '/home/fedora/.ssh'
    }
    'Ubuntu': {
      $ssh_user = 'ubuntu'
      $ssh_dir = '/home/ubuntu/.ssh'
    }
    'CentOS': {
      $ssh_user = 'root'
      $ssh_dir = '/root/.ssh'
     }
  }

  if ! defined(File[$ssh_dir]) {
    file { $ssh_dir:
      ensure => directory,
      mode   => '0700',
    }
  }

  ssh_authorized_key { 'nodepool-static-2015-03-19':
    ensure  => present,
    user    => $ssh_user,
    type    => 'ssh-rsa',
    key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6WutNHfM+YdnjeNFeaIpvxqt+9aDn95Ykpmc+fASSjlDZJtOrueH3ch/v08wkE4WQKg03i+t8VonqEwMGmApYA3VzFsURUQbxzlSz5kHlBQSqgz5JTwUmnt1RH5sePL5pkuJ6JgqJ8PxJod6fiD7YDjaKJW/wBzXGnGg2EkgqrkBQXYL4hyaPuSwsQF0Gdwg3QFqXl+R/GrM6FscUkkJzbjqGKI2GhLT8mf2BIMEAiMFhF5Wl4FFrbvhTfPfW+9VdcsiMxCXaxp00n1x1+Y7OqR5AZ/id0Lkz9ZoFVGS901OB/L4xXrvUtI2y+kIYeF6hxfmAl/zhY0eWzwo9lDPz',
    require => File[$ssh_dir],
  }

}
