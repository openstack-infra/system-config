# == Class: openstack_project::puppetmaster
#
class openstack_project::puppetmaster (
  $puppetmaster_clouds,
  $root_rsa_key = 'xxx',
  $puppetdb = true,
  $puppetdb_server = 'puppetdb.openstack.org',
  $puppetmaster_update_cron_interval = { min     => '*/15',
                                         hour    => '*',
                                         day     => '*',
                                         month   => '*',
                                         weekday => '*',
                                       },
) {
  include logrotate
  include openstack_project::params

  class { '::ansible':
    ansible_hostfile    => '/etc/ansible/hosts',
    retry_files_enabled => 'False',
  }

  file { '/etc/ansible/hostfile':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['ansible'],
  }

  cron { 'updatepuppetmaster':
    user        => 'root',
    minute      => $puppetmaster_update_cron_interval[min],
    hour        => $puppetmaster_update_cron_interval[hour],
    monthday    => $puppetmaster_update_cron_interval[day],
    month       => $puppetmaster_update_cron_interval[month],
    weekday     => $puppetmaster_update_cron_interval[weekday],
    command     => 'flock -n /var/run/puppet/puppet_run_all.lock bash /opt/system-config/production/run_all.sh >> /var/log/puppet_run_all_cron.log 2>&1',
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
    user        => 'root',
    hour        => '3',
    minute      => '0',
    command     => 'sleep $((RANDOM\%600)) && find /var/lib/puppet/reports -name \'*.yaml\' -mtime +5 -execdir rm {} \;',
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'deleteoldreports-json':
    user        => 'root',
    hour        => '3',
    minute      => '0',
    command     => 'sleep $((RANDOM\%600)) && find /var/lib/puppet/reports -name \'*.json\' -mtime +5 -execdir rm {} \;',
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
    ensure => present,
  }

  file { '/etc/apache2/sites-available/puppetmaster.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('openstack_project/puppetmaster/puppetmaster_vhost.conf.erb'),
    require => Package['puppetmaster-passenger'],
  }

# To set LANG to utf8, otherwise we get charset errors on manifests
# with non-ascii chars
  file { '/etc/apache2/envvars':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/puppetmaster/envvars.debian',
    require => Package['puppetmaster-passenger'],
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

# Enable puppetdb

  if $puppetdb {
    class { 'puppetdb::master::config':
      puppetdb_server              => $puppetdb_server,
      puppet_service_name          => 'apache2',
      puppetdb_soft_write_failure  => true,
      manage_storeconfigs          => false,
    }
  }

# Jenkins master management
  cron { 'restartjenkinsmasters':
    ensure      => absent,
    # Run through all masters onces a week.
    weekday     => '6',
    hour        => '0',
    minute      => '15',
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    command     => "flock -n /var/run/puppet/restart_jenkins_masters.lock ansible-playbook -f 1 /opt/system-config/production/playbooks/restart_jenkins_masters.yaml --extra-vars 'user=${jenkins_api_user} password=${jenkins_api_key}' >> /var/log/restart_jenkins_masters.log 2>&1",
  }

  file { '/var/log/restart_jenkins_masters.log':
    ensure => absent,
  }

  logrotate::file { 'restartjenkinsmasters':
    ensure  => absent,
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

  # Ansible mgmt
  # TODO: Put this into its own class, maybe called bastion::ansible or something

  vcsrepo { '/opt/ansible':
    ensure   => latest,
    provider => git,
    revision => 'devel',
    source   => 'https://github.com/ansible/ansible',
  }

  file { '/etc/ansible/hosts':
    ensure  => directory,
    owner   => 'root',
    group   => 'admin',
    mode    => '0755',
  }

  file { '/etc/ansible/hosts/puppet':
    ensure => absent,
  }

  file { '/etc/ansible/hosts/openstack':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => '/opt/ansible/contrib/inventory/openstack.py',
    replace => true,
    require => Vcsrepo['/opt/ansible'],
  }

  file { '/etc/ansible/hosts/static':
    ensure => absent,
  }

  file { '/etc/ansible/hosts/emergency':
    ensure  => present,
    owner   => 'root',
    group   => 'admin',
    mode    => '0664',
  }

  file { '/etc/ansible/hosts/generated-groups':
    ensure  => present,
    owner   => 'root',
    group   => 'admin',
    mode    => '0664',
  }

  file { '/etc/ansible/hosts/infracloud':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/openstack_project/puppetmaster/infracloud',
  }

  file { '/etc/ansible/groups.txt':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/puppetmaster/groups.txt',
    notify => Exec['expand_groups'],
  }

  file { '/var/cache/ansible-inventory':
    ensure  => directory,
    owner   => 'root',
    group   => 'admin',
    mode    => '2775',
  }

  file { '/var/cache/ansible-inventory/ansible-inventory.cache':
    ensure  => present,
    owner   => 'root',
    group   => 'admin',
    mode    => '0664',
  }

  file { '/usr/local/bin/expand-groups.sh':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/openstack_project/puppetmaster/expand-groups.sh',
    notify => Exec['expand_groups'],
  }

  exec { 'expand_groups':
    command     => 'expand-groups.sh',
    path        => '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    refreshonly => true,
  }

}
