class jenkins_slave {

    jenkinsuser { "jenkins":
      ensure => present
    }

    slavecirepo { "openstack-ci":
      ensure => present,
      require => [ Package[git], Jenkinsuser[jenkins] ]
    }

    apt::ppa { "ppa:tarmac/ppa":
      ensure => present,
    }

    cron { "updatepuppet":
      user => root,
      minute => "*/15",
      command => "cd /root/openstack-ci-puppet && /usr/bin/git pull -q && /var/lib/gems/1.8/bin/puppet apply -l /tmp/manifest.log --modulepath=/root/openstack-ci-puppet/modules manifests/site.pp",
      require => [ Jenkinsuser[jenkins] ]
    }

    cron { "updateci":
      user => jenkins,
      minute => "*/15",
      command => "cd /home/jenkins/openstack-ci && /usr/bin/git pull -q origin master"
    }

    file { 'aptsources':
      name => '/etc/apt/sources.list',
      owner => 'root',
      group => 'root',
      mode => 644,
      ensure => 'present',
      source => [
         "puppet:///modules/jenkins_slave/sources.list",
       ],
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

    package { "openjdk-6-jre":
        ensure => latest
          }
    
    package { "devscripts":
        ensure => latest
          }
    
    package { "python-sphinx":
        ensure => latest
          }
    
    package { "graphviz":
        ensure => latest
          }
    
    package { "pep8":
        ensure => latest
          }
    
    package { "pylint":
        ensure => latest
          }
    
    package { "python-dev":
         ensure => latest
           }

    package { "tarmac":
      ensure => latest,
      require => Apt::Ppa["ppa:tarmac/ppa"]
    }

    package { "python-pip":
        ensure => latest,
        require => Package[python-dev]
          }

    package { "python-coverage":
        ensure => latest,
        require => Package[python-nose]
          }

    package { "python-nose":
        ensure => latest,
        require => Package[python-pip]
          }

    package { "nosexcover":
        ensure => latest,
        provider => pip,
        require => Package[python-coverage]
    }

}
