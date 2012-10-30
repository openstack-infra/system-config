# == Define: buildsource
#
# define to build from source using ./configure && make && make install.
#
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
    creates => $creates,
    before  => exec["make in ${dir}"],
  }

  exec { "make in ${dir}":
    command => 'make',
    path    => '/usr/bin:/bin',
    user    => $user,
    cwd     => $dir,
    creates => $creates,
    before  => exec["make install in ${dir}"],
  }

  exec { "make install in ${dir}":
    command => 'make install',
    path    => '/usr/bin:/bin',
    user    => $user,
    cwd     => $dir,
    creates => $creates,
  }
}
