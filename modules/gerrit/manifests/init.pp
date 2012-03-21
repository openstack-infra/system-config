class gerrit($canonicalweburl='',
$openidssourl="https://login.launchpad.net/+openid",
$email='',
$github_projects = [],
$commentlinks = [ { name => 'changeid',
                  match => '(I[0-9a-f]{8,40})',
                  link => '#q,$1,n,z' },

                  { name => 'launchpad',
                  match => '([Bb]ug|[Ll][Pp])[\\s#:]*(\\d+)',
                  link => 'https://code.launchpad.net/bugs/$2' },

                  { name => 'blueprint',
                  match => '([Bb]lue[Pp]rint|[Bb][Pp])[\\s#:]*([A-Za-z0-9\\-]+)',
                  link => 'https://blueprints.launchpad.net/openstack/?searchtext=$2' },

                  ],
$logo
  ) {

  user { "gerrit2":
    ensure => present,
    comment => "Gerrit",
    home => "/home/gerrit2",
    shell => "/bin/bash",
    gid => "gerrit2",
    managehome => true,
    require => Group["gerrit2"]
  }

  group { "gerrit2":
    ensure => present
  }

  package { "gitweb":
    ensure => latest
  }
  package { "python-dev":
    ensure => latest
  }
  package { "python-pip":
    ensure => latest,
    require => Package[python-dev]
  }
  package { "github2":
    ensure => latest,
    provider => pip,
    require => Package[python-pip]
  }

  cron { "gerritupdateci":
    user => gerrit2,
    minute => "*/15",
    command => 'sleep $((RANDOM\%60)) && cd /home/gerrit2/openstack-ci && /usr/bin/git pull -q origin master'
  }

  cron { "gerritsyncusers":
    user => gerrit2,
    minute => "*/15",
    command => 'sleep $((RANDOM\%60+60)) && cd /home/gerrit2/openstack-ci && python gerrit/update_gerrit_users.py'
  }

  cron { "gerritclosepull":
    user => gerrit2,
    minute => "*/5",
    command => 'sleep $((RANDOM\%60+90)) && cd /home/gerrit2/openstack-ci && python gerrit/close_pull_requests.py'
  }

  cron { "expireoldreviews":
    user => gerrit2,
    hour => 6,
    minute => 3,
    command => 'cd /home/gerrit2/openstack-ci && python gerrit/expire_old_reviews.py'
  }

  cron { "gerrit_repack":
    user => gerrit2,
    weekday => 0,
    hour => 4,
    minute => 7,
    command => 'find /home/gerrit2/review_site/git/ -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \;',
    environment => "PATH=/usr/bin:/bin:/usr/sbin:/sbin",
  }

  file { "/var/log/gerrit":
    ensure => "directory",
    owner => 'gerrit2'
  }

# directory creation hacks until we can automate gerrit installation

  file { "/home/gerrit2/review_site":
    ensure => "directory",
    owner => "gerrit2",
    require => User["gerrit2"]
  }

  file { "/home/gerrit2/review_site/etc":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  file { "/home/gerrit2/review_site/hooks":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  file { "/home/gerrit2/review_site/static":
    ensure => "directory",
    owner => "gerrit2",
    require => File["/home/gerrit2/review_site"]
  }

  file { '/home/gerrit2/github.config':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    content => template('gerrit/github.config.erb'),
    replace => 'true',
    require => User["gerrit2"]
  }

  file { '/home/gerrit2/review_site/static/title.png':
    ensure => 'present',
    source => 'puppet:///modules/gerrit/${logo}',
  }

  file { '/home/gerrit2/review_site/static/openstack-page-bkg.jpg':
    ensure => 'present',
    source => 'puppet:///modules/gerrit/openstack-page-bkg.jpg'
  }

  file { '/home/gerrit2/review_site/etc/GerritSite.css':
    ensure => 'present',
    source => 'puppet:///modules/gerrit/GerritSite.css'
  }

  file { '/home/gerrit2/review_site/etc/GerritSiteHeader.html':
    ensure => 'present',
    source => 'puppet:///modules/gerrit/GerritSiteHeader.html'
  }

  file { '/home/gerrit2/review_site/etc/replication.config':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/gerrit/replication.config',
    replace => 'true',
    require => File["/home/gerrit2/review_site/etc"]
  }

  file { '/home/gerrit2/review_site/etc/gerrit.config':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    content => template('gerrit/gerrit.config.erb'),
    replace => 'true',
    require => File["/home/gerrit2/review_site/etc"]
  }

  file { '/home/gerrit2/review_site/hooks/change-merged':
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => 'present',
    source => 'puppet:///modules/gerrit/change-merged',
    replace => 'true',
    require => File["/home/gerrit2/review_site/hooks"]
  }

  file { '/home/gerrit2/review_site/hooks/patchset-created':
    owner => 'root',
    group => 'root',
    mode => 555,
    ensure => 'present',
    source => 'puppet:///modules/gerrit/patchset-created',
    replace => 'true',
    require => File["/home/gerrit2/review_site/hooks"]
  }

  file { '/home/gerrit2/review_site/static/echosign-cla.html':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    source => 'puppet:///modules/gerrit/echosign-cla.html',
    replace => 'true',
    require => File["/home/gerrit2/review_site/static"]
  }

}
