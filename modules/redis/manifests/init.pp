class redis(
$redis_port = '6379',
$redis_max_memory='1gb',
$redis_bind='127.0.0.1'){
	
	include wget
	include gcc

	$src_dir = "/usr/local/src"
	$redis_pkg = "redis-2.6.16.tar.gz"
	$redis_src_dir = "${src_dir}/redis"
	$redis_bin_dir = "/usr/local"

	File {
	    owner => root,
	    group => root,
	}

	file { '/etc/redis':
	    ensure => directory,
  	}

	file {'redis-src-dir':	
	    path => $redis_src_dir,
	    ensure => directory,
  	}

	file { 'redis-init':
	    ensure  => present,
	    path    => "/etc/init.d/redis_server_${redis_port}",
	    mode    => '0755',
	    content => template('redis/init_script.erb'),
	    notify  => Service['redis'],
	}
	
	
	file { 'redis-pkg':
	      ensure => present,
	      path   => "$redis_src_dir/${redis_pkg}",
	      mode   => '0644',
	      source => "puppet:///modules/redis/${redis_pkg}",
	      require => File['redis-src-dir'],	
	}

	notify { "unpacking redis package ${redis_pkg}":
		 withpath => true, }

	exec { 'unpack-redis':
	    command => "tar --strip-components 1 -xzf ${redis_pkg}",
	    cwd     => $redis_src_dir,
	    path    => '/bin:/usr/bin',
	    unless  => "test -f ${redis_src_dir}/Makefile",
	    require => File['redis-pkg'],
  	}

	file { 'redis_port.conf':
	    ensure  => present,
	    path    => "/etc/redis/${redis_port}.conf",
	    mode    => '0644',
	    content => template('redis/redis.conf.erb'),
	    require => [ Exec['unpack-redis']],		
        }


	notify { "building redis...": withpath => true,  }	

	exec { 'install-redis':
	    command => "make && make install PREFIX=${redis_bin_dir}",
	    cwd     => $redis_src_dir,
	    path    => '/bin:/usr/bin',
	    require => [ Exec['unpack-redis'], Class['gcc'] ],
	}

	notify { "starting redis server...": withpath => true,  }	

	service { 'redis':
	    ensure    => running,
	    name      => "redis_server_${redis_port}",
	    enable    => true,
	    require   => [ File['redis_port.conf'],  File['redis-init'], Exec['install-redis'] ],
	    subscribe => File['redis_port.conf'],
       }
}
