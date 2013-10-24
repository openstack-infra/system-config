# == Class: redis
#
class redis(
$redis_port = '6379',
$redis_max_memory='1gb',
$redis_bind='127.0.0.1') {

  $redis_bin_dir = '/usr/local/bin'


  File {
    owner => root,
    group => root,
  }

  package {'redis-server-uninstall':
    ensure => absent,
  }


  package {'redis-server':
    ensure  => installed,
    require => [ Package['redis-server-uninstall']],
  }

  case $::redis_version {
  /2\.2\.\d+/: {
  $redis_conf_file='redis.2.2.conf.erb'
    }
    /2\.4\.\d+/: {
  $redis_conf_file='redis.2.4.conf.erb'
    }
  /2\.6\.\d+/: {
  $redis_conf_file='redis.2.6.conf.erb'
    }
    default: {
      fail("Invalid redis version, ${::redis_version}")
    }
  }

  file { 'redis-init':
    ensure  => present,
    path    => "/etc/init.d/redis_server_${redis_port}",
    mode    => '0755',
    content => template('redis/init_script.erb'),
    notify  => Service['redis'],
  }

  file { 'redis_port.conf':
    ensure  => present,
    path    => "/etc/redis/${redis_port}.conf",
    mode    => '0644',
    content => template("redis/${redis_conf_file}"),
    require => [ Package['redis-server']],
  }

  service { 'redis':
    ensure    => running,
    name      => "redis_server_${redis_port}",
    enable    => true,
    require   => [ File['redis_port.conf'],  File['redis-init'], Package['redis-server'] ],
    subscribe => File['redis_port.conf'],
  }

}
