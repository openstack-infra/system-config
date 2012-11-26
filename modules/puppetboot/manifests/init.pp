# == Class: puppetboot
#
class puppetboot($ensure=present) {
  file {'/etc/init/puppetboot.conf':
    ensure => $ensure,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/puppetboot/puppetboot.conf',
  }
}
