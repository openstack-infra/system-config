# == Class: openstack_project::glancetest
#
class openstack_project::glancetest(
  $s3_store_access_key = '',
  $s3_store_secret_key = '',
  $s3_store_bucket = '',
  $s3_store_host = 's3.amazonaws.com',
) {

  file { 'jenkinsglanceconfigdir':
    ensure  => directory,
    name    => '/home/jenkins/.config/glance',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => Class['::jenkins::jenkinsuser'],
  }

  file { 'glances3conf':
    ensure  => present,
    name    => '/home/jenkins/.config/glance/s3.conf',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    require => File['jenkinsglanceconfigdir'],
    content => template('openstack_project/glance_s3.conf.erb'),
  }

  file { '/home/jenkins/.config/glance/swift.conf':
    ensure => absent,
  }
}
