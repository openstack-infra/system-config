class jenkins_slave {

    package { "python-software-properties":
        ensure => latest
          }

    package { "openjdk-6-jre":
        ensure => latest
          }
    
    package { "puppet":
        ensure => latest
          }
    
    package { "bzr":
        ensure => latest
          }
    
    package { "git":
        ensure => latest
          }
    
    package { "python-setuptools":
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
    
    package { "byobu":
        ensure => latest
          }

    package { "python-dev":
         ensure => latest
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
