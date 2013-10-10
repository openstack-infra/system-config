# Class: pip::bootstrap
#

class pip::bootstrap ( $pythonver = $title)
{
  include pip::jsongem
  include pip::params
  notify{'completed bootstrap':
    require => [
      Downloader[$::pip::params::ez_setup_url],
      Downloader[$::pip::params::git_pip_url],
    ],
  }

  file { '/var/lib/python-install':
      ensure => directory
  }

  downloader {$::pip::params::git_pip_url:
    ensure   => present,
    path     => '/var/lib/python-install/get-pip.py',
    md5      => $::pip::params::git_pip_md5,
    owner    => 'root',
    group    => 'root',
    mode     => 755,
    replace  => false,
    provider => url,
  }
}
