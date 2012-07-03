# Install and maintain Gerrit Code Review.
# params:
#   virtual_hostname:
#     used in the Apache virtual host, eg., review.example.com
#   canonicalweburl:
#     Used in the Gerrit config to generate links, eg., https://review.example.com/
#   ssl_cert_file:
#   ssl_key_file:
#     Used in the Apache virtual host to specify the SSL cert and key files.
#   ssl_chain_file:
#     Optional, if you have an intermediate cert Apache should serve.
#   openidssourl:
#     The URL to use for OpenID in SSO mode.
#   email:
#     The email address Gerrit should use when sending mail.
#   database_poollimit:
#   container_heaplimit:
#   core_packedgitopenfiles:
#   core_packedgitlimit:
#   core_packedgitwindowsize:
#   sshd_threads:
#   httpd_acceptorthreads:
#   httpd_minthreads:
#   httpd_maxthreads:
#   httpd_maxwait:
#     Gerrit configuration options; see Gerrit docs.
#   commentlinks:
#     A list of regexes Gerrit should hyperlink.
#   logo:
#     The name of the image file for the site header.
#   war:
#     The URL of the Gerrit WAR that should be downloaded and installed.
#     Note that only the final component is used for comparing to the most
#     recently installed WAR.  In other words, if you update the war from:
#
#       http://ci.openstack.org/tarballs/gerrit.war
#     to:
#       http://somewhereelse.example.com/gerrit.war
#
#     Gerrit won't be updated unless you delete gerrit.war from
#     ~gerrit2/gerrit-wars.  But if you change the URL from:
#
#       http://ci.openstack.org/tarballs/gerrit-2.2.2.war
#     to:
#       http://ci.openstack.org/tarballs/gerrit-2.3.0.war
#     Gerrit will be upgraded on the next puppet run.

# TODO: move closing github pull requests to another module
# TODO: move gerritbot configuration to another module
# TODO: move apache configuration to another module
# TODO: move mysql configuration to another module
# TODO: make more gerrit options configurable here
# TODO: launchpadlib creds for user sync script

