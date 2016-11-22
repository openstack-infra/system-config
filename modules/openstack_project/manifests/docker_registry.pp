# NOTE(mnaser): Password in this case is a bcrypt'd string, use htpasswd -bc
#               to generate it:
#
#                   htpasswd -nBb user pass
#
# == Class: openstack_project::docker_registry
#
class openstack_project::docker_registry(
  $keytab,
  $username,
  $password,
  $ssl_cert_file = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file = '',
  $ssl_chain_file_contents = '',
) {
  include ::httpd::ssl

  httpd::mod { ['proxy', 'proxy_http']:
    ensure => present,
  }

  file { '/etc/docker.keytab':
    owner   => 'docker-registry',
    group   => 'docker-registry',
    mode    => '0400',
    content => $keytab,
  }

  package { 'docker-registry':
    ensure => present,
  }

  service { 'docker-registry':
    enable => true
  }

  file { '/etc/docker/registry/config.yml':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/docker_registry/config.yml',
    require => Package['docker-registry'],
    notify  => Service['docker-registry']
  }

  file { '/etc/docker/registry/users':
    ensure  => present,
    content => template('openstack_project/docker_registry/users.erb'),
    require => Package['docker-registry'],
    notify  => Service['docker-registry']
  }

  # NOTE(mnaser): The logic for the SSL certs selection and installation
  #               is borrowed from static.pp

  # To use the standard ssl-certs package snakeoil certificate, leave both
  # $ssl_cert_file and $ssl_cert_file_contents empty. To use an existing
  # certificate, specify its path for $ssl_cert_file and leave
  # $ssl_cert_file_contents empty. To manage the certificate with puppet,
  # provide $ssl_cert_file_contents and optionally specify the path to use for
  # it in $ssl_cert_file.
  if ($ssl_cert_file == '') and ($ssl_cert_file_contents == '') {
    $cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
    file { $cert_file: }
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
    file { $key_file: }
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

  ::httpd::vhost { $::fqdn:
    port       => 443, # Is required despite not being used.
    docroot    => '/dev/null', # Is required despite not being used.
    priority   => '50',
    ssl        => true,
    template   => 'openstack_project/docker-registry.vhost.erb',
    vhost_name => $::fqdn,
    require    => [
      File[$cert_file],
      File[$key_file],
    ],
  }
}
