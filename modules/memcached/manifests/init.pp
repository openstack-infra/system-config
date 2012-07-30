class memcached($memcached_size = '2000', $memcached_port = '11000', $memcached_ip = '0.0.0.0') {
  package { ["memcached"]:
    ensure => latest;
  }
  service { ["memcached"]:
    ensure => running,
    enable => true,
    require => [Package["memcached"]];
  }
  file {
    "/etc/memcached.conf":
      content => template("memcached/memcached.conf.erb"),
      owner => root,
      group => root,
      mode => 444,
      notify => Service["memcached"],
      require => [Package["memcached"]];
  }
}

