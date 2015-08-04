class openstack_project::bifrost (
  $baremetal_json_hosts,
  $ironic_db_password,
  $mysql_password,
) {

  include ::ansible

  class { '::mysql::server':
    root_password => $mysql_password,
  }

  class { '::ironic::bifrost':
    ironic_db_password   => $ironic_db_password,
    mysql_password       => $mysql_password,
    baremetal_json_hosts => $baremetal_json_hosts,
  }

  # This is almost certainly the wrong way to do this
  exec { 'bifrost: install':
    command   => '/usr/bin/ansible-playbook -i inventory/localhost install.yaml',
    cwd       => '/opt/stack/bifrost/playbooks',
    creates   => '/etc/ironic',
    subscribe => Class['::ironic::bifrost'],
  }

  #exec { 'bifrost: enroll-dynamic':
  #  command => '',
  #  creates => '',
  #  require => Exec['bifrost: install'],
  #}

  #exec { 'bifrost: deploy-dynamic':
  #  command => '',
  #  creates => '',
  #  require => Exec['bifrost: enroll-dynamic'],
  #}

}
