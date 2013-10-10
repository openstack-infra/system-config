# Class: pip::bootstrap
#

define pip::bootstrap ( $pythonver = $title)
{
    include pip::params
    notify{"completed bootstrap for ${pythonver}":
            require => [
                    Exec["get_ez_setup for ${pythonver}"],
                    Exec["get_get_pip for ${pythonver}"],
                    ],
    }

    exec { "get_ez_setup for ${pythonver}":
      command => 'wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O /var/lib/ez_setup.py',
      path    => '/bin:/usr/bin',
      creates => '/var/lib/ez_setup.py',
      require => Package['wget'],
    }

    exec { "get_get_pip for ${pythonver}":
      command => 'wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O /var/lib/get-pip.py',
      path    => '/bin:/usr/bin',
      creates => '/var/lib/get-pip.py',
      require => Exec["get_ez_setup for ${pythonver}"],
    }
}
