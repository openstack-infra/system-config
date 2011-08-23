define cowbuilder::cow($distro = ubuntu, $bits = 64) {

  $has_cow = "/usr/bin/test -d /var/cache/pbuilder/base-$name.cow"
  case $bits {
    32: {
      $env = ["ARCH=i386", "DIST=$name","APTCACHEHARDLINK=no","HOME=/root"]
    }
    64: {
      $env = ["DIST=$name","APTCACHEHARDLINK=no","HOME=/root"]
  }

  case $distro {
    ubuntu: {
      exec { "Add base cow for $name":
        environment => $env,
        command => "git-pbuilder create --distribution $name --components 'main universe'  --hookdir /var/cache/pbuilder/hook.d/ --mirror='http://us.archive.ubuntu.com/ubuntu/'",
        path => "/usr/sbin:/usr/bin:/sbin:/bin",
        user => root,
        group => root,
        timeout => 0,
        logoutput => on_failure,
        unless => "$has_cow",
      }
    }
    debian: {
      exec { "Add base cow for $name":
        environment => $env,
        command => "git-pbuilder create --distribution $name --mirror ftp://ftp.us.debian.org/debian/ --debootstrapopts '--keyring=/usr/share/keyrings/debian-archive-keyring.gpg' --hookdir /var/cache/pbuilder/hook.d/",
        path => "/usr/sbin:/usr/bin:/sbin:/bin",
        user => root,
        group => root,
        timeout => 0,
        logoutput => on_failure,
        unless => "$has_cow",
      }
    }
  }
  exec { "Update base cow for $name":
    environment => $env,
    command => "git-pbuilder update --hookdir /var/cache/pbuilder/hook.d/",
    path => "/usr/sbin:/usr/bin:/sbin:/bin",
    user => root,
    group => root,
    logoutput => on_failure,
    onlyif => "$has_cow",
  }
}
