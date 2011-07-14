class sudoers {
  group { 'wheel':
    ensure => 'present'
  }
  group { 'sudo':
    ensure => 'present'
  }
  group { 'admin':
    ensure => 'present'
  }

  file { '/etc/sudoers':
    owner => 'root',
    group => 'root',
    mode => 440,
    ensure => 'present',
    source => [
      "puppet:///modules/sudoers/sudoers.$operatingsystem",
      "puppet:///modules/sudoers/sudoers"
      ],
    replace => 'true',
  }

  file { '/etc/alternatives/editor':
    ensure => link,
    target => "/usr/bin/vim.basic",
  }
}
