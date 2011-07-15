
class openstack_ci_admins_users {
  include sudoers
  
  group { 'annegentle':
    ensure => 'present'
  }

  user { 'annegentle':
    ensure => 'present',
    comment => 'Anne Gentle',
    home => $operatingsystem ? {
      Darwin => '/Users/annegentle',
      solaris => '/export/home/annegentle',
      default => '/home/annegentle',
    },
    shell => '/bin/bash',
    gid => 'annegentle',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'annegentlehome':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle',
      solaris => '/export/home/annegentle',
      default => '/home/annegentle',
    },
    owner => 'annegentle',
    group => 'annegentle',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'annegentlesshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.ssh',
      solaris => '/export/home/annegentle/.ssh',
      default => '/home/annegentle/.ssh',
    },
    owner => 'annegentle',
    group => 'annegentle',
    mode => 700,
    ensure => 'directory',
    require => File['annegentlehome'],
  }

  file { 'annegentlekeys':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.ssh/authorized_keys',
      solaris => '/export/home/annegentle/.ssh/authorized_keys',
      default => '/home/annegentle/.ssh/authorized_keys',
    },
    owner => 'annegentle',
    group => 'annegentle',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3A74P+vhfqTKUP3s6qtOYtJJnBtNyrR59M0Vh+/iZIqI4uWMrmAYhn8dRyagWKYHG7d7zb3kPa9ckJBjSFdJfhLqwgcjGRewh6G6rqTuuiQTw73AJSHu9zenlrUha27oMyklX/ApZpUMBECzH4FgqhfUuRI4wulAgvnM6jm/eA+zGpmlRQMuguY9P8+AOirhk/koQhVDlR10aTzUCg6NLNmzi+72jSxBqEt8IzlE/f3emGJ09hCNQyz+PxGJUesoZ3UQhhda8Fuosi9j/ANbknSh68b5UNKuldPl9TjmxFPBX36chIMFJW1Ln/gwdjY+GIaGfXI0BPRVugdLdIgbjw== stacker@gentle\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA507CBhTaT8grzfX0BZ7Xe2CrVVUAe8Vh3YttEYD0Rkm3S78WJtkGAsYYk+SHft0KuXZWRAPWUcARRDDVa9PsIVFBiMgTEjN5UeLcPpMNctxvBfjeHOrZBhBFmrHodAmcv3rRRRnLJqNjg6w5OHM8usaaHOxHMhUErxfm3p/MsVKhIXRuZFXi1XswsRjrVxFvwc+U9m7YLRuSOjl4m6BMmLrvJVzBR6UYWWF6fCyJZc3AnDVeynqqDYl8KW+Xy4PferNHhMFm4fbCKdVPKUNGfRmvR1ZptCVbCceaPLg6rrLDPpybtzKDB37jI8zvr+NcE8B4mbE224XJ/JVpOmMOIw== anne.gentle@M1EVAGY\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA78jhKB4vlEKYueZ4v9WiceCf8BWRr7p9Oo7X/6vGad+Al0P0JTu1tuf9ErjaDR5mxtCWi6Am2MI7ddQef7yQyKCDxTct9QPfrZmzLeRSFEzw3OlnoM4oIdv7FKF5WzGRjNdYYiT4YvuuYMA0RvczRjHawlVVCdPnUiQD54RJOKmw3K9pW8i9GgcMre1w1ewO+wMeV3vR+NEyL1Qk0xmXfl49uSbaFOHyiu3g56ELqs1rqTG+xTpvzjHNFkOlN0O9lLwjIWiDkK7/rr8pP/3ivneXoPh+0kFGXPdH/bYCoAwveYFUyGc9SMTzNc9jo+1j+NuXjXNmPtEikDfvk2xe3w== annegentle@annegentle-ubuntu\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAoKqhG8vjinpt1T5VP42rtaj/WFyESYQuBAbQPfQbRrSSt3NeHeU1y/iRIvO3kpuRYcxJeqk6+GBH4Py55WjtiJKdRDNXKhIVqTVBMr26+7Gn/9Hxg26uU48wQiU5orAfLY+6MM1Eol2yJDATx7IlWQvOhCPcGQabWccyXNSP+1bCnGLTzO7hqI6Nnr1QuXiZJdDrJ9ATAhdqvGTzBsZGiM+Qps2C96dmURPOE4Iu9CF3dwu6RDi8UDzJfxdxU7hvq/r+EF4RWnSG2e5lRaifrrkieSISy5JzMJ4uxMN7I2hISk9/slQjq34yU9/DXZ3FvKRfV+iQ+o3g4WN2lQQQZw== training@SwiftTest\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClzt3qeTsyYAtsiCS+WmLvCzBww88gqSIHPUnxUbvYjkoSp8YpCRsFBtN6Z2Fwpete8PymjCmp4wUhh5XariIAWUVmju6mtZ7qsU2e/h5qm+He861Yat5R5YD024SyijQTRDoOrkQMtnX2bphHXKjKtPgGGe5AZbV3m7GcBQQXdH+7ViT5IDvCFnl94YYQVkRl5fHPAtAYleHjLDaD15fqbJsXzjoDdV5A9mL+D80+pNa31At/pw9Foc1VDpM8/zJu0n11oI/B68MOnVw/dudrPEA7tEiXKHKlVbNcuzK3fWj2pmgICIqsIX3Idq3dlN9OO+pDF+BaXgWNzLKaZmWt docbuilder@DocBuilds\n",
    ensure => 'present',
    require => File['annegentlesshdir'],
  }

  file { 'annegentlebashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.bashrc',
      solaris => '/export/home/annegentle/.bashrc',
      default => '/home/annegentle/.bashrc',
    },
    owner => 'annegentle',
    group => 'annegentle',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'annegentlebash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.bash_logout',
      solaris => '/export/home/annegentle/.bash_logout',
      default => '/home/annegentle/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'annegentle',
    group => 'annegentle',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'annegentleprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.profile',
      solaris => '/export/home/annegentle/.profile',
      default => '/home/annegentle/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'annegentle',
    group => 'annegentle',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'annegentlebazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.bazaar',
      solaris => '/export/home/annegentle/.bazaar',
      default => '/home/annegentle/.bazaar',
    },
    owner => 'annegentle',
    group => 'annegentle',
    mode => 755,
    ensure => 'directory',
    require => File['annegentlehome'],
  }


  file { 'annegentlebazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/annegentle/.bazaar/authentication.conf',
      solaris => '/export/home/annegentle/.bazaar/authentication.conf',
      default => '/home/annegentle/.bazaar/authentication.conf',
    },
    owner => 'annegentle',
    group => 'annegentle',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = annegentle\n",
    ensure => 'present',
    require => File['annegentlebazaardir'],
  }


  group { 'dan-prince':
    ensure => 'present'
  }

  user { 'dan-prince':
    ensure => 'present',
    comment => 'Dan Prince',
    home => $operatingsystem ? {
      Darwin => '/Users/dan-prince',
      solaris => '/export/home/dan-prince',
      default => '/home/dan-prince',
    },
    shell => '/bin/bash',
    gid => 'dan-prince',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'dan-princehome':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince',
      solaris => '/export/home/dan-prince',
      default => '/home/dan-prince',
    },
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'dan-princesshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.ssh',
      solaris => '/export/home/dan-prince/.ssh',
      default => '/home/dan-prince/.ssh',
    },
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 700,
    ensure => 'directory',
    require => File['dan-princehome'],
  }

  file { 'dan-princekeys':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.ssh/authorized_keys',
      solaris => '/export/home/dan-prince/.ssh/authorized_keys',
      default => '/home/dan-prince/.ssh/authorized_keys',
    },
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA+yNMzUrQXa0EOfv+WJtfmLO1WdoOaD47G9qwllSUc4GPRkYzkTNdxcEPrR3XBR94ctOeWOHZ/w7ymhvwK5LLsoNBK+WgRz/mg8oHcii2GoL0fNojdwUMyFMIJxJT+iwjF/omyhyrW/aLAztAKRO7BdOkNlXMAAcMxKzQtFqdZm09ghoImu3BPYUTyDKHMp+t0P1d7mkHdd719oDfMf+5miHxQeJZJCWAsGwroN7k8a46rvezDHEygBsDAF2ZpS2iGMABos/vTp1oyHkCgCqc3rM0OoKqcKB5iQ9Qaqi5ung08BXP/PHfVynXzdGMjTh4w+6jiMw7Dx2GrQIJsDolKQ== dan.prince@dovetail\n",
    ensure => 'present',
    require => File['dan-princesshdir'],
  }

  file { 'dan-princebashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.bashrc',
      solaris => '/export/home/dan-prince/.bashrc',
      default => '/home/dan-prince/.bashrc',
    },
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'dan-princebash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.bash_logout',
      solaris => '/export/home/dan-prince/.bash_logout',
      default => '/home/dan-prince/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'dan-princeprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.profile',
      solaris => '/export/home/dan-prince/.profile',
      default => '/home/dan-prince/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'dan-princebazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.bazaar',
      solaris => '/export/home/dan-prince/.bazaar',
      default => '/home/dan-prince/.bazaar',
    },
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 755,
    ensure => 'directory',
    require => File['dan-princehome'],
  }


  file { 'dan-princebazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/dan-prince/.bazaar/authentication.conf',
      solaris => '/export/home/dan-prince/.bazaar/authentication.conf',
      default => '/home/dan-prince/.bazaar/authentication.conf',
    },
    owner => 'dan-prince',
    group => 'dan-prince',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = dan-prince\n",
    ensure => 'present',
    require => File['dan-princebazaardir'],
  }


  group { 'eday':
    ensure => 'present'
  }

  user { 'eday':
    ensure => 'present',
    comment => 'Eric Day',
    home => $operatingsystem ? {
      Darwin => '/Users/eday',
      solaris => '/export/home/eday',
      default => '/home/eday',
    },
    shell => '/bin/bash',
    gid => 'eday',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'edayhome':
    name => $operatingsystem ? {
      Darwin => '/Users/eday',
      solaris => '/export/home/eday',
      default => '/home/eday',
    },
    owner => 'eday',
    group => 'eday',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'edaysshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.ssh',
      solaris => '/export/home/eday/.ssh',
      default => '/home/eday/.ssh',
    },
    owner => 'eday',
    group => 'eday',
    mode => 700,
    ensure => 'directory',
    require => File['edayhome'],
  }

  file { 'edaykeys':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.ssh/authorized_keys',
      solaris => '/export/home/eday/.ssh/authorized_keys',
      default => '/home/eday/.ssh/authorized_keys',
    },
    owner => 'eday',
    group => 'eday',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAqs8pBCqpAYnyqoyOO9Z5bF4CGHxIiAA10k78EDlwd6muoREEnTmGtxNiRO5HY6wzkpNaHm7JaD8VTRmrAPSQ9z9htWyTSk2e5jWsBblePdxU+tU73E6ZZrGC35eZSWIn1AuuJRZSvIZ55fwrYcqW/y1lELHLyB5DfMIGXxPBiTcqmhYonGEpeBD676AzZ+pwpPjdDonyuY9+gE21UaTQl2Z1Xxp1O05p169WQmYB9Pr8tcpL9GkFZ38uBFS+6fdIHisCs5vXEvW23GUL0izNJeJrtHcjAcjwYRi4l2FCoFi9PwmPvkwic4wcaiSS+T85dZB8myFn6i2CALrMtqCvmJEAaxPk+9cfFqd71mEyxXn1zTYdAezTURn4OnHhQGxvy4fvP8SRfUsV0We5+A8afpEqYedaZBnM4LIARaY6jKqK1FPVjAKyTSwdaUQwYjxg2Xp1VoY1PwwHYA27rubn4wLotfzsLWILJPuMgzkHhiyI+ozruE7CeKWVnlUq+Ogx4eK8It9WWU+KRo1kjDZEBIdPLj29mZj4JSF/hTzgZgs6CxUZa+A8cukJW/2brxpZBy/xLt0lWnHWYzWHwCBhsvlYS48loLi2OE1osWn7nDtibnt0lyiYuDP93AXkXxVbmxmmRnimy4VT2KNxCi0Qa0Pjisg92OfgIyTHeejsHck= eday@oddments.org",
    ensure => 'present',
    require => File['edaysshdir'],
  }

  file { 'edaybashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.bashrc',
      solaris => '/export/home/eday/.bashrc',
      default => '/home/eday/.bashrc',
    },
    owner => 'eday',
    group => 'eday',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'edaybash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.bash_logout',
      solaris => '/export/home/eday/.bash_logout',
      default => '/home/eday/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'eday',
    group => 'eday',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'edayprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.profile',
      solaris => '/export/home/eday/.profile',
      default => '/home/eday/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'eday',
    group => 'eday',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'edaybazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.bazaar',
      solaris => '/export/home/eday/.bazaar',
      default => '/home/eday/.bazaar',
    },
    owner => 'eday',
    group => 'eday',
    mode => 755,
    ensure => 'directory',
    require => File['edayhome'],
  }


  file { 'edaybazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/eday/.bazaar/authentication.conf',
      solaris => '/export/home/eday/.bazaar/authentication.conf',
      default => '/home/eday/.bazaar/authentication.conf',
    },
    owner => 'eday',
    group => 'eday',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = eday\n",
    ensure => 'present',
    require => File['edaybazaardir'],
  }


  group { 'corvus':
    ensure => 'present'
  }

  user { 'corvus':
    ensure => 'present',
    comment => 'James E. Blair',
    home => $operatingsystem ? {
      Darwin => '/Users/corvus',
      solaris => '/export/home/corvus',
      default => '/home/corvus',
    },
    shell => '/bin/bash',
    gid => 'corvus',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'corvushome':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus',
      solaris => '/export/home/corvus',
      default => '/home/corvus',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'corvussshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.ssh',
      solaris => '/export/home/corvus/.ssh',
      default => '/home/corvus/.ssh',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 700,
    ensure => 'directory',
    require => File['corvushome'],
  }

  file { 'corvuskeys':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.ssh/authorized_keys',
      solaris => '/export/home/corvus/.ssh/authorized_keys',
      default => '/home/corvus/.ssh/authorized_keys',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvKYcWK1T7e3PKSFiqb03EYktnoxVASpPoq2rJw2JvhsP0JfS+lKrPzpUQv7L4JCuQMsPNtZ8LnwVEft39k58Kh8XMebSfaqPYAZS5zCNvQUQIhP9myOevBZf4CDeG+gmssqRFcWEwIllfDuIzKBQGVbomR+Y5QuW0HczIbkoOYI6iyf2jB6xg+bmzR2HViofNrSa62CYmHS6dO04Z95J27w6jGWpEOTBjEQvnb9sdBc4EzaBVmxCpa2EilB1u0th7/DvuH0yP4T+X8G8UjW1gZCTOVw06fqlBCST4KjdWw1F/AuOCT7048klbf4H+mCTaEcPzzu3Fkv8ckMWtS/Z9Q== jeblair@operational-necessity\n",
    ensure => 'present',
    require => File['corvussshdir'],
  }

  file { 'corvusbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.bashrc',
      solaris => '/export/home/corvus/.bashrc',
      default => '/home/corvus/.bashrc',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'corvusbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.bash_logout',
      solaris => '/export/home/corvus/.bash_logout',
      default => '/home/corvus/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'corvusprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.profile',
      solaris => '/export/home/corvus/.profile',
      default => '/home/corvus/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'corvusbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.bazaar',
      solaris => '/export/home/corvus/.bazaar',
      default => '/home/corvus/.bazaar',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 755,
    ensure => 'directory',
    require => File['corvushome'],
  }


  file { 'corvusbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/corvus/.bazaar/authentication.conf',
      solaris => '/export/home/corvus/.bazaar/authentication.conf',
      default => '/home/corvus/.bazaar/authentication.conf',
    },
    owner => 'corvus',
    group => 'corvus',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = corvus\n",
    ensure => 'present',
    require => File['corvusbazaardir'],
  }


  group { 'jaypipes':
    ensure => 'present'
  }

  user { 'jaypipes':
    ensure => 'present',
    comment => 'Jay Pipes',
    home => $operatingsystem ? {
      Darwin => '/Users/jaypipes',
      solaris => '/export/home/jaypipes',
      default => '/home/jaypipes',
    },
    shell => '/bin/bash',
    gid => 'jaypipes',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'jaypipeshome':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes',
      solaris => '/export/home/jaypipes',
      default => '/home/jaypipes',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'jaypipessshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.ssh',
      solaris => '/export/home/jaypipes/.ssh',
      default => '/home/jaypipes/.ssh',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 700,
    ensure => 'directory',
    require => File['jaypipeshome'],
  }

  file { 'jaypipeskeys':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.ssh/authorized_keys',
      solaris => '/export/home/jaypipes/.ssh/authorized_keys',
      default => '/home/jaypipes/.ssh/authorized_keys',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5d2DekN5POb+e04tVtC/pok7r0Lg/+90sbvhgLTDKSGM7uPI83ulH4sZrMKVU5NTK4GBh9G+RNK6UaKodNiBGKiHZ4QdaMqbkP3TIXd3uDEBUefEAzSqpCGydbjpmtxFZWtA5hcKXTSpMRbbx/vek3lYIRsQaU0Ezc7V0cczSmJBGA6VH22TIW/5wkVvZQozK2jdkIAnJhdL7CN5kKyGs94CfXN9ofNr1ssVb/tPJqSotx7FDcrwT9VmEWTn/nCuoWf42sVu0RIHVMSpr5sxFa+G33omeRLOSCCD+zYZoMCEHZTFNCXZhPWGebWhgGHsu0+bN6heRmoJ8lw01gHxWQ== jpipes@serialcoder\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAt2tCgmlHEj5huGLJTPM2pV+aj6ZObneGq92m30LsKOn2SMrC9y4PpqjlRDweduBDKK2cPSnHt3HL1jM5npLh5IGHN2FxAWo3spgwpWPhdkT1VbdyiTZPw4++y/qZhWdNvEWBpNcf3Zn2Qi0x7F1+5fCri/vwVA9RBG35wozaP0mkxaJuAS/LLR7ZJIF99Fqfdk6+Fp5mobXt0ggEqs/78MhCuE2AYaNZ/VWCoanL4w6+UJwZV1Ftd9Ksx6f+8NpaOC9WlNSxJmp2EDJsLBy8mpJh1OsAjC3hu1VvQYmYhSo47ADSfAw9h7aaLUcL6hb7w2n4f+9Ej2+L6+NzEm0Izw== jpipes@serialcoder",
    ensure => 'present',
    require => File['jaypipessshdir'],
  }

  file { 'jaypipesbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.bashrc',
      solaris => '/export/home/jaypipes/.bashrc',
      default => '/home/jaypipes/.bashrc',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'jaypipesbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.bash_logout',
      solaris => '/export/home/jaypipes/.bash_logout',
      default => '/home/jaypipes/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jaypipesprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.profile',
      solaris => '/export/home/jaypipes/.profile',
      default => '/home/jaypipes/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'jaypipesbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.bazaar',
      solaris => '/export/home/jaypipes/.bazaar',
      default => '/home/jaypipes/.bazaar',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 755,
    ensure => 'directory',
    require => File['jaypipeshome'],
  }


  file { 'jaypipesbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/jaypipes/.bazaar/authentication.conf',
      solaris => '/export/home/jaypipes/.bazaar/authentication.conf',
      default => '/home/jaypipes/.bazaar/authentication.conf',
    },
    owner => 'jaypipes',
    group => 'jaypipes',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = jaypipes\n",
    ensure => 'present',
    require => File['jaypipesbazaardir'],
  }


  group { 'heckj':
    ensure => 'present'
  }

  user { 'heckj':
    ensure => 'present',
    comment => 'Joseph Heck',
    home => $operatingsystem ? {
      Darwin => '/Users/heckj',
      solaris => '/export/home/heckj',
      default => '/home/heckj',
    },
    shell => '/bin/bash',
    gid => 'heckj',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'heckjhome':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj',
      solaris => '/export/home/heckj',
      default => '/home/heckj',
    },
    owner => 'heckj',
    group => 'heckj',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'heckjsshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.ssh',
      solaris => '/export/home/heckj/.ssh',
      default => '/home/heckj/.ssh',
    },
    owner => 'heckj',
    group => 'heckj',
    mode => 700,
    ensure => 'directory',
    require => File['heckjhome'],
  }

  file { 'heckjkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.ssh/authorized_keys',
      solaris => '/export/home/heckj/.ssh/authorized_keys',
      default => '/home/heckj/.ssh/authorized_keys',
    },
    owner => 'heckj',
    group => 'heckj',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA3GLOPOhg6NZX6AS5RaDaxNUPVyvSOPty3X2ZWfF1p9YzO9hF6r97g/Du3DawFO9wluCZxOJujsz8mMZT77ZeiTPYMhKZj2v9fC63PnZ++6d2k3h6SNK/oezc9t9nzor9hX7nr5N7xYOWmke6SOmET+Ju0EOv47ckjcVKZeA1S6c= joe@mu.org\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxp9biRxxduCjWz0ytNj1+bGCTB6GRecWFUp4Bk1iC6X2oiNE600vfAJw+qZljvTzZ4ijwe4bYP26FdHvH1dKc3Oc9UiExYg9BuGue62LdVQGFtpNWvgPxzoRsU+Eko3X6MbtnzQeCW+Fv2vqzKZqt9ItO4UAXwH3hQ54V6rZKbPBOI66IJahWlIYCuLBbaoZOTonXoigVACrqkmfPdOTgo63wqi0yON5OUX9FoUD8vXRe8gbs0uOE2Zc/RHnaAueagSnMHiJcYUarzdukjmmNbHtXjgg/VmC3HCrWWKZYMLPy8Xtxb32METTfutXnKBTicl5Fgy5UKiXcEu3PVY1rQ== heckj@ubuntu\n\nssh-dsa AAAAB3NzaC1kc3MAAACBALwgmRY9/4ZXBMHFaELPtiuL0EMcPOjC7OuP1WzT0shbZXPcr5x5pwF23op6iXv2xh4utx41q0KO7QqkN6FW+LvSd2IXpL+3uwoQWK2FO9S+6x2/pkcb5uFHRgUXDHYS68F4Vp4K67Rx0JBlMvc5l+Uba6KwF7ROPz7tVbMD0E0PAAAAFQCafbZcaqDpRlVd4lRIxRQCGRNEWQAAAIEAlqa05bUYsTdY8kcL+Ox/V4fP6JN65kVt+l2Iiw3bJ5Vog5Z9thANAltL1dq2wf6IXvQHfPIXzWEOfOJbHAlNfUpP3tSswTJ4pTC5z04xWWdViiKolhMKxwQ+IEOxYQubqozOtuZs9JYIX4T5K2LrQ01ohxlhA1TObVWZAmbzfrQAAACAaFb18djhUQbLqZG9yns4Uwn/T+Dm6kVE3WAmv8bzf843k9GWu2xe75ldw9pA80x43Eu1OhBpknC9kl3g48VwxMYphuBH7/1PEiGCEJCWdniOYdxUPPRT5bw9BZCLYVe1twmUb8NHyg1OEkAuNieKn49ReQ7dkNokrA43bzFPLOI= heckj@cwch.local\n",
    ensure => 'present',
    require => File['heckjsshdir'],
  }

  file { 'heckjbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.bashrc',
      solaris => '/export/home/heckj/.bashrc',
      default => '/home/heckj/.bashrc',
    },
    owner => 'heckj',
    group => 'heckj',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'heckjbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.bash_logout',
      solaris => '/export/home/heckj/.bash_logout',
      default => '/home/heckj/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'heckj',
    group => 'heckj',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'heckjprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.profile',
      solaris => '/export/home/heckj/.profile',
      default => '/home/heckj/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'heckj',
    group => 'heckj',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'heckjbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.bazaar',
      solaris => '/export/home/heckj/.bazaar',
      default => '/home/heckj/.bazaar',
    },
    owner => 'heckj',
    group => 'heckj',
    mode => 755,
    ensure => 'directory',
    require => File['heckjhome'],
  }


  file { 'heckjbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/heckj/.bazaar/authentication.conf',
      solaris => '/export/home/heckj/.bazaar/authentication.conf',
      default => '/home/heckj/.bazaar/authentication.conf',
    },
    owner => 'heckj',
    group => 'heckj',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = heckj\n",
    ensure => 'present',
    require => File['heckjbazaardir'],
  }


  group { 'mordred':
    ensure => 'present'
  }

  user { 'mordred':
    ensure => 'present',
    comment => 'Monty Taylor',
    home => $operatingsystem ? {
      Darwin => '/Users/mordred',
      solaris => '/export/home/mordred',
      default => '/home/mordred',
    },
    shell => '/bin/bash',
    gid => 'mordred',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'mordredhome':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred',
      solaris => '/export/home/mordred',
      default => '/home/mordred',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'mordredsshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.ssh',
      solaris => '/export/home/mordred/.ssh',
      default => '/home/mordred/.ssh',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 700,
    ensure => 'directory',
    require => File['mordredhome'],
  }

  file { 'mordredkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.ssh/authorized_keys',
      solaris => '/export/home/mordred/.ssh/authorized_keys',
      default => '/home/mordred/.ssh/authorized_keys',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr+HlnLCCMnAqP6bvAQmb6aMfNjwp425OuG9nlN6uXXEymP5G/WT/Ok2RWb+O1hsaRGsvwHrkCdhCvT0XrDIWRCK3vaQ/v0LogeRbX5HIdOrH6r5N++DV9SqVTFZ6+54CfOE/pyku6pkBdoM8WJ9EIQBQC82EE6mgtpS/UNdiymsoB+2I8yNwUROm/AROCjqN60PI/2j234qYYaUXoD/FM3ZE/cfUoTTi0NAbt5OM5pCHPfaWhWCYtQ4l2CnEXXhKU9TcoQVoTu54IBAmblgD2LeJnOsKQtVcd5rgGzl/OtkL1ZvWCq23LHMeOC2WANgWIyxp4x66m51uErbgnTwOkQ== monty@sanction\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwgRJ+iQMzive6pq8f/F4N0CN0+SptI5l+yj10Rx3i80Zh4a3ERratuIsEmuyyeBU/l+dmR074Jic/42rYnQJBEKT5bvGLhiftcSUu630NZgAFnP5e4TbpHlYJzXDxOOctAHyd8TH5iQftWeNi5NIYAwfYpO6a4/GE1InMcyqW+icyDxyt3rwDN0qzLHcVFdCgWPsbEuJuqweH/qsen78LNWPro+ynk6dnsSKhe8dWkhYjPhAEjbsL13VezksHNbk2aa/yvppCCgdLdvniaQDKr+F0/X5Xp1teL8L7Rr9Ei+I3l6Ge4I3KY0s8TM+6TpAp4GGvdKakOBeoSAP5wYjrw== root@camelot\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyxfIpVCvZyM8BIy7r7WOSIG6Scxq4afean1Pc/bej5ZWHXCu1QnhGbI7rW3sWciEhi375ILejfODl2TkBpfdJe/DL205lLkTxAa+FUqcZ5Ymwe+jBgCH5XayzyhRPFFLn07IfA/BDAjGPqFLvq6dCEHVNJIui6oEW7OUf6a3376YF55r9bw/8Ct00F9N7zrISeSSeZXbNR+dEqcsBEKBqvZGcLtM4jzDzNXw1ITPPMGaoEIIszLpkkJcy8u/13GIrbAwNrB2wjl6Mzj+N9nTsB4rFtxRXp31ZbytCH5G9CL/mFard7yi8NLVEJPZJvAifNVhooxGN06uAiTFE8EsuQ== mtaylor@qualinost\n\nssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIB6bmpw3QjDUMDhYGiSA1tlolTrGQGcSXgfGindWnDymGE5uglpgsGbYeRqL+4lrULCDYvMJ9IGSVJOQ40VcnRcGHO+ykyUp3VNTnfwpU0Ee3xapmKL0o7sPqXx8Vlr0X2b7RaQbUYT48jyI9D1h5RW8At2X4N4A4d1HibfURTzgQ== rsa-key-20100819\nssh-dsa AAAAB3NzaC1kc3MAAACBAKwcqWzaNSScs5Hu7cLUs/xdvw09zbphWzSdB0UNs9rQG3ctkWjbaK+WKsXOpd/gxyWPY4fti1uhK5xFyaaLMOIrf+EhFnnKtJ+Z3pCE/uwRROE/Y74bWHXRZRZ5hB150sFmEYet09ZHPD/lVjtBF9zJcvlWh5CIh7xUviHqp3b/AAAAFQDypk12Poey0L35PgngF6g042NAbwAAAIACd/P1epZQXmtIWXkkFWhp4rQTSqz6YV/FpWCHM8bk7qr+4owhHrFkwS1cSPQyyTnCfNM5lorqJ2chjk1AeGr8OMo9GoUxLNSe0CtcCHjT6b2mfkWnqkSi//KwUq3oNUhkl9xZJls7kT0w6F+CncpPEMYseOb8h5UpZ2xVmAgZmwAAAIBYoLiugqeo39qUZQ0a7vQ3ydlmJ/EJzv1rjWRJ79or01wfkpb+jgBeiTHPeuCw2WTEBpKYkU4U8x5tUHb+kdN6TrABcvbn/kfgsoMZeb1rPaiDDM+93prkSI7hS2FKYDv6TIBsT4StmY/BZHfhTwjQUcW+yYJv7vlM9LeIlA4IEw== monty@speedy\nssh-dsa AAAAB3NzaC1kc3MAAACBAN2I6q4yjydSwEnhf45GPBDvj/MUjPBlTj3Buf+xunUtfdXSIpTDvasTVibEKhNrNkr0zkIe8hE5uOM3pHeSLRx9Tj8Txjn5RN3xsKhkqhS/j/GCPiDWRQnpfHPWHK7NxEMwbMv7Rato8YubVmSq9UodXSWytcSXZCTtQVZJvDMjAAAAFQCA+aVTTD9XcC7A575rcu0j75f2HwAAAIA8tdrsQoNV1AMde6r0iE8T8wkw9T9cA9bwK8sbIR3S81FG805bMdVanBfDBwfOTM/rbuGQoH4F8oqURor7njwARh5BLTFrpqSqSw6vTm30TJnRDUS7qrDG0xrzqk+RF5AXHHJ4MJKbjpUc2C3MHOo+rybjE1rJh9OWr9xG3oRroAAAAIAyN2Btf9fCJh2MhqPrtVCfSUzcE7qz/7XludszUwrWElsTfqXtSfRqiQybXSImVPz9DE+ZufOHGLMGolEi+ALRgLp4L7JDBld+Gga64HnAbg/jmDKN97CyFrRbmVbln/oFQFmDhLchGnERhRKQWOWwXKdOrDgGvDwHORsCffUVLw== mtaylor@qualinost\n\nssh-dsa AAAAB3NzaC1kc3MAAACBAN2I6q4yjydSwEnhf45GPBDvj/MUjPBlTj3Buf+xunUtfdXSIpTDvasTVibEKhNrNkr0zkIe8hE5uOM3pHeSLRx9Tj8Txjn5RN3xsKhkqhS/j/GCPiDWRQnpfHPWHK7NxEMwbMv7Rato8YubVmSq9UodXSWytcSXZCTtQVZJvDMjAAAAFQCA+aVTTD9XcC7A575rcu0j75f2HwAAAIA8tdrsQoNV1AMde6r0iE8T8wkw9T9cA9bwK8sbIR3S81FG805bMdVanBfDBwfOTM/rbuGQoH4F8oqURor7njwARh5BLTFrpqSqSw6vTm30TJnRDUS7qrDG0xrzqk+RF5AXHHJ4MJKbjpUc2C3MHOo+rybjE1rJh9OWr9xG3oRroAAAAIAyN2Btf9fCJh2MhqPrtVCfSUzcE7qz/7XludszUwrWElsTfqXtSfRqiQybXSImVPz9DE+ZufOHGLMGolEi+ALRgLp4L7JDBld+Gga64HnAbg/jmDKN97CyFrRbmVbln/oFQFmDhLchGnERhRKQWOWwXKdOrDgGvDwHORsCffUVLw== mtaylor@qualinost\n",
    ensure => 'present',
    require => File['mordredsshdir'],
  }

  file { 'mordredbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.bashrc',
      solaris => '/export/home/mordred/.bashrc',
      default => '/home/mordred/.bashrc',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'mordredbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.bash_logout',
      solaris => '/export/home/mordred/.bash_logout',
      default => '/home/mordred/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'mordredprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.profile',
      solaris => '/export/home/mordred/.profile',
      default => '/home/mordred/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'mordredbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.bazaar',
      solaris => '/export/home/mordred/.bazaar',
      default => '/home/mordred/.bazaar',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 755,
    ensure => 'directory',
    require => File['mordredhome'],
  }


  file { 'mordredbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/mordred/.bazaar/authentication.conf',
      solaris => '/export/home/mordred/.bazaar/authentication.conf',
      default => '/home/mordred/.bazaar/authentication.conf',
    },
    owner => 'mordred',
    group => 'mordred',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = mordred\n",
    ensure => 'present',
    require => File['mordredbazaardir'],
  }


  group { 'santosh-jodh-8':
    ensure => 'present'
  }

  user { 'santosh-jodh-8':
    ensure => 'present',
    comment => 'Santosh Jodh',
    home => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8',
      solaris => '/export/home/santosh-jodh-8',
      default => '/home/santosh-jodh-8',
    },
    shell => '/bin/bash',
    gid => 'santosh-jodh-8',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'santosh-jodh-8home':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8',
      solaris => '/export/home/santosh-jodh-8',
      default => '/home/santosh-jodh-8',
    },
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'santosh-jodh-8sshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.ssh',
      solaris => '/export/home/santosh-jodh-8/.ssh',
      default => '/home/santosh-jodh-8/.ssh',
    },
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 700,
    ensure => 'directory',
    require => File['santosh-jodh-8home'],
  }

  file { 'santosh-jodh-8keys':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.ssh/authorized_keys',
      solaris => '/export/home/santosh-jodh-8/.ssh/authorized_keys',
      default => '/home/santosh-jodh-8/.ssh/authorized_keys',
    },
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 640,
    content => "",
    ensure => 'present',
    require => File['santosh-jodh-8sshdir'],
  }

  file { 'santosh-jodh-8bashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.bashrc',
      solaris => '/export/home/santosh-jodh-8/.bashrc',
      default => '/home/santosh-jodh-8/.bashrc',
    },
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'santosh-jodh-8bash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.bash_logout',
      solaris => '/export/home/santosh-jodh-8/.bash_logout',
      default => '/home/santosh-jodh-8/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'santosh-jodh-8profile':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.profile',
      solaris => '/export/home/santosh-jodh-8/.profile',
      default => '/home/santosh-jodh-8/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'santosh-jodh-8bazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.bazaar',
      solaris => '/export/home/santosh-jodh-8/.bazaar',
      default => '/home/santosh-jodh-8/.bazaar',
    },
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 755,
    ensure => 'directory',
    require => File['santosh-jodh-8home'],
  }


  file { 'santosh-jodh-8bazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/santosh-jodh-8/.bazaar/authentication.conf',
      solaris => '/export/home/santosh-jodh-8/.bazaar/authentication.conf',
      default => '/home/santosh-jodh-8/.bazaar/authentication.conf',
    },
    owner => 'santosh-jodh-8',
    group => 'santosh-jodh-8',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = santosh-jodh-8\n",
    ensure => 'present',
    require => File['santosh-jodh-8bazaardir'],
  }


  group { 'soren':
    ensure => 'present'
  }

  user { 'soren':
    ensure => 'present',
    comment => 'Soren Hansen',
    home => $operatingsystem ? {
      Darwin => '/Users/soren',
      solaris => '/export/home/soren',
      default => '/home/soren',
    },
    shell => '/bin/bash',
    gid => 'soren',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'sorenhome':
    name => $operatingsystem ? {
      Darwin => '/Users/soren',
      solaris => '/export/home/soren',
      default => '/home/soren',
    },
    owner => 'soren',
    group => 'soren',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'sorensshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.ssh',
      solaris => '/export/home/soren/.ssh',
      default => '/home/soren/.ssh',
    },
    owner => 'soren',
    group => 'soren',
    mode => 700,
    ensure => 'directory',
    require => File['sorenhome'],
  }

  file { 'sorenkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.ssh/authorized_keys',
      solaris => '/export/home/soren/.ssh/authorized_keys',
      default => '/home/soren/.ssh/authorized_keys',
    },
    owner => 'soren',
    group => 'soren',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7bpJJzvwa4KKzxk9fyegkCUKKOA1gttDJdB+E2mllxcDkScYRYoFnwiq0kl1BwkNFRXj10pguhI/7O3escSvF3Di2Lw4haHR8my6yaz7jFlBbBw8+6j5RbIRnTORS5G4mH4LtAxToGomfJd9gxWpVMiqLa4V7Hg8K6CYRSSUOWzqs7Y/Hv13ASr8ZbaweB1ygVE8kbKuW2ILcqRrKYKaQDeh+aPqLsXDNhT2k2WLsTIqMTSKy70sHqyCjD2joRVBuTiqt1uaQqYCJWT8vuDvXsF0Lmi4tMjRF7GOuOKd0QsT5y8C8dLHWDfeBNQJv46dZE6UUHOfhucTM4w73zpXaw== soren@butch\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8YfXbgi0uNZEpOxLvzPdGgo5dAAjqVUGf+kU1bvxcZf3y7a2veDXOOnez4VGl6OC1bgeENW/5O2hKi0wUG3XMWp8uLVSupI6A8o+cBCu7MYzChMdgullBEh7Bz4cbvoMmQiWOZPPsZLTTrl7E6SJJ5jTTn8IsSkCp21m2Sr4b5SWj+Nw43NVtGYFtBBG/OoixlxcNutiSn7YjOH6CAVOhKpTNddwqECKBfxCdS2kYrMzJw8/QhA9FwJHoFt3PevuC4I/9ARlyZCsbOY+ENc2NtFXNVnF5m6tE/eDZFTt652pNPlldWAaVBzKDZ4CUi4HS3WDxGcVqhtaNawIV6sR8w== soren@intel\n\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyAtAccJ8ndh6wzq3vY1izHTdPh3kAKtjBK6P390ClIRBA3CfjKS6KaKSeGs1xZ4WZhOk9oz4d/+Ep7iOXLpUnYYjHm5bLD8o6jKAhKohoABzCyj3ONPNxvxvsvdahSPLONC6H1PlbhvTbn9UwEtZ//migJTATdLQEjXHaNhNJ8UZz9XtCf1Qv4YiYmyRId6h5N+OPNU4OmqlCZyanBXKN5jK1Kubq6SseY++74Y54ZPXVccGmJDTOfNBfM1nR0+f2Mq2iHR0a3PuJcGXFx/P4mIA0Knyh98W6esB9fG7/JVID2bGpJ6c91+AkL9fmwOpfWrk7rr13+iGiH2RTcmd0w== soren@lenny\n\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCGTnV3tEMvry4UruD6I23TW3L616ML8p15kdj4TYlcBUZvUDzPoT+QjinNw7Pm1C4dJk3xJJtvxshKSXF08QF88kWgtF6jSpp1ZwmDXKNnPRLAIT5pewubFHd5iwMFf371P2/kxIm37iAo45puTO0CL39dAKkw6L/F7M3ycFUgsIkik6oN9bX1X3Yu3e/Lv2hJ1LGN7K2nnQmLd9aFulpruM7iPtFt8qJ82ofJq2LGH931QsP1QonvJxonajo9wrEAfXTFENDwcoOD0Py+KXOddqb/1SJxbLwclDmHMX5bKA5K+R6GzzpDUEsDZYa1xhJpmOmlaBTxFGoQg/wtHUNf cardno:000500000063",
    ensure => 'present',
    require => File['sorensshdir'],
  }

  file { 'sorenbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.bashrc',
      solaris => '/export/home/soren/.bashrc',
      default => '/home/soren/.bashrc',
    },
    owner => 'soren',
    group => 'soren',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'sorenbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.bash_logout',
      solaris => '/export/home/soren/.bash_logout',
      default => '/home/soren/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'soren',
    group => 'soren',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'sorenprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.profile',
      solaris => '/export/home/soren/.profile',
      default => '/home/soren/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'soren',
    group => 'soren',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'sorenbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.bazaar',
      solaris => '/export/home/soren/.bazaar',
      default => '/home/soren/.bazaar',
    },
    owner => 'soren',
    group => 'soren',
    mode => 755,
    ensure => 'directory',
    require => File['sorenhome'],
  }


  file { 'sorenbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/soren/.bazaar/authentication.conf',
      solaris => '/export/home/soren/.bazaar/authentication.conf',
      default => '/home/soren/.bazaar/authentication.conf',
    },
    owner => 'soren',
    group => 'soren',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = soren\n",
    ensure => 'present',
    require => File['sorenbazaardir'],
  }


  group { 'ttx':
    ensure => 'present'
  }

  user { 'ttx':
    ensure => 'present',
    comment => 'Thierry Carrez',
    home => $operatingsystem ? {
      Darwin => '/Users/ttx',
      solaris => '/export/home/ttx',
      default => '/home/ttx',
    },
    shell => '/bin/bash',
    gid => 'ttx',
    groups => ['wheel','sudo','admin'],
    membership => 'minimum',
  }

  file { 'ttxhome':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx',
      solaris => '/export/home/ttx',
      default => '/home/ttx',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 644,
    ensure => 'directory',
  }
    
  
  file { 'ttxsshdir':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.ssh',
      solaris => '/export/home/ttx/.ssh',
      default => '/home/ttx/.ssh',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 700,
    ensure => 'directory',
    require => File['ttxhome'],
  }

  file { 'ttxkeys':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.ssh/authorized_keys',
      solaris => '/export/home/ttx/.ssh/authorized_keys',
      default => '/home/ttx/.ssh/authorized_keys',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAz4Mu4IhAg3/AY4fCnAomOAJIkJS4YnTlTXiIikUIqS/R\n116Do8CxKJjwM8MPc0i/n7zpYKTgAEJ4qbgaWG/sGokUw8ZsJ+6WfcSLGszU/6qd7+s3BEqUyStTsPrV\nmK7gnBroub+WaLk0/BKfMR+Mx3MJY/wPisuqdHK8kViQR09/qSFuuPgSZsYw2GuLM1Ul4h3vC4BaAbQV\ne+1AKq7/Yz+ARK1IDr7ZqdK7T1f/G01Vi1J03Q0YCeB7JFvUFtwPm561yNOWXxQuJMQ9Z1CDunRpLiil\nRN8WrM97ETF9i+XKCavb54UxzDz1SEwyhSouTdSFRc1A3jZMloZrvr2hLQ== ttx@cassini\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIF2INBeJdT3nT3+3yac+DGRQVN7wPv/GTb/OPDocQhfGMeQP7JwSURiv1nrXGbbjzuip7l7vRJs4u4NqXkUi0GFj1aLBpUm2Z1NFFDn4cuZ5KCYX6rjVrDYIpj4OlOyzt9YGONvvH/dB2GHw8kYbN50OalFWQCS0TVzj9SQbO47B/TPdtLnh116yEP5AXZZUGgl+q533/x8+nxAxJKA9iAk3mSswl67gXc4pRo84pjwpx+R/52ha6RfmLkoNAEOqtr5MGx5gyW+WXsoLJBl2bjcfzYoQI7gPWRIn+rtCnDFi762TS54zstXxR1ww+ppmqHk04l2oprNoI0wr00Fsl ttx@stardust\n",
    ensure => 'present',
    require => File['ttxsshdir'],
  }

  file { 'ttxbashrc':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.bashrc',
      solaris => '/export/home/ttx/.bashrc',
      default => '/home/ttx/.bashrc',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    source => "/etc/skel/.bashrc",
    replace => 'false',
    ensure => 'present',
  }

  file { 'ttxbash_logout':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.bash_logout',
      solaris => '/export/home/ttx/.bash_logout',
      default => '/home/ttx/.bash_logout',
    },
    source => "/etc/skel/.bash_logout",
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'ttxprofile':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.profile',
      solaris => '/export/home/ttx/.profile',
      default => '/home/ttx/.profile',
    },
    source => "/etc/skel/.profile",
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    replace => 'false',
    ensure => 'present',
  }

  file { 'ttxbazaardir':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.bazaar',
      solaris => '/export/home/ttx/.bazaar',
      default => '/home/ttx/.bazaar',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 755,
    ensure => 'directory',
    require => File['ttxhome'],
  }


  file { 'ttxbazaarauth':
    name => $operatingsystem ? {
      Darwin => '/Users/ttx/.bazaar/authentication.conf',
      solaris => '/export/home/ttx/.bazaar/authentication.conf',
      default => '/home/ttx/.bazaar/authentication.conf',
    },
    owner => 'ttx',
    group => 'ttx',
    mode => 640,
    content => "[Launchpad]\nhost = .launchpad.net\nscheme = ssh\nuser = ttx\n",
    ensure => 'present',
    require => File['ttxbazaardir'],
  }


}
  