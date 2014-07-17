# == Class: openstack_project::jenkins
#
class openstack_project::jenkins (
  $vhost_name = $::fqdn,
  $jenkins_jobs_password = '',
  $jenkins_jobs_username = 'gerrig', # This is not a typo, well it isn't anymore.
  $manage_jenkins_jobs = true,
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $jenkins_ssh_private_key = '',
  $zmq_event_receivers = [],
  $sysadmins = []
  $gearman_server ='zuul.openstack.org',
  $gearman_port ='4730',
) {
  include openstack_project

  $iptables_rule = regsubst ($zmq_event_receivers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 8888 -s \1 -j ACCEPT')
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    iptables_rules6           => $iptables_rule,
    iptables_rules4           => $iptables_rule,
    sysadmins                 => $sysadmins,
  }

  # Set defaults here because they evaluate variables which you cannot
  # do in the class parameter list.
  if $ssl_cert_file == '' {
    $prv_ssl_cert_file = "/etc/ssl/certs/${vhost_name}.pem"
  }
  else {
    $prv_ssl_cert_file = $ssl_cert_file
  }
  if $ssl_key_file == '' {
    $prv_ssl_key_file = "/etc/ssl/private/${vhost_name}.key"
  }
  else {
    $prv_ssl_key_file = $ssl_key_file
  }

  class { '::jenkins::master':
    vhost_name              => $vhost_name,
    serveradmin             => 'webmaster@openstack.org',
    logo                    => 'openstack.png',
    ssl_cert_file           => $prv_ssl_cert_file,
    ssl_key_file            => $prv_ssl_key_file,
    ssl_chain_file          => $ssl_chain_file,
    ssl_cert_file_contents  => $ssl_cert_file_contents,
    ssl_key_file_contents   => $ssl_key_file_contents,
    ssl_chain_file_contents => $ssl_chain_file_contents,
    jenkins_ssh_private_key => $jenkins_ssh_private_key,
    jenkins_ssh_public_key  => $openstack_project::jenkins_ssh_key,
  }

  jenkins::plugin { 'build-timeout':
    version => '1.14',
  }
  jenkins::plugin { 'copyartifact':
    version => '1.22',
  }
  jenkins::plugin { 'dashboard-view':
    version => '2.3',
  }
  jenkins::plugin { 'envinject':
    version => '1.70',
  }
  jenkins::plugin { 'gearman-plugin':
    version => '0.0.7',
  }
  jenkins::plugin { 'git':
    version => '1.1.23',
  }
  jenkins::plugin { 'greenballs':
    version => '1.12',
  }
  jenkins::plugin { 'extended-read-permission':
    version => '1.0',
  }
  jenkins::plugin { 'zmq-event-publisher':
    version => '0.0.3',
  }
#  TODO(jeblair): release
#  jenkins::plugin { 'scp':
#    version => '1.9',
#  }
  jenkins::plugin { 'jobConfigHistory':
    version => '1.13',
  }
  jenkins::plugin { 'monitoring':
    version => '1.40.0',
  }
  jenkins::plugin { 'nodelabelparameter':
    version => '1.2.1',
  }
  jenkins::plugin { 'notification':
    version => '1.4',
  }
  jenkins::plugin { 'openid':
    version => '1.5',
  }
  jenkins::plugin { 'publish-over-ftp':
    version => '1.7',
  }
  jenkins::plugin { 'simple-theme-plugin':
    version => '0.2',
  }
  jenkins::plugin { 'timestamper':
    version => '1.3.1',
  }
  jenkins::plugin { 'token-macro':
    version => '1.5.1',
  }

  if $manage_jenkins_jobs == true {
    class { '::jenkins::job_builder':
      url      => "https://${vhost_name}/",
      username => $jenkins_jobs_username,
      password => $jenkins_jobs_password,
    }

    file { '/etc/jenkins_jobs/config':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      recurse => true,
      purge   => true,
      force   => true,
      source  =>
        'puppet:///modules/openstack_project/jenkins_job_builder/config',
      notify  => Exec['jenkins_jobs_update'],
    }

    file { '/etc/default/jenkins':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/openstack_project/jenkins/jenkins.default',
    }
  }

  # Set up stunnel on the jenkins masters
  #
  # This sets up the stunnel service in preparation for the switch to SSL
  # for gearman. The jenkins gearman plugin doesn't support connecting to
  # a gearman server over SSL, so instead it will connect locally to the
  # listening stunnel service which will deal with the SSL wrapping of
  # the TCP connection.
  #
  # The service is currently stopped, as it isn't needed until we hit
  # the big SSL switch.
  #
  # When ready a patch set is required to start the stunnel service:
  #     ensure => running
  #
  # And we need to be sure the SSL cert, key _and_ CA is placed
  # in the required locations (2 of the three should already be in
  # place for apache):
  #     $prv_ssl_cert_file
  #     $prv_ssl_key_file
  #     $ssl_chain_file
  #
  package { 'stunnel4':
    ensure => present,
  }

  group { 'stunnel4':
    ensure => present,
  }

  user { 'stunnel4':
    ensure  => present,
    shell   => '/bin/false',
    gid     => 'stunnel4',
    require => Group['stunnel4'],
  }

  service { 'stunnel4':
    ensure  => stopped,
    has_restart => True,
    reuiqre => [
      Package['tunnel4'],
      User['stunnel4'],
      File['/etc/default/stunnel4'],
      File['/etc/stunnel/stunnel.conf'],
    ]
  }

  file { '/etc/default/stunnel4':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service['stunnel4'],
    source => 'puppet:///modules/jenkins/stunnel/default_stunnel4',
  }

  file { '/etc/stunnel/stunnel.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify => Service['stunnel4'],
    content => template('jenkins/stunnel.conf.erb'),
  }

  file { '/var/log/stunnel4/':
    ensure  => directory,
    mode    => '0755',
    uid     => 'stunnel4',
    gid     => 'stunnel4',
    require => User['stunnel4'],
  }

  file { '/var/run/stunnel4/':
    ensure  => directory,
    mode    => '0755',
    uid     => 'stunnel4',
    gid     => 'stunnel4',
    require => User['stunnel4'],
  }
}
