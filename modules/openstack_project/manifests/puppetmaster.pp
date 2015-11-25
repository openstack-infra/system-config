# == Class: openstack_project::puppetmaster
#
class openstack_project::puppetmaster (
  $jenkins_api_key,
  $puppetmaster_clouds,
  $jenkins_api_user = 'hudson-openstack',
  $root_rsa_key = 'xxx',
  $puppetdb = true,
  $puppetdb_server = 'puppetdb.openstack.org',
) {
  include logrotate
  include openstack_project::params

  include ansible

  file { '/etc/ansible/hostfile':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['ansible'],
  }

  cron { 'updatepuppetmaster':
    user        => 'root',
    minute      => '*/15',
    command     => 'flock -n /var/run/puppet/puppet_run_all.lock bash /opt/system-config/production/run_all.sh',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
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

  cron { 'deleteoldreports':
    user        => 'root',
    hour        => '3',
    minute      => '0',
    command     => 'sleep $((RANDOM\%600)) && find /var/lib/puppet/reports -name \'*.yaml\' -mtime +7 -execdir rm {} \;',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
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
    group   => 'root',
    mode    => '0600',
    content => template('openstack_project/puppetmaster/ansible-clouds.yaml.erb'),
  }

  package { 'puppetmaster-passenger':
    ensure => absent,
  }

  file { '/etc/apache2/sites-available/puppetmaster.conf':
    ensure  => absent,
  }

  file { '/etc/apache2/envvars':
    ensure  => absent,
  }

# For launch/launch-node.py and ansible openstack inventory
  package { 'shade':
    ensure   => latest,
    provider => pip,
    require  => [Package['python-lxml'], Package['libxslt1-dev']],
  }
  package { 'python-paramiko':
    ensure => present,
  }
  package { 'python-lxml':
    ensure => present,
  }
  package { 'libxslt1-dev':
    ensure => present,
  }

# Jenkins master management
  cron { 'restartjenkinsmasters':
    user        => 'root',
    # Run through all masters onces a week.
    weekday     => '6',
    hour        => '0',
    minute      => '15',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    command     => "flock -n /var/run/puppet/restart_jenkins_masters.lock ansible-playbook -f 1 /opt/system-config/production/playbooks/restart_jenkins_masters.yaml --extra-vars 'user=${jenkins_api_user} password=${jenkins_api_key}' >> /var/log/restart_jenkins_masters.log 2>&1",
  }

  logrotate::file { 'restartjenkinsmasters':
    ensure  => present,
    log     => '/var/log/restart_jenkins_masters.log',
    options => ['compress',
      'copytruncate',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Cron['restartjenkinsmasters'],
  }

}
