# == Class: puppetboot
#
class puppetboot($ensure=present) {
  if ($::operatingsystem in ['CentOS', 'RedHat', 'Ubuntu']) {
    file {'/etc/init/puppetboot.conf':
      ensure => $ensure,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/puppetboot/puppetboot.conf',
    }
  }
}
