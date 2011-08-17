define cowbuilder::debgpg {

  exec { "Add gpg public key $name":
    command => "gpg --keyserver keys.gnupg.net --recv-key $name",
    path => "/usr/sbin:/usr/bin:/sbin:/bin",
    user => root,
    group => root,
    logoutput => on_failure,
    unless => "/usr/bin/gpg --list-keys $name >/dev/null 2>&1",
  }
}
