# == Class: openstack_project::storyboard
#
class openstack_project::storyboard(
  $mysql_host = '',
  $mysql_password = '',
  $mysql_user = '',
  $sysadmins = [],
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = ''
) {
  class { 'openstack_project::server':
    sysadmins                 => $sysadmins,
    iptables_public_tcp_ports => [80, 443],
  }

  class { '::storyboard::cert':
    ssl_cert_content => $ssl_cert_file_contents,
    ssl_key_content  => $ssl_key_file_contents,
    ssl_ca_content   => $ssl_chain_file_contents
  }

  class { '::storyboard::application':
    hostname            => $::fqdn,
    openid_url          => $openid_url,
    mysql_host          => $mysql_host,
    mysql_database      => 'storyboard',
    mysql_user          => $mysql_user,
    mysql_user_password => $mysql_password
  }

  # Load the projects into the database.
  class { '::storyboard::load_projects':
    source => 'puppet:///modules/openstack_project/review.projects.yaml',
  }

  # Load the superusers into the database
  class { '::storyboard::load_superusers':
    source => 'puppet:///modules/openstack_project/storyboard/superusers.yaml',
  }
}
