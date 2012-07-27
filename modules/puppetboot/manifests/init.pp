class puppetboot($ensure=present) {
  file {'/etc/init/puppetboot.conf':
    owner => 'root',
    group => 'root',
    mode => 644,
    ensure => $ensure,
    source => [
      "puppet:///modules/puppetboot/puppetboot.conf",
    ],
  }
}
