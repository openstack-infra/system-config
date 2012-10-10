# A wrapper class around the main gerrit class that sets gerrit
# up for launchpad single sign on, bug/blueprint links and user
# import and sync
# TODO: launchpadlib creds for user sync script

class openstack_project::gerrit (
  $vhost_name=$fqdn,
  $canonicalweburl="https://$fqdn/",
  $serveradmin='webmaster@openstack.org',
  $ssh_host_key='/home/gerrit2/review_site/etc/ssh_host_rsa_key',
  $ssl_cert_file='',
  $ssl_key_file='',
  $ssl_chain_file='',
  $ssl_cert_file_contents='',
  $ssl_key_file_contents='',
  $ssl_chain_file_contents='',
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
  $contactstore=false,
  $contactstore_appsec='',
  $contactstore_pubkey='',
  $contactstore_url='',
  $script_user='update',
  $script_key_file='/home/gerrit2/.ssh/id_rsa',
  $script_logging_conf='/home/gerrit2/.sync_logging.conf',
  $projects_file='UNDEF',
  $github_username,
  $github_oauth_token,
  $mysql_password,
  $mysql_root_password,
  $trivial_rebase_role_id,
  $email_private_key,
  $replicate_github=true,
  $testmode=false,
  $sysadmins=[]
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443, 29418],
    sysadmins => $sysadmins
  }

  class { '::gerrit':
    vhost_name               => $vhost_name,
    canonicalweburl          => $canonicalweburl,
    # opinions
    enable_melody            => 'true',
    melody_session           => 'true',
    # passthrough
    ssl_cert_file            => $ssl_cert_file,
    ssl_key_file             => $ssl_key_file,
    ssl_chain_file           => $ssl_chain_file,
    ssl_cert_file_contents   => $ssl_cert_file_contents,
    ssl_key_file_contents    => $ssl_key_file_contents,
    ssl_chain_file_contents  => $ssl_chain_file_contents,
    email                    => $email,
    openidssourl             => "https://login.launchpad.net/+openid",
    database_poollimit       => $database_poollimit,
    container_heaplimit      => $container_heaplimit,
    core_packedgitopenfiles  => $core_packedgitopenfiles,
    core_packedgitlimit      => $core_packedgitlimit,
    core_packedgitwindowsize => $core_packedgitwindowsize,
    sshd_threads             => $sshd_threads,
    httpd_acceptorthreads    => $httpd_acceptorthreads,
    httpd_minthreads         => $httpd_minthreads,
    httpd_maxthreads         => $httpd_maxthreads,
    httpd_maxwait            => $httpd_maxwait,
    commentlinks             => [{ name  => 'changeid',
                                   match => '(I[0-9a-f]{8,40})',
                                   link => '#q,$1,n,z'
                                 },
                                 { name  => 'launchpad',
                                   match => '([Bb]ug|[Ll][Pp])[\\s#:]*(\\d+)',
                                   link  => 'https://code.launchpad.net/bugs/$2'
                                 },
                                 { name  => 'blueprint',
                                   match => '([Bb]lue[Pp]rint|[Bb][Pp])[\\s#:]*([A-Za-z0-9\\-]+)',
                                   link => 'https://blueprints.launchpad.net/openstack/?searchtext=$2'
                                 },
                                ],
    war                      => $war,
    contactstore             => $contactstore,
    contactstore_appsec      => $contactstore_appsec,
    contactstore_pubkey      => $contactstore_pubkey,
    contactstore_url         => $contactstore_url,
    mysql_password           => $mysql_password,
    mysql_root_password      => $mysql_root_password,
    email_private_key        => $email_private_key,
    projects_file            => $projects_file,
    replicate_github         => $replicate_github,
    testmode                 => $testmode,
    require                  => Class[openstack_project::server],
  }
  if ($testmode == false) {
    class { 'gerrit::cron':
      script_user => $script_user,
      script_key_file => $script_key_file,
    }
    class { 'github':
      username => $github_username,
      oauth_token => $github_oauth_token,
      require => Class['::gerrit']
    }
  }

  file { '/home/gerrit2/review_site/static/echosign-cla.html':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/echosign-cla.html',
    replace => 'true',
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/cla.html':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/cla.html',
    replace => 'true',
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/title.png':
    ensure => 'present',
    source => "puppet:///modules/openstack_project/openstack.png",
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/openstack-page-bkg.jpg':
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/openstack-page-bkg.jpg',
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSite.css':
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/GerritSite.css',
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSiteHeader.html':
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/GerritSiteHeader.html',
    require => Class['::gerrit'],
  }

  cron { "gerritsyncusers":
    ensure => absent,
  }

  class { "launchpad_sync":
    user => "gerrit2",
    script_user => $script_user,
    script_key_file => $script_key_file,
    script_logging_conf => $script_logging_conf,
    site => "openstack",
    root_team => "openstack",
  }

  file { '/home/gerrit2/review_site/hooks/change-merged':
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => 'present',
    source => 'puppet:///modules/openstack_project/gerrit/change-merged',
    replace => 'true',
    require => Class['::gerrit']
  }

  file { '/home/gerrit2/review_site/hooks/patchset-created':
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => 'present',
    content => template('openstack_project/gerrit_patchset-created.erb'),
    replace => 'true',
    require => Class['::gerrit']
  }

  file { '/usr/local/gerrit/scripts/trivial_rebase.py':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source =>
      'puppet:///modules/openstack_project/gerrit/scripts/trivial_rebase.py',
    replace => 'true',
    require => Class['::gerrit']
  }
}
