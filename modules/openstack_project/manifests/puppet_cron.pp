class openstack_project::puppet_cron {
  include logrotate
  include puppetboot
  cron { "updatepuppet":
    user => root,
    minute => "*/15",
    command => 'apt-get update >/dev/null 2>&1 ; sleep $((RANDOM\%600)) && cd /root/openstack-ci-puppet && /usr/bin/git pull -q && puppet apply -l /var/log/manifest.log --modulepath=/root/openstack-ci-puppet/modules manifests/site.pp',
    environment => "PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  }
  logrotate::file { 'updatepuppet':
    log => '/var/log/manifest.log',
    options => ['compress', 'delaycompress', 'missingok', 'rotate 7', 'daily', 'notifempty'],
    require => Cron['updatepuppet'],
  }
}

