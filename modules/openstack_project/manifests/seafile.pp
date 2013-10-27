# == Class: openstack_project::seafile
# seafile_db_host = $seafile_db_host
# seafile_db_user = $seafile_db_user
# seafile_db_password = $seafile_db_password
# sysadmins = $sysadmins
# seafile_user_name = $seafile_user_name
# seafile_id = $seafile_id
# seafile_instance_name = $seafile_instance_name
# seafile_url = $seafile_url
# seafile_network_port = $seafile_network_port
# seafile_client_port = $seafile_client_port
# seafile_db_engine = $seafile_db_engine
# seafile_ccnet_db = $seafile_ccnet_db
# seafile_db_port = $seafile_db_port  # default is 3306
# seafile_seafile_db = $seafile_seafile_db
# seafile_seafile_db_port = $seafile_seafile_db_port
# seafile_http_port = $seafile_http_port
# seafile_secrec_key = $seafile_secrec_key
# seafile_seahub_db = $seafile_seahub_db
# seafile_rsa_key_contents = $seafile_rsa_key_contents

class openstack_project::seafile (
  $sysadmins = []
) {
  class {'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 8000, 8082],
    sysadmins                 => $sysadmins,
  }
  include seafile

  seafile::site {'seafile':

  }
}
