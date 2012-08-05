class openstack_project::glancetest(
  $s3_store_host="s3.amazonaws.com",
  $s3_store_access_key,
  $s3_store_secret_key,
  $s3_store_bucket,
  $swift_store_auth_address="auth.api.rackspacecloud.com/v1.0/",
  $swift_store_user,
  $swift_store_key,
  $swift_store_container,
  ) {

  file { 'jenkinsglanceconfigdir':
    name => '/home/jenkins/.config/glance',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 700,
    ensure => 'directory',
    require => Class['::jenkins::jenkinsuser'],
  }

  file { 'glances3conf':
    name => '/home/jenkins/.config/glance/s3.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 400,
    ensure => 'present',
    require => File['jenkinsglanceconfigdir'],
    content => template('jenkins/glance_s3.conf.erb'),
  }

  file { 'glanceswiftconf':
    name => '/home/jenkins/.config/glance/swift.conf',
    owner => 'jenkins',
    group => 'jenkins',
    mode => 400,
    ensure => 'present',
    require => File['jenkinsglanceconfigdir'],
    content => template('jenkins/glance_swift.conf.erb'),
  }

}
