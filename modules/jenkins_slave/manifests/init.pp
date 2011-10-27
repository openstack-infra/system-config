class jenkins_slave {

    jenkinsuser { "jenkins":
      ensure => present,
    }

    slavecirepo { "openstack-ci":
      ensure => present,
      require => [ Package[git], Jenkinsuser[jenkins] ],
    }

    devstackrepo { "devstack":
      ensure => present,
      require => [ Package[git], Jenkinsuser[jenkins] ],
    }

    apt::ppa { "ppa:openstack-ci/build-depends":
      ensure => present
    }

    $packages = ["apache2",
                 "autoconf",
                 "automake",
                 "build-essential",
                 "cdbs",
                 "curl",
                 "debootstrap",
                 "devscripts",
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
                 "libsasl2-dev",
                 "libtool",
                 "libvirt-bin",
                 "libxml2-dev",
                 "libxslt1-dev",
                 "maven2",
                 "openjdk-6-jre",
                 "parted",
                 "pep8",
                 "psmisc",
                 "pylint",
                 "python-all-dev",
                 "python-cheetah",
                 "python-libvirt",
                 "python-pip",
                 "python-sphinx",
                 "python-unittest2",
                 "python-vm-builder",
                 "python3-all-dev",
                 "screen",
                 "socat",
                 "sqlite3",
                 "swig",
                 "unzip",
                 "vlan",
                 "wget"]
    package { $packages:
      ensure => "latest",
      require => Apt::Ppa["ppa:openstack-ci/build-depends"],
    }

    cron { "updateci":
      user => jenkins,
      minute => "*/15",
      command => "cd /home/jenkins/openstack-ci && /usr/bin/git pull -q origin master",
      require => [ Jenkinsuser[jenkins] ],
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

}
