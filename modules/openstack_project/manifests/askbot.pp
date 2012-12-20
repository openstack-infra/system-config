# == Class: openstack_project::askbot
#
class openstack_project::askbot(
  $mysql_password,
  $mysql_root_password,
  $sysadmins = []
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  class { '::askbot':
    mysql_password      => $mysql_password,
    mysql_root_password => $mysql_root_password,
  }

  askbot::site { 'one':
    mysql_password      => $mysql_password,
    mysql_root_password => $mysql_root_password,
  }

  askbot::mysql { 'one':
    mysql_password      => $mysql_password,
    mysql_root_password => $mysql_root_password,
  }

  askbot::deploy { 'one':
  }

  askbot::site { 'two':
    mysql_password      => $mysql_password,
    mysql_root_password => $mysql_root_password,
  }

  askbot::mysql { 'two':
    mysql_password      => $mysql_password,
    mysql_root_password => $mysql_root_password,
  }

  askbot::deploy { 'two':
    vhost_name => 'ask-secondary.openstack.org',
  }
}
