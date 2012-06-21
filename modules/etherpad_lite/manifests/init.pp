# define to manage a git repo (should replace with vcsrepo module)
define git_repo (
  $repo,
  $dest,
  $user   = 'root',
  $branch = 'master',
  $clone_only = undef
) {

  if $clone_only == 'true' {
    $checkout_condition = "false"
  }
  else {
    $checkout_condition = "test -d ${dest}"
  }

# if we already have the git repo the pull updates
  exec { "update_${title}":
    command => "git pull --ff-only origin ${branch}",
    cwd     => $dest,
    path    => '/bin:/usr/bin',
    user    => $user,
    onlyif  => $checkout_condition,
    before  => Exec["clone_${title}"],
  }

# otherwise get a new clone of it
  exec { "clone_${title}":
    command => "git clone ${repo} ${dest}",
    path    => '/bin:/usr/bin',
    user    => $user,
    onlyif  => "test ! -d ${dest}",
  } ->

  exec { "checkout_${title}_${branch}":
    command => "git checkout ${branch}",
    path    => '/bin:/usr/bin',
    cwd     => $dest,
    user    => $user,
    subscribe => Exec["clone_${title}"],
    refreshonly => true,
    onlyif  => "test -d ${dest}"
  }

}

# define to build from source using ./configure && make && make install.
define buildsource(
  $dir     = $title,
  $user    = 'root',
  $creates = '/nonexistant/file'
) {

  exec { "./configure in ${dir}":
    command => './configure',
    path    => "/usr/bin:/bin:/usr/local/bin:${dir}",
    user    => $user,
    cwd     => $dir,
    creates => $creates
  } ->

  exec { "make in ${dir}":
    command => 'make',
    path    => '/usr/bin:/bin',
    user    => $user,
    cwd     => $dir,
    creates => $creates
  } ->

  exec { "make install in ${dir}":
    command => 'make install',
    path    => '/usr/bin:/bin',
    user    => $user,
    cwd     => $dir,
    creates => $creates
  }

}

# Class to install etherpad lite. Puppet acts a lot like a package manager
# through this class.
#
# To use etherpad lite you will want the following includes:
# include etherpad_lite
# include etherpad_lite::mysql # necessary to use mysql as the backend
# include etherpad_lite::site # configures etherpad lite instance
# include etherpad_lite::nginx # will add reverse proxy on localhost
# The defaults for all the classes should just work (tm)
#
# You will need to have a file at
# /root/secret-files/etherpad-lite_settings.json on the host that is puppet
# master or running puppet apply. This file should contain the settings for
# etherpad-lite. A template for that settings file can be found at:
# https://raw.github.com/Pita/etherpad-lite/master/settings.json.template
#
class etherpad_lite (
  $ep_user          = 'eplite',
  $base_log_dir     = '/var/log',
  $base_install_dir = '/opt/etherpad-lite'
) {

  user { $ep_user:
    shell   => '/sbin/nologin',
    home    => "${base_log_dir}/${ep_user}",
    system  => true,
    gid     => $ep_user,
    require => Group[$ep_user]
  }

  group { $ep_user:
    ensure => present
  }

  # Below is what happens when you treat puppet as a package manager.
  # This is probably bad, but it works and you don't need to roll .debs.
  file { "${base_install_dir}":
    ensure => directory,
    group  => $ep_user,
    mode   => 0664,
  }

  git_repo { 'nodejs_repo':
    repo       => 'https://github.com/joyent/node.git',
    dest       => "${base_install_dir}/nodejs",
    branch     => 'v0.6.16-release',
    clone_only => 'true',
    require    => Package['git']
  }

  package { ['gzip',
             'curl',
             'python',
             'libssl-dev',
             'pkg-config',
             'abiword',
             'build-essential']:
    ensure => present
  }

  package { ['nodejs', 'npm']:
    ensure => purged
  }

  buildsource { "${base_install_dir}/nodejs":
    creates => '/usr/local/bin/node',
    require => [Package['gzip'],
                Package['curl'],
                Package['python'],
                Package['libssl-dev'],
                Package['pkg-config'],
                Package['build-essential'],
                Git_repo['nodejs_repo']]
  }

  git_repo { 'etherpad_repo':
    repo       => 'https://github.com/Pita/etherpad-lite.git',
    dest       => "${base_install_dir}/etherpad-lite",
    user       => $ep_user,
    clone_only => 'true',
    require    => Package['git']
  }

  exec { 'install_etherpad_dependencies':
    command     => './bin/installDeps.sh',
    path        => "/usr/bin:/bin:/usr/local/bin:${base_install_dir}/etherpad-lite",
    user        => $ep_user,
    cwd         => "${base_install_dir}/etherpad-lite",
    environment => "HOME=${base_log_dir}/${ep_user}",
    require     => [Git_repo['etherpad_repo'],
                    Buildsource["${base_install_dir}/nodejs"]],
    before      => File["${base_install_dir}/etherpad-lite/settings.json"],
    creates     => "${base_install_dir}/etherpad-lite/node_modules"
  }

  file { '/etc/init/etherpad-lite.conf':
    ensure  => 'present',
    content => template('etherpad_lite/upstart.erb'),
    replace => 'true',
    owner   => 'root',
  }

  file { '/etc/init.d/etherpad-lite':
    ensure => link,
    target => '/lib/init/upstart-job'
  }

  file { "${base_log_dir}/${ep_user}":
    ensure => directory,
    owner  => $ep_user,
  }
  # end package management ugliness

}
