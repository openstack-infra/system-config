class jenkins_slave($ssh_key, $sudo = false, $bare = false, $user = true) {

    if ($user == true) {
      jenkinsuser { "jenkins":
        ensure => present,
        sudo => $sudo,
        ssh_key => "${ssh_key}"
      }
    }

    # Packages that all jenkins slaves need
    $common_packages = [
	         "default-jdk", # jdk for building java jobs
                 "build-essential",
                 "autoconf",
                 "automake",
                 "ccache",
                 "devscripts",
                 "python-pip",
      		 ]

    # Packages that most jenkins slaves (eg, unit test runners) need
    $standard_packages = [
    		 "apache2",
                 "asciidoc", # for building gerrit
                 "cdbs",
                 "curl",
                 "debootstrap",
                 "dnsmasq-base",
                 "ebtables",
                 "gawk",
                 "graphviz",
                 "iptables",
                 "kpartx",
                 "kvm",
                 "libapache2-mod-wsgi",
                 "libcurl4-gnutls-dev",
                 "libldap2-dev",
                 "libmysqlclient-dev",
                 "libsasl2-dev",
                 "libsqlite3-dev",
                 "libtool",
                 "libvirt-bin",
                 "libxml2-dev",
                 "libxslt1-dev",
                 "lxc",
                 "maven2",
		 "mercurial", # needed by pip bundle
		 "mysql-server",
		 "pandoc", #for docs, markdown->docbook, bug 924507
                 "parted",
                 "pep8",
                 "psmisc",
                 "pylint",
                 "python-all-dev",
                 "python-cheetah",
                 "python-libvirt",
                 "python-libxml2",
                 "python-sphinx",
                 "python-unittest2",
                 "python-vm-builder",
                 "python-zmq", # zeromq unittests (not pip installable)
                 "python3-all-dev",
                 "screen",
                 "socat",
                 "sqlite3",
                 "swig",
                 "unzip",
                 "vlan",
                 "wget",
                 "pyflakes"]

    if ($bare == false) {
        $packages = [$common_packages, $standard_packages]
    } else {
        $packages = $common_packages
    }

    package { $packages:
      ensure => present,
    }

    package { "git-review":
      ensure => latest,  # okay to use latest for pip
      provider => pip,
      require => Package[python-pip],
    }

    file { 'profilerubygems':
      name => '/etc/profile.d/rubygems.sh',
      owner => 'root',
      group => 'root',
      mode => 644,
      ensure => 'present',
      source => [
         "puppet:///modules/jenkins_slave/rubygems.sh",
       ],
    }

    file { 'ccachegcc':
      name => '/usr/local/bin/gcc',
      ensure => link,
      target => '/usr/bin/ccache',
      require => Package['ccache'],
    }

    file { 'ccacheg++':
      name => '/usr/local/bin/g++',
      ensure => link,
      target => '/usr/bin/ccache',
      require => Package['ccache'],
    }

    file { 'ccachecc':
      name => '/usr/local/bin/cc',
      ensure => link,
      target => '/usr/bin/ccache',
      require => Package['ccache'],
    }

    file { 'ccachec++':
      name => '/usr/local/bin/c++',
      ensure => link,
      target => '/usr/bin/ccache',
      require => Package['ccache'],
    }


    if ($bare == false) {
         exec { "jenins-slave-mysql":
          creates => "/var/lib/mysql/openstack_citest/",
       	  command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -e \"\
       	    CREATE USER 'openstack_citest'@'localhost' IDENTIFIED BY 'openstack_citest';\
            CREATE DATABASE openstack_citest;\
            GRANT ALL ON openstack_citest.* TO 'openstack_citest'@'localhost';\
            FLUSH PRIVILEGES;\"",
          require => [
            File["/etc/mysql/my.cnf"],  # For myisam default tables
            Package["mysql-server"],
            Service["mysql"]
          ]
        }

        file { "/etc/mysql/my.cnf":
          source => 'puppet:///modules/jenkins_slave/my.cnf',
          owner => 'root',
          group => 'root',
          ensure => 'present',
          replace => 'true',
          mode => 444,
          require => Package["mysql-server"],
        }

        service { "mysql":
          name => "mysql",
          ensure    => running,
          enable    => true,
          subscribe => File["/etc/mysql/my.cnf"],
          require => [File["/etc/mysql/my.cnf"], Package["mysql-server"]]
        }
    }

    file { '/usr/local/jenkins':
      owner => 'root',
      group => 'root',
      mode => 755,
      ensure => 'directory',
    }

    file { '/usr/local/jenkins/slave_scripts':
      owner => 'root',
      group => 'root',
      mode => 755,
      ensure => 'directory',
      recurse => true,
      require => File['/usr/local/jenkins'],
      source => [
                  "puppet:///modules/jenkins_slave/slave_scripts",
                ],
    }
}
