class openstack_project::gerrit (
      $ssl_cert_file='',
      $ssl_key_file='',
      $ssl_chain_file='',
      $email='',
      $database_poollimit='',
      $container_heaplimit='',
      $core_packedgitopenfiles='',
      $core_packedgitlimit='',
      $core_packedgitwindowsize='',
      $sshd_threads='',
      $httpd_acceptorthreads='',
      $httpd_minthreads='',
      $httpd_maxthreads='',
      $httpd_maxwait='',
      $github_projects = [],
      $upstream_projects = [],
      $war,
      $script_user,
      $script_key_file,
      $github_user,
      $github_token,
      $mysql_password,
      $email_private_key
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }

  class { 'gerrit':
    # opinions
    virtual_hostname => $fqdn,
    canonicalweburl => "https://$fqdn/",
    logo => 'openstack.png',
    script_site => 'openstack',
    enable_melody => 'true',
    melody_session => 'true',
    # passthrough
    ssl_cert_file => $ssl_cert_file,
    ssl_key_file => $ssl_key_file,
    ssl_chain_file => $ssl_chain_file,
    email => $email,
    database_poollimit => $database_poollimit,
    container_heaplimit => $container_heaplimit,
    core_packedgitopenfiles => $core_packedgitopenfiles,
    core_packedgitlimit => $core_packedgitlimit,
    core_packedgitwindowsize => $core_packedgitwindowsize,
    sshd_threads => $sshd_threads,
    httpd_acceptorthreads => $httpd_acceptorthreads,
    httpd_minthreads => $httpd_minthreads,
    httpd_maxthreads => $httpd_maxthreads,
    httpd_maxwait => $httpd_maxwait,
    github_projects => $github_projects,
    upstream_projects => $upstream_projects,
    war => $war,
    script_user => $script_user,
    script_key_file => $script_key_file,
    github_user => $github_user,
    github_token => $github_token,
    mysql_password => $mysql_password,
    email_private_key => $email_private_key
  }
}
