# == Class: openstack_project::puppetmaster
#
class openstack_project::puppetmaster (
  $puppetmaster_clouds,
  $root_rsa_key = 'xxx',
  $enable_mqtt = false,
  $mqtt_hostname = 'firehose.openstack.org',
  $mqtt_port = 8883,
  $mqtt_username = 'infra',
  $mqtt_password = undef,
  $mqtt_ca_cert_contents = undef,
) {
  include logrotate

  class { '::ansible':
    ansible_hostfile    => '/etc/ansible/hosts',
    retry_files_enabled => 'False',
    ansible_version     => '2.2.1.0',
  }

  file { '/etc/ansible/hostfile':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['ansible'],
  }

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

  logrotate::file { 'updatecloudlaunchercron':
    ensure  => present,
    log     => '/var/log/puppet_run_cloud_launcher_cron.log',
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

  cron { 'updatepuppetmaster':
    ensure => absent,
  }

  logrotate::file { 'updatepuppetmaster':
    ensure  => present,
    log     => '/var/log/puppet_run_all.log',
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

  logrotate::file { 'updatepuppetmastercron':
    ensure  => present,
    log     => '/var/log/puppet_run_all_cron.log',
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

  cron { 'deleteoldreports':
    ensure => absent,
  }

  cron { 'deleteoldreports-json':
    ensure => absent,
  }

  file { '/etc/puppet/hieradata':
    ensure => directory,
    group  => 'puppet',
    mode   => '0750',
    owner  => 'puppet',
  }

  file { '/etc/puppet/hieradata/production':
    ensure  => directory,
    group   => 'puppet',
    mode    => '0750',
    owner   => 'root',
    recurse => true,
    require => File['/etc/puppet/hieradata'],
  }

  file { '/var/lib/puppet/reports':
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0750',
    }

  if ! defined(File['/root/.ssh']) {
    file { '/root/.ssh':
      ensure => directory,
      mode   => '0700',
    }
  }

  file { '/root/.ssh/id_rsa':
    ensure  => present,
    mode    => '0400',
    content => $root_rsa_key,
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

# For puppet master apache serving.
  package { 'puppetmaster-passenger':
    ensure => absent,
  }

  file { '/etc/apache2/sites-available/puppetmaster.conf':
    ensure  => absent,
  }

  file { '/etc/apache2/envvars':
    ensure  => absent,
  }

# For launch/launch-node.py.
  $pip_packages = [
    'shade',
    'python-openstackclient',
  ]
  package { $pip_packages:
    ensure   => latest,
    provider => openstack_pip,
  }
  package { 'python-paramiko':
    ensure => present,
  }
  # No longer needed with latest client libs
  package { 'python-lxml':
    ensure => absent,
  }
  package { 'libxslt1-dev':
    ensure => absent,
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

  # Temporarily pin paho-mqtt to 1.2.3 since 1.3.0 won't support TLS on
  # Trusty's Python 2.7.
  if $enable_mqtt {
    package {'paho-mqtt':
      ensure   => '1.2.3',
      provider => openstack_pip,
      require  => Class['pip'],
    }

    file { '/etc/mqtt_ca_cert.pem.crt':
      ensure  => present,
      content => $mqtt_ca_cert_contents,
      replace => true,
      owner   => 'root',
      group   => 'admin',
      mode    => '0555',
    }

    file { '/etc/mqtt_client.yaml':
      owner   => 'root',
      group   => 'admin',
      mode    => '0664',
      content => template('openstack_project/puppetmaster/mqtt_client.yaml.erb'),
    }

    file { '/opt/ansible/lib/ansible/plugins/callback/mqtt.py':
      ensure => absent,
    }

    file { '/etc/ansible/callback_plugins/mqtt.py':
      owner   => 'root',
      group   => 'admin',
      mode    => '0664',
      source  => 'puppet:///modules/openstack_project/puppetmaster/mqtt.py',
      require => File['/etc/ansible/callback_plugins'],
    }
  }

  exec { 'expand_groups':
    command     => 'expand-groups.sh',
    path        => '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    refreshonly => true,
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
