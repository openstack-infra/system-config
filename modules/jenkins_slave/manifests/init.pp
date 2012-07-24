class jenkins_slave($ssh_key, $sudo = false, $bare = false, $user = true) {

    include pip

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
      		 ]

    # Packages that most jenkins slaves (eg, unit test runners) need
    $standard_packages = [
    		 "apache2",
                 "asciidoc", # for building gerrit/building openstack docs
                 "cdbs",
                 "curl",
                 "debootstrap",
                 "dnsmasq-base",
                 "docbook-xml", # for building openstack docs
                 "docbook5-xml", # for building openstack docs
                 "docbook-xsl", # for building openstack docs
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
		 "pandoc", #for docs, markdown->docbook, bug 924507
                 "parted",
                 "pep8",
                 "psmisc",
                 "pylint",
                 "python-cheetah",
                 "python-libvirt",
                 "python-libxml2",
                 "python-sphinx",
                 "python-unittest2",
                 "python-vm-builder",
                 "python-zmq", # zeromq unittests (not pip installable)
                 "python3-all-dev",
                 "screen",
                 "sgml-data",
                 "socat",
                 "sqlite3",
                 "swig",
                 "unzip",
                 "vlan",
                 "wget",
                 "xsltproc", # for building openstack docs
                 "pyflakes"]

    if ($bare == false) {
        $packages = [$common_packages, $standard_packages]
    } else {
        $packages = $common_packages
    }

    package { $packages:
      ensure => present,
    }

    # Packages that need to be installed from pip
    $pip_packages = [
                 "git-review",
                 "setuptools-git",
                 "tox"]

    package { $pip_packages:
      ensure => latest,  # we want the latest from these
      provider => pip,
      require => Class[pip]
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

        class {'mysql::server':
            config_hash =>  {
                'root_password' => 'insecure_slave',
                'default_storage_engine' = 'MyISAM',
                'bind_address' => '127.0.0.1',
            }
        }

        mysql::db { 'openstack_citest':
            user     => 'openstack_citest',
                     password => 'openstack_citest',
                     host     => 'localhost',
                     grant    => ['all'],
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

    # Temporary for debugging glance launch problem
    # https://lists.launchpad.net/openstack/msg13381.html
    file { '/etc/sysctl.d/10-ptrace.conf':
      ensure => present,
      source => "puppet:///modules/jenkins_slave/10-ptrace.conf",
      owner => 'root',
      group => 'root',
      mode => 444,
    }

    exec { "ptrace sysctl":
      subscribe => File['/etc/sysctl.d/10-ptrace.conf'],
      refreshonly => true,
      command => "/sbin/sysctl -p /etc/sysctl.d/10-ptrace.conf",
    }
}
