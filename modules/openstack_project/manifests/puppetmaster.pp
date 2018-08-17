# == Class: openstack_project::puppetmaster
#
class openstack_project::puppetmaster (
  $puppetmaster_clouds,
  $root_rsa_key = 'xxx',
  $puppetmaster_update_cron_interval = { min     => '*/15',
                                         hour    => '*',
                                         day     => '*',
                                         month   => '*',
                                         weekday => '*',
                                       },
) {
  include logrotate

  cron { 'updatecloudlauncher':
    ensure => absent,
  }

  logrotate::file { 'updatecloudlauncher':
    ensure  => present,
    log     => '/var/log/puppet_run_cloud_launcher.log',
    options => ['compress',
      'copytruncate',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Cron['updatepuppetmaster'],
  }

# Cloud credentials are stored in this directory for launch-node.py.
  file { '/root/ci-launch':
    ensure => directory,
    owner  => 'root',
    group  => 'admin',
    mode   => '0750',
  }

  file { '/etc/openstack':
    ensure => directory,
    owner  => 'root',
    group  => 'admin',
    mode   => '0750',
  }

  file { '/etc/openstack/clouds.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'admin',
    mode    => '0660',
    content => template('openstack_project/puppetmaster/ansible-clouds.yaml.erb'),
  }

  file { '/etc/openstack/all-clouds.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'admin',
    mode    => '0660',
    content => template('openstack_project/puppetmaster/all-clouds.yaml.erb'),
  }


  # For signing key management
  package { 'gnupg':
    ensure => present,
  }
  package { 'gnupg-curl':
    ensure => present,
  }
  file { '/root/signing.gnupg':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
  file { '/root/signing.gnupg/gpg.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    source  => 'puppet:///modules/openstack_project/puppetmaster/signing.conf',
    require => File['/root/signing.gnupg'],
  }
  file { '/root/signing.gnupg/sks-keyservers.netCA.pem':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    source  => 'puppet:///modules/openstack_project/puppetmaster/sks-ca.pem',
    require => File['/root/signing.gnupg'],
  }

  # Certificate Authority for zuul services.
  file { '/etc/zuul-ca':
    ensure  => directory,
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
  }

  file { '/etc/zuul-ca/openssl.cnf':
    ensure  => present,
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    source  => 'puppet:///modules/openstack_project/puppetmaster/zuul_ca.cnf',
    require => File['/etc/zuul-ca'],
  }

  file { '/etc/zuul-ca/certs':
    ensure  => directory,
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    require => File['/etc/zuul-ca'],
  }

  file { '/etc/zuul-ca/crl':
    ensure  => directory,
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    require => File['/etc/zuul-ca'],
  }

  file { '/etc/zuul-ca/newcerts':
    ensure  => directory,
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    require => File['/etc/zuul-ca'],
  }

  file { '/etc/zuul-ca/private':
    ensure  => directory,
    owner   => 'root',
    group   => 'puppet',
    mode    => '0640',
    require => File['/etc/zuul-ca'],
  }
}
