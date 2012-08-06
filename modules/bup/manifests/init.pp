class bup {
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

}
