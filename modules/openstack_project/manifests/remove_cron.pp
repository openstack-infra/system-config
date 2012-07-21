class openstack_project::remove_cron {
  cron { "updatepuppet":
    ensure => absent
  }

  file { '/etc/init/puppetboot.conf':
    ensure => absent
  }

  file { "/etc/logrotate.d/updatepuppet":
    ensure => absent
  }
}

