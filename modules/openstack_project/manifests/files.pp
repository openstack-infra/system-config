# == Class: openstack_project::files
#
class openstack_project::files (
  $vhost_name = $::fqdn,
  $developer_cert_file_contents,
  $developer_key_file_contents,
  $developer_chain_file_contents,
  $docs_cert_file_contents,
  $docs_key_file_contents,
  $docs_chain_file_contents,
  $git_airship_cert_file_contents,
  $git_airship_key_file_contents,
  $git_airship_chain_file_contents,
  $git_openstack_cert_file_contents,
  $git_openstack_key_file_contents,
  $git_openstack_chain_file_contents,
  $git_starlingx_cert_file_contents,
  $git_starlingx_key_file_contents,
  $git_starlingx_chain_file_contents,
  $git_zuul_cert_file_contents,
  $git_zuul_key_file_contents,
  $git_zuul_chain_file_contents,
) {

  $afs_root = '/afs/openstack.org/'
  $www_base = '/var/www'

  #####################################################
  # Build Apache Webroot
  file { "${www_base}":
    ensure  => directory,
    owner   => root,
    group   => root,
  }

  file { "${www_base}/robots.txt":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0444',
    source   => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require  => File["${www_base}"],
  }

  #####################################################
  # Git Redirects Webroot
  file { "${www_base}/git-redirect":
    ensure  => directory,
    owner   => root,
    group   => root,
    require => File["${www_base}"],
  }

  file { "${www_base}/git-redirect/.htaccess":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0444',
    source   => 'puppet:///modules/openstack_project/git-redirect.htaccess',
    require  => File["${www_base}/git-redirect"],
  }

  #####################################################
  # Set up directories needed by HTTPS certs/keys
  file { '/etc/ssl/certs':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  #####################################################
  # Build VHost
  include ::httpd

  ::httpd::vhost { $vhost_name:
    port     => 80,
    priority => '50',
    docroot  => "${afs_root}",
    template => 'openstack_project/files.vhost.erb',
    require  => [
      File["${www_base}"],
    ]
  }

  httpd_mod { 'rewrite':
    ensure => present,
    before => Service['httpd'],
  }

  class { '::httpd::logrotate':
    options => [
      'daily',
      'missingok',
      'rotate 7',
      'compress',
      'delaycompress',
      'notifempty',
      'create 640 root adm',
    ],
  }

  # Until Apache 2.4.24 the event MPM has some issues scalability
  # bottlenecks that were seen to drop connections, especially on
  # larger files; see
  #  https://httpd.apache.org/docs/2.4/mod/event.html
  #
  # The main advantage of event MPM is for keep-alive requests which
  # are not really a big issue on this static file server.  Therefore
  # we switch to the threaded worker MPM as a workaround.  This can be
  # reconsidered when the apache version running is sufficient to
  # avoid these problems.

  httpd::mod { 'mpm_event': ensure => 'absent' }
  httpd::mod { 'mpm_worker': ensure => 'present' }

  file { '/etc/apache2/mods-available/mpm_worker.conf':
    ensure => file,
    source => 'puppet:///modules/openstack_project/files/mpm_worker.conf',
    notify => Service['httpd'],
  }

  file {'/usr/local/bin/404s.sh':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/openstack_project/files/404s.sh',
  }
  file {'/var/www/docs-404s':
    ensure => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }
  cron {'generate_docs_404s':
    # This seems to be about half an hour after apache rotates logs.
    hour        => '7',
    minute      => '0',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin',
    command     => '404s.sh /var/log/apache2/docs.openstack.org_access.log /var/www/docs-404s/',
    require     => File['/usr/local/bin/404s.sh'],
  }

  ###########################################################
  # docs.openstack.org

  ::httpd::vhost { 'docs.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => "${afs_root}docs",
    priority   => '50',
    template   => 'openstack_project/docs.vhost.erb',
  }
  file { '/etc/ssl/certs/docs.openstack.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $docs_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/docs.openstack.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $docs_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/docs.openstack.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $docs_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/docs.openstack.org.pem'],
  }


  ###########################################################
  # developer.openstack.org

  ::httpd::vhost { 'developer.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => "${afs_root}developer-docs",
    priority   => '50',
    template   => 'openstack_project/developer.vhost.erb',
  }
  file { '/etc/ssl/certs/developer.openstack.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $developer_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/developer.openstack.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $developer_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/developer.openstack.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $developer_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/developer.openstack.org.pem'],
  }


  ###########################################################
  # git.airshipit.org

  ::httpd::vhost { 'git.airshipit.org':
    port     => 443, # Is required despite not being used.
    docroot  => "${www_base}/git-redirect",
    priority => '50',
    template => 'openstack_project/git-redirect.vhost.erb',
    require  => File["${www_base}/git-redirect"],
  }
  file { '/etc/ssl/certs/git.airshipit.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_airship_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/git.airshipit.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $git_airship_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/git.airshipit.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_airship_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/git.airshipit.org.pem'],
  }


  ###########################################################
  # git.openstack.org

  ::httpd::vhost { 'git.openstack.org':
    port     => 443, # Is required despite not being used.
    docroot  => "${www_base}/git-redirect",
    priority => '50',
    template => 'openstack_project/git-redirect.vhost.erb',
    require  => File["${www_base}/git-redirect"],
  }
  file { '/etc/ssl/certs/git.openstack.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_openstack_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/git.openstack.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $git_openstack_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/git.openstack.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_openstack_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/git.openstack.org.pem'],
  }


  ###########################################################
  # git.starlingx.io

  ::httpd::vhost { 'git.starlingx.io':
    port     => 443, # Is required despite not being used.
    docroot  => "${www_base}/git-redirect",
    priority => '50',
    template => 'openstack_project/git-redirect.vhost.erb',
    require  => File["${www_base}/git-redirect"],
  }
  file { '/etc/ssl/certs/git.starlingx.io.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_starlingx_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/git.starlingx.io.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $git_starlingx_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/git.starlingx.io_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_starlingx_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/git.starlingx.io.pem'],
  }


  ###########################################################
  # git.zuul-ci.org

  ::httpd::vhost { 'git.zuul-ci.org':
    port     => 443, # Is required despite not being used.
    docroot  => "${www_base}/git-redirect",
    priority => '50',
    template => 'openstack_project/git-redirect.vhost.erb',
    require  => File["${www_base}/git-redirect"],
  }
  file { '/etc/ssl/certs/git.zuul-ci.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_zuul_cert_file_contents,
    require => File['/etc/ssl/certs'],
  }
  file { '/etc/ssl/private/git.zuul-ci.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $git_zuul_key_file_contents,
    require => File['/etc/ssl/private'],
  }
  file { '/etc/ssl/certs/git.zuul-ci.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $git_zuul_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => File['/etc/ssl/certs/git.zuul-ci.org.pem'],
  }
}
