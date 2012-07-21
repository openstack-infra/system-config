class openstack_project::puppetmaster {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [8140]
  }
  cron { "updatepuppetmaster":
    user => root,
    minute => "*/15",
    command => 'sleep $((RANDOM\%600)) && cd /opt/openstack-ci-puppet/production && /usr/bin/git pull -q',
    environment => "PATH=/var/lib/gems/1.8/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  }
}
