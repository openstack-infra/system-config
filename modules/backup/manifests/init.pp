class backup ($backup_user, $backup_server) {
  package { "bup":
    ensure => present
  }

  file { "/etc/bup-excludes":
    ensure => present,
    content => "/proc/*
/sys/*
/dev/*
/tmp/*
/floppy/*
/cdrom/*
/var/spool/squid/*
/var/spool/exim/*
/media/*
/mnt/*
/var/agentx/*
/run/*
"
  }

  cron { "bup-rs-ord":
    user => root,
    hour => "5",
    minute => "37",
    command => "tar -X /etc/bup-excludes -cPf - / | bup split -r $backup_user@$backup_server: -n root -q",
  }
}