class gerrit($virtual_hostname='',
      $canonicalweburl='',
      $ssl_cert_file='',
      $ssl_key_file='',
      $ssl_chain_file='',
      $openidssourl="https://login.launchpad.net/+openid",
      $email='',
      $database_poollimit='',
      $container_heaplimit='',
      $core_packedgitopenfiles='',
      $core_packedgitlimit='',
      $core_packedgitwindowsize='',
      $sshd_threads='',
      $httpd_acceptorthreads='',
      $httpd_minthreads='',
      $httpd_maxthreads='',
      $httpd_maxwait='',
      $github_projects = [],
      $upstream_projects = [],
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
      $logo,
      $war,
      $script_user,
      $script_key_file,
      $script_site,
      $enable_melody = 'false',
      $melody_session = 'false'
  ) {

  # Set this to true to disable cron jobs and replication, which can
  # interfere with testing.
  $testmode = false

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

  $packages = ["gitweb",
               "python-dev",
	       "openjdk-6-jre-headless",
	       "mysql-server",
	       "python-mysqldb",      # for launchpad sync script
	       "python-openid",       # for launchpad sync script
	       "python-launchpadlib", # for launchpad sync script
	       "apache2"]

  package { $packages:
    ensure => present,
  }

  package { "python-pip":
    ensure => present,
    require => Package[python-dev]
  }

  package { "PyGithub":
    ensure => latest,  # okay to use latest for pip
    provider => pip,
    require => Package[python-pip]
  }

  # Skip cron jobs if we're in test mode
  if ($testmode == false) {

    cron { "gerritsyncusers":
      user => gerrit2,
      minute => "*/15",
      command => "sleep $((RANDOM\%60+60)) && python /usr/local/gerrit/scripts/update_gerrit_users.py ${script_user} ${script_key_file} ${script_site}",
      require => File['/usr/local/gerrit/scripts'],
    }

    cron { "gerritclosepull":
      user => gerrit2,
      minute => "*/5",
      command => 'sleep $((RANDOM\%60+90)) && python /usr/local/gerrit/scripts/close_pull_requests.py',
      require => File['/usr/local/gerrit/scripts'],
    }

    cron { "expireoldreviews":
      user => gerrit2,
      hour => 6,
      minute => 3,
      command => "python /usr/local/gerrit/scripts/expire_old_reviews.py ${script_user} ${script_key_file}",
      require => File['/usr/local/gerrit/scripts'],
    }

    cron { "gerrit_repack":
      user => gerrit2,
      weekday => 0,
      hour => 4,
      minute => 7,
      command => 'find /home/gerrit2/review_site/git/ -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \;',
      environment => "PATH=/usr/bin:/bin:/usr/sbin:/sbin",
    }

    cron { "removedbdumps":
      user => gerrit2,
      hour => 5,
      minute => 1,
      command => 'find /home/gerrit2/dbupdates/ -name "*.sql.gz" -mtime +30 -exec rm -f {} \;',
      environment => "PATH=/usr/bin:/bin:/usr/sbin:/sbin",
    }

    cron { "gerritfetchremotes":
      user => gerrit2,
      minute => "*/30",
      command => 'sleep $((RANDOM\%60+90)) && python /usr/local/gerrit/scripts/fetch_remotes.py',
      require => File['/usr/local/gerrit/scripts'],
    }

    file { "/usr/local/gerrit/gerritbot":
      owner => 'root',
      group => 'root',
      mode => 555,
      ensure => 'present',
      source => 'puppet:///modules/gerrit/gerritbot',
    }

    file { "/etc/init.d/gerritbot":
      owner => 'root',
      group => 'root',
      mode => 555,
      ensure => 'present',
      source => 'puppet:///modules/gerrit/gerritbot.init',
      require => File['/usr/local/gerrit/gerritbot'],
    }

    service { 'gerritbot':
      name       => 'gerritbot',
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require => File['/etc/init.d/gerritbot'],
      subscribe => [ File["/usr/local/gerrit/gerritbot"] ],
    }

  } # testmode==false

  file { "/var/log/gerrit":
    ensure => "directory",
    owner => 'gerrit2'
  }

  # Prepare gerrit directories.  Even though some of these would be created
  # by the init command, we can go ahead and create them now and populate them.
  # That way the config files are already in place before init runs.

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

  file { "/home/gerrit2/review_site/bin":
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

  file { '/home/gerrit2/remotes.config':
    owner => 'root',
    group => 'root',
    mode => 444,
    ensure => 'present',
    content => template('gerrit/remotes.config.erb'),
    replace => 'true',
    require => User["gerrit2"]
  }

  file { '/home/gerrit2/review_site/static/title.png':
    ensure => 'present',
    source => "puppet:///modules/gerrit/${logo}",
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

  # Skip replication if we're in test mode
  if ($testmode == false) {
    file { '/home/gerrit2/review_site/etc/replication.config':
      owner => 'root',
      group => 'root',
      mode => 444,
      ensure => 'present',
      source => 'puppet:///modules/gerrit/replication.config',
      replace => 'true',
      require => File["/home/gerrit2/review_site/etc"]
    }
  }

  # Gerrit sets these permissions in 'init'; don't fight them.
  file { '/home/gerrit2/review_site/etc/gerrit.config':
    owner => 'gerrit2',
    group => 'gerrit2',
    mode => 644,
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

  # Secret files.
  # TODO: move the first two into other modules since they aren't for gerrit.
  # TODO: move secure.config to a puppet master

  file { '/home/gerrit2/github.secure.config':
    owner => 'root',
    group => 'gerrit2',
    mode => 440,
    ensure => 'present',
    source => 'file:///root/secret-files/github.secure.config',
    replace => 'true',
    require => User['gerrit2']
  }

  file { '/home/gerrit2/gerritbot.config':
    owner => 'root',
    group => 'gerrit2',
    mode => 440,
    ensure => 'present',
    source => 'file:///root/secret-files/gerritbot.config',
    replace => 'true',
    require => User['gerrit2']
  }

  # Gerrit sets these permissions in 'init'; don't fight them.  If
  # these permissions aren't set correctly, gerrit init will write a
  # new secure.config file and lose the mysql password.
  file { '/home/gerrit2/review_site/etc/secure.config':
    owner => 'gerrit2',
    group => 'gerrit2',
    mode => 600,
    ensure => 'present',
    source => 'file:///root/secret-files/secure.config',
    replace => 'true',
    require => File["/home/gerrit2/review_site/etc"]
  }

# Set up MySQL.
# We should probably have or use a puppet module to manage mysql, and then
# use that to satisfy the requirements that gerrit has.

  exec { "gerrit-mysql":
    creates => "/var/lib/mysql/reviewdb/",
    command => "/usr/bin/mysql --defaults-file=/etc/mysql/debian.cnf -e \"\
      CREATE USER 'gerrit2'@'localhost' IDENTIFIED BY '`grep password /home/gerrit2/review_site/etc/secure.config |cut -d= -f2|sed -e 's/ //'`';\
      CREATE DATABASE reviewdb;\
      ALTER DATABASE reviewdb charset=latin1;\
      GRANT ALL ON reviewdb.* TO 'gerrit2'@'localhost';\
      FLUSH PRIVILEGES;\"",
    require => [File['/home/gerrit2/review_site/etc/secure.config'], Package["mysql-server"]],
  }

  file { "/etc/mysql/my.cnf":
    source => 'puppet:///modules/gerrit/my.cnf',
    owner => 'root',
    group => 'root',
    ensure => 'present',
    replace => 'true',
    mode => 444,
    require => Package["mysql-server"],
  }

# Set up apache.  This should also be a separate, generalized module.

  file { "/etc/apache2/sites-available/gerrit":
    content => template('gerrit/gerrit.vhost.erb'),
    owner => 'root',
    group => 'root',
    ensure => 'present',
    replace => 'true',
    mode => 444,
    require => Package["apache2"],
  }

  file { "/etc/apache2/sites-enabled/gerrit":
    ensure => link,
    target => '/etc/apache2/sites-available/gerrit',
    require => [
      File['/etc/apache2/sites-available/gerrit'],
      File['/etc/apache2/mods-enabled/ssl.conf'],
      File['/etc/apache2/mods-enabled/ssl.load'],
      File['/etc/apache2/mods-enabled/rewrite.load'],
      File['/etc/apache2/mods-enabled/proxy.conf'],
      File['/etc/apache2/mods-enabled/proxy.load'],
      File['/etc/apache2/mods-enabled/proxy_http.load'],
    ],
  }

  file { '/etc/apache2/sites-enabled/000-default':
    require => File['/etc/apache2/sites-available/gerrit'],
    ensure => absent,
  }

  file { '/etc/apache2/mods-enabled/ssl.conf':
    target => '/etc/apache2/mods-available/ssl.conf',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/ssl.load':
    target => '/etc/apache2/mods-available/ssl.load',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/rewrite.load':
    target => '/etc/apache2/mods-available/rewrite.load',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/proxy.conf':
    target => '/etc/apache2/mods-available/proxy.conf',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/proxy.load':
    target => '/etc/apache2/mods-available/proxy.load',
    ensure => link,
    require => Package['apache2'],
  }

  file { '/etc/apache2/mods-enabled/proxy_http.load':
    target => '/etc/apache2/mods-available/proxy_http.load',
    ensure => link,
    require => Package['apache2'],
  }

  exec { "gracefully restart apache":
    subscribe => [ File["/etc/apache2/sites-available/gerrit"]],
    refreshonly => true,
    path => "/bin:/usr/bin:/usr/sbin",
    command => "apache2ctl graceful",
  }

  # Install Gerrit itself.

  # The Gerrit WAR is specified as a url like 'http://ci.openstack.org/tarballs/gerrit-2.2.2-363-gd0a67ce.war'
  # Set $basewar so that we can work with filenames like gerrit-2.2.2-363-gd0a67ce.war'.

  if $war =~ /.*\/(.*)/ {
    $basewar = $1
  } else {
    $basewar = $war
  }

  # This directory is used to download and cache gerrit war files.
  # That way the download and install steps are kept separate.
  file { "/home/gerrit2/gerrit-wars":
    ensure => "directory",
    require => User["gerrit2"]
  }

  # If we don't already have the specified WAR, download it.
  exec { "download:$war":
    command => "/usr/bin/wget $war -O /home/gerrit2/gerrit-wars/$basewar",
    creates => "/home/gerrit2/gerrit-wars/$basewar",
    require => File["/home/gerrit2/gerrit-wars"],
  }

  # If gerrit.war isn't the same as $basewar, install it.
  file { "/home/gerrit2/review_site/bin/gerrit.war":
    source => "file:///home/gerrit2/gerrit-wars/$basewar",
    require => Exec["download:$war"],
    ensure => present,
    replace => 'true',
    # user, group, and mode have to be set this way to avoid retriggering gerrit-init on every run
    # because gerrit init sets them this way
    owner => 'gerrit2',
    group => 'gerrit2',
    mode => 644,
  }

  # If gerrit.war was just installed, run the Gerrit "init" command.
  # Stop is included here because it may not be running or the init
  # script may not exist, and in those cases, we don't care if it fails.
  # Running the init script as the gerrit2 user _does_ work.
  exec { "gerrit-init":
    user => 'gerrit2',
    command => "/etc/init.d/gerrit stop; /usr/bin/java -jar /home/gerrit2/review_site/bin/gerrit.war init -d /home/gerrit2/review_site --batch --no-auto-start",
    subscribe => File["/home/gerrit2/review_site/bin/gerrit.war"],
    refreshonly => true,
    require => [Package["openjdk-6-jre-headless"],
                User["gerrit2"],
		Exec["gerrit-mysql"],
                File["/etc/mysql/my.cnf"],  # For innodb default tables
                File["/home/gerrit2/review_site/etc/gerrit.config"],
                File["/home/gerrit2/review_site/etc/secure.config"]],
    notify => Exec["gerrit-start"],
  }

  # Symlink the init script.
  file { "/etc/init.d/gerrit":
    ensure => link,
    target => '/home/gerrit2/review_site/bin/gerrit.sh',
    require => Exec['gerrit-init'],
  }

  # The init script requires the path to gerrit to be set.
  file { "/etc/default/gerritcodereview":
    source => 'puppet:///modules/gerrit/gerritcodereview.default',
    ensure => present,
    replace => 'true',
    owner => 'root',
    group => 'root',
    mode => 444,
  }

  # Make sure the init script starts on boot.
  file { ['/etc/rc0.d/K10gerrit',
          '/etc/rc1.d/K10gerrit',
          '/etc/rc2.d/S90gerrit',
          '/etc/rc3.d/S90gerrit',
          '/etc/rc4.d/S90gerrit',
          '/etc/rc5.d/S90gerrit',
          '/etc/rc6.d/K10gerrit']:
    ensure => link,
    target => '/etc/init.d/gerrit',
    require => File['/etc/init.d/gerrit'],
  }

  exec { "gerrit-start":
      command => '/etc/init.d/gerrit start',
      require => File['/etc/init.d/gerrit'],
      refreshonly => true,
  }

  file { '/usr/local/gerrit':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
  }

  file { '/usr/local/gerrit/scripts':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    require => File['/usr/local/gerrit'],
    source => [
                "puppet:///modules/gerrit/scripts",
              ],
  }
}
