class openstack_project::puppet_cron($ensure=present) {
  include logrotate

  class { 'puppetboot':
    ensure => $ensure
  }
  cron { "updatepuppet":
    ensure => $ensure,
    user => root,
    minute => "*/15",
    command => 'apt-get update >/dev/null 2>&1 ; sleep $((RANDOM\%600)) && /bin/bash /root/openstack-ci-puppet/run_puppet.sh /root/openstack-ci-puppet',
    environment => "PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  }
  logrotate::file { 'updatepuppet':
    ensure => $ensure,
    log => '/var/log/manifest.log',
    options => ['compress', 'delaycompress', 'missingok', 'rotate 7', 'daily', 'notifempty'],
    require => Cron['updatepuppet'],
  }
}
