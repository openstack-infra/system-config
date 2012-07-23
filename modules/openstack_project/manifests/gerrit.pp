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
      $war,
      $script_user,
      $script_key_file,
      $github_projects = [],
      $github_user,
      $github_token,
      $mysql_password,
      $email_private_key,
      $testmode=false,
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418]
  }

  class { 'gerrit::launchpad':
    # opinions
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
    war => $war,
    script_user => $script_user,
    script_key_file => $script_key_file,
    mysql_password => $mysql_password,
    email_private_key => $email_private_key,
    testmode => $testmode,
  }
  if ($testmode == false) {
    class { 'gerrit::cron':
      script_user => $script_user,
      script_key_file => $script_key_file,
    }
    class { 'github':
      github_projects => $github_projects,
      github_user => $github_username,
      github_token => $github_oauth_token,
    }
  }

  file { '/home/gerrit2/review_site/static/echosign-cla.html':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/echosign-cla.html',
    replace => 'true',
    require => Class['gerrit::launchpad'],
  }

  file { '/home/gerrit2/review_site/static/title.png':
    ensure => 'present',
    source => "puppet:///modules/openstack_project/openstack.png",
    require => Class['gerrit::launchpad'],
  }

  file { '/home/gerrit2/review_site/static/openstack-page-bkg.jpg':
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/openstack-page-bkg.jpg',
    require => Class['gerrit::launchpad'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSite.css':
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/GerritSite.css',
    require => Class['gerrit::launchpad'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSiteHeader.html':
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/GerritSiteHeader.html',
    require => Class['gerrit::launchpad'],
  }

}
