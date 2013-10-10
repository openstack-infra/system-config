# Class: pip::bootstrap
#
define pip::bootstrap (
    $description = $title
    ){
      include pip::params
      notify{$description:
              require => [
                      Exec['get_ez_setup'],
                      Exec['get_get_pip'],
                    ],
        }

      if (!defined(Package['wget']))
      {
        package { 'wget':
          ensure => present,
        }
      }

      exec { 'get_ez_setup':
        command => 'wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O /var/lib/ez_setup.py',
        path    => '/bin:/usr/bin',
        creates => '/var/lib/ez_setup.py',
      }

      exec { 'get_get_pip':
        command => 'wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O /var/lib/get-pip.py',
        path    => '/bin:/usr/bin',
        creates => '/var/lib/get-pip.py',
      }
  }

}
