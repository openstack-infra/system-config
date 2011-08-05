class gerrit($canonicalweburl='',
             $openidssourl="https://login.launchpad.net/+openid",
             $email='',
             $commentlinks = [ { name => 'launchpad',
                               match => '([Bb]ug|[Ll][Pp])\\s*[#:]?\\s*(\\d+)',
                               link => 'https://code.launchpad.net/bugs/$2' } ]
               ) {
               
  if $gerrit_installed {
    #notice('Gerrit is installed')

    file { '/home/gerrit2/review_site/etc/replication.config':
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source => 'puppet:///modules/gerrit/replication.config',
      replace => 'true',
    }

    file { '/home/gerrit2/review_site/etc/gerrit.config':
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      content => template('gerrit/gerrit.config.erb'),
      replace => 'true',
    }

    file { '/home/gerrit2/review_site/hooks/change-merged':
      owner => 'root',
      group => 'root',
      mode => 555,
      ensure => 'present',
      source => 'puppet:///modules/gerrit/change-merged',
      replace => 'true',
    }

  } else {
    notice('Gerrit is not installed')
  }

}
