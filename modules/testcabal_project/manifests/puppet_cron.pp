# == Class: openstack_project::puppet_cron
#
class openstack_project::puppet_cron($ensure = present)
{
  include logrotate

  class { 'puppetboot':
    ensure => $ensure,
  }
  cron { 'updatepuppet':
    ensure      => $ensure,
    user        => 'root',
    minute      => '*/15',
    command     => "${::openstack_project::params::update_pkg_list_cmd}sleep $((RANDOM\%600)) && puppet agent --test >>/var/log/manifest.log",
    environment => 'PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }
  logrotate::file { 'updatepuppet':
    ensure  => $ensure,
    log     => '/var/log/manifest.log',
    options => ['compress',
      'delaycompress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Cron['updatepuppet'],
  }
}
