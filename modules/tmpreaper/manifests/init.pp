class tmpreaper() {
   package { 'tmpreaper':
      ensure => present,
   }

   file { 'tmpreaper-cron.daily':
      name => '/etc/cron.daily/tmpreaper',
      ensure => 'present',
      owner => 'root',
      group => 'root',
      mode => 755,
      source => 'puppet:///modules/tmpreaper/tmpreaper-cron.daily',
   }

   file { 'tmpreaper.conf':
      name => '/etc/tmpreaper.conf',
      ensure => 'present',
      owner => 'root',
      group => 'root',
      mode => 644,
      source => 'puppet:///modules/tmpreaper/tmpreaper.conf',
   }
}
