# Class: pip::bootstrap
#

class pip::bootstrap ( $pythonver = $title)
{
  include pip::jsongem
  include pip::params
  notify{'completed bootstrap':
    require => [
      Downloader[$::pip::params::get_pip_url],
    ],
  }

  file { '/var/lib/python-install':
      ensure => directory
  }

  downloader {$::pip::params::get_pip_url:
    ensure   => present,
    path     => '/var/lib/python-install/get-pip.py',
    owner    => 'root',
    group    => 'root',
    mode     => 755,
    replace  => false,
    require  => File['/var/lib/python-install'],
  }
}
