class cowbuilder {
    
  $slave_packages = ["git-buildpackage",
                     "pbuilder",
                     "cowbuilder",
                     "linux32",
                     "debian-archive-keyring"]

  $ubuntu_releases = [ "lucid",
                       "maverick",
                       "natty",
                       "oneiric" ]

  $debian_releases = [ "wheezy",
                       "squeeze" ]

  package { $slave_packages:
    ensure => "latest"
  }

  file { 'cowhookdir':
    name => '/var/cache/pbuilder/hook.d',
    ensure => 'directory',
    mode => 755,
    require => Package['pbuilder'],
  }

  file { 'cowhook':
    name => '/var/cache/pbuilder/hook.d/E01-enable-repos',
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'present',
    source => "puppet:///modules/cowbuilder/E01-enable-repos",
    replace => 'true',
    require => File[cowhookdir]
  }

  cowbuilder::debgpg { 'AED4B06F473041FA': }

  cowbuilder::cow { $ubuntu_releases:
    distro => 'ubuntu',
    require => [ Package[debian-archive-keyring],
                 Package[linux32],
                 File[cowhook]
               ],
  }
  cowbuilder::cow { $debian_releases:
    distro => 'debian',
    require => [ Package[debian-archive-keyring],
                 Package[linux32],
                 File[cowhook],
                 Cowbuilder::Debgpg[AED4B06F473041FA],
               ],
  }

}
