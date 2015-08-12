# == Class: openstack_project::static
#
class openstack_project::static (
  $swift_authurl = '',
  $swift_user = '',
  $swift_key = '',
  $swift_tenant_name = '',
  $swift_region_name = '',
  $swift_default_container = '',
  $project_config_repo = '',
  $security_ssl_cert_file_contents = '',
  $security_ssl_key_file_contents = '',
  $security_ssl_chain_file_contents = '',
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
) {
  class { 'project_config':
    url  => $project_config_repo,
  }

  include openstack_project
  class { 'jenkins::jenkinsuser':
    ssh_key     => $openstack_project::jenkins_ssh_key,
    gitfullname => $jenkins_gitfullname,
    gitemail    => $jenkins_gitemail,
  }

  include ::apache
  include ::apache::mod::wsgi

  httpd_mod { 'rewrite':
    ensure => present,
  }
  httpd_mod { 'proxy':
    ensure => present,
  }
  httpd_mod { 'proxy_http':
    ensure => present,
  }

  if ! defined(File['/srv/static']) {
    file { '/srv/static':
      ensure => directory,
    }
  }

  ###########################################################
  # Tarballs

  ::httpd::vhost { 'tarballs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/tarballs',
    require  => File['/srv/static/tarballs'],
  }

  file { '/srv/static/tarballs':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # legacy ci.openstack.org site redirect

  ::httpd::vhost { 'ci.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/ci.vhost.erb',
  }

  ###########################################################
  # Logs
  class { 'openstackci::logserver':
    jenkins_ssh_key         => $openstack_project::jenkins_ssh_key,
    domain                  => 'openstack.org',
    swift_authurl           => $swift_authurl,
    swift_user              => $swift_user,
    swift_key               => $swift_key,
    swift_tenant_name       => $swift_tenant_name,
    swift_region_name       => $swift_region_name,
    swift_default_container => $swift_default_container,
  }

  ###########################################################
  # Docs-draft

  ::httpd::vhost { 'docs-draft.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/docs-draft',
    require  => File['/srv/static/docs-draft'],
  }

  file { '/srv/static/docs-draft':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/srv/static/docs-draft/robots.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/disallow_robots.txt',
    require => File['/srv/static/docs-draft'],
  }

  ###########################################################
  # Security

  ::httpd::vhost { 'security.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/security',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/security.vhost.erb',
    vhost_name => 'security.openstack.org',
    require    => File['/srv/static/security'],
  }

  file { '/srv/static/security':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

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

  file { '/etc/ssl/certs/security.openstack.org.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $security_ssl_cert_file_contents,
    require => File['/etc/ssl/certs'],
    before  => Httpd::Vhost['security.openstack.org'],
  }

  file { '/etc/ssl/private/security.openstack.org.key':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $security_ssl_key_file_contents,
    require => File['/etc/ssl/private'],
    before  => Httpd::Vhost['security.openstack.org'],
  }

  file { '/etc/ssl/certs/security.openstack.org_intermediate.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $security_ssl_chain_file_contents,
    require => File['/etc/ssl/certs'],
    before  => Httpd::Vhost['security.openstack.org'],
  }

  ###########################################################
  # Governance

  ::httpd::vhost { 'governance.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/governance',
    require  => File['/srv/static/governance'],
  }

  file { '/srv/static/governance':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # Specs

  ::httpd::vhost { 'specs.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/srv/static/specs',
    require  => File['/srv/static/specs'],
  }

  file { '/srv/static/specs':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # legacy summit.openstack.org site redirect

  ::httpd::vhost { 'summit.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/summit.vhost.erb',
  }

  ###########################################################
  # legacy devstack.org site redirect

  ::httpd::vhost { 'devstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    serveraliases => ['*.devstack.org'],
    template      => 'openstack_project/devstack.vhost.erb',
  }

  ###########################################################
  # Trystack

  ::httpd::vhost { 'trystack.openstack.org':
    port     => 80,
    priority => '50',
    docroot  => '/opt/trystack',
    template => 'openstack_project/trystack.vhost.erb',
    require  => Vcsrepo['/opt/trystack'],
  }

  vcsrepo { '/opt/trystack':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/trystack-site',
  }
}
