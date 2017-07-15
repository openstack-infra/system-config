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
  $ssl_cert_file = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file = '',
  $ssl_chain_file_contents = '',
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
  $expires = {
    'service-types.openstack.org' => {
      'application/json' => 'access plus 1 week'
    }
  }
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

  # This will try to index our millions of logs and docs by default
  # and cause all sorts of IO and disk-usage issues.
  package { 'mlocate':
    ensure => absent,
  }

  include ::httpd
  include ::httpd::mod::wsgi

  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['proxy']) {
    httpd::mod { 'proxy':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['proxy_http']) {
    httpd::mod { 'proxy_http':
        ensure => present,
    }
  }

  if ! defined(Httpd::Mod['alias']) {
    httpd::mod { 'alias': ensure => present }
  }

  if ! defined(Httpd::Mod['headers']) {
    httpd::mod { 'headers': ensure => present }
  }

  if ! defined(Httpd::Mod['expires']) {
    httpd::mod { 'expires':
        ensure => present,
    }
  }

  if ! defined(File['/srv/static']) {
    file { '/srv/static':
      ensure => directory,
    }
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

  # To use the standard ssl-certs package snakeoil certificate, leave both
  # $ssl_cert_file and $ssl_cert_file_contents empty. To use an existing
  # certificate, specify its path for $ssl_cert_file and leave
  # $ssl_cert_file_contents empty. To manage the certificate with puppet,
  # provide $ssl_cert_file_contents and optionally specify the path to use for
  # it in $ssl_cert_file.
  if ($ssl_cert_file == '') and ($ssl_cert_file_contents == '') {
    $cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
  } else {
    if $ssl_cert_file == '' {
      $cert_file = "/etc/ssl/certs/${::fqdn}.pem"
    } else {
      $cert_file = $ssl_cert_file
    }
    if $ssl_cert_file_contents != '' {
      file { $cert_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $ssl_cert_file_contents,
        require => File['/etc/ssl/certs'],
      }
    }
  }

  # To use the standard ssl-certs package snakeoil key, leave both
  # $ssl_key_file and $ssl_key_file_contents empty. To use an existing key,
  # specify its path for $ssl_key_file and leave $ssl_key_file_contents empty.
  # To manage the key with puppet, provide $ssl_key_file_contents and
  # optionally specify the path to use for it in $ssl_key_file.
  if ($ssl_key_file == '') and ($ssl_key_file_contents == '') {
    $key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
  } else {
    if $ssl_key_file == '' {
      $key_file = "/etc/ssl/private/${::fqdn}.key"
    } else {
      $key_file = $ssl_key_file
    }
    if $ssl_key_file_contents != '' {
      file { $key_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => $ssl_key_file_contents,
        require => File['/etc/ssl/private'],
      }
    }
  }

  # To avoid using an intermediate certificate chain, leave both
  # $ssl_chain_file and $ssl_chain_file_contents empty. To use an existing
  # chain, specify its path for $ssl_chain_file and leave
  # $ssl_chain_file_contents empty. To manage the chain with puppet, provide
  # $ssl_chain_file_contents and optionally specify the path to use for it in
  # $ssl_chain_file.
  if ($ssl_chain_file == '') and ($ssl_chain_file_contents == '') {
    $chain_file = ''
  } else {
    if $ssl_chain_file == '' {
      $chain_file = "/etc/ssl/certs/${::fqdn}_intermediate.pem"
    } else {
      $chain_file = $ssl_chain_file
    }
    if $ssl_chain_file_contents != '' {
      file { $chain_file:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $ssl_chain_file_contents,
        require => File['/etc/ssl/certs'],
        before  => File[$cert_file],
      }
    }
  }

  ###########################################################
  # Tarballs

  ::httpd::vhost { 'tarballs.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/tarballs',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/static-http-and-https.vhost.erb',
    vhost_name => 'tarballs.openstack.org',
    require    => [
      File['/srv/static/tarballs'],
      File[$cert_file],
      File[$key_file],
    ],
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
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/docs-draft',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/static-http-and-https.vhost.erb',
    vhost_name => 'docs-draft.openstack.org',
    require    => [
      File['/srv/static/docs-draft'],
      File[$cert_file],
      File[$key_file],
    ],
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
    template   => 'openstack_project/static-https-redirect.vhost.erb',
    vhost_name => 'security.openstack.org',
    require    => [
      File['/srv/static/security'],
      File[$cert_file],
      File[$key_file],
    ],
  }

  file { '/srv/static/security':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # Governance (TC and UC) & Election

  # Extra aliases and directories needed for vhost template:
  $governance_aliases = {
    '/election/' => '/srv/static/election/',
    '/tc/'       => '/srv/static/tc/',
    '/uc/'       => '/srv/static/uc/',
  }
  # Extra redirects needed for vhost template:
  $governance_redirects = {
    '/badges/'      => '/tc/badges/',
    '/goals/'       => '/tc/goals/',
    '/reference/'   => '/tc/reference/',
    '/resolutions/' => '/tc/resolutions/',
  }
  # One of these must also be the docroot
  $governance_directories = [
    '/srv/static/election',
    '/srv/static/governance',
    '/srv/static/tc',
    '/srv/static/uc',
  ]

  ::httpd::vhost { 'governance.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/governance',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/static-governance.vhost.erb',
    vhost_name => 'governance.openstack.org',
    require    => [
      File[$governance_directories],
      File[$cert_file],
      File[$key_file],
    ],
  }

  file { $governance_directories:
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # Specs

  ::httpd::vhost { 'specs.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/specs',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/static-http-and-https.vhost.erb',
    vhost_name => 'specs.openstack.org',
    require    => [
      File['/srv/static/specs'],
      File[$cert_file],
      File[$key_file],
    ],
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
  # legacy site redirects

  ::httpd::vhost { 'devstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    serveraliases => ['*.devstack.org'],
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'cinder.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'glance.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'horizon.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'keystone.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'nova.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'qa.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ::httpd::vhost { 'swift.openstack.org':
    port          => 80,
    priority      => '50',
    docroot       => 'MEANINGLESS_ARGUMENT',
    template      => 'openstack_project/legacy.vhost.erb',
  }

  ###########################################################
  # Trystack

  ::httpd::vhost { 'trystack.openstack.org':
    port          => 443, # Is required despite not being used.
    docroot       => '/opt/trystack',
    priority      => '50',
    ssl           => true,
    template      => 'openstack_project/static-http-and-https.vhost.erb',
    vhost_name    => 'trystack.openstack.org',
    serveraliases => ['trystack.org', 'www.trystack.org'],
    require       => [
      Vcsrepo['/opt/trystack'],
      File[$cert_file],
      File[$key_file],
    ],
  }

  vcsrepo { '/opt/trystack':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/trystack-site',
  }

  ###########################################################
  # Releases

  ::httpd::vhost { 'releases.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/releases',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/static-https-redirect.vhost.erb',
    vhost_name => 'releases.openstack.org',
    require    => [
      File['/srv/static/releases'],
      File[$cert_file],
      File[$key_file],
    ],
  }

  file { '/srv/static/releases':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ###########################################################
  # service-types.openstack.org

  ::httpd::vhost { 'service-types.openstack.org':
    port       => 443, # Is required despite not being used.
    docroot    => '/srv/static/service-types',
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/static-https-redirect.vhost.erb',
    vhost_name => 'service-types.openstack.org',
    require    => [
      File['/srv/static/service-types'],
      File[$cert_file],
      File[$key_file],
    ],
  }

  file { '/srv/static/service-types':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
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

}
