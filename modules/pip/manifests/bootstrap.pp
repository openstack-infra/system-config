# Class: pip::bootstrap
#

class pip::bootstrap ( $pythonver = $title)
{
  include pip::jsongem
  include pip::params
  notify{'completed bootstrap':
        require => [
                    Exec['get_ez_setup'],
                    Exec['get_get_pip'],
                    ],
  }

  file { '/var/lib/python-install':
      ensure => directory
  }

  if ! defined(Package['wget'])
  {
    package{'wget':ensure => present, }
  }


  exec { 'get_ez_setup':
    command => 'wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O /var/lib/python-install/ez_setup.py',
    path    => '/bin:/usr/bin',
    creates => '/var/lib/ez_setup.py',
    require => [File['/var/lib/python-install'], Package['wget']],
  }

  exec { 'get_get_pip':
    command => 'wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O /var/lib/python-install/get-pip.py',
    path    => '/bin:/usr/bin',
    creates => '/var/lib/python-install/get-pip.py',
    require => Exec['get_ez_setup'],
  }
}
