class mysql::packages::server($version = "5.5") {
  package { "mysql-server-${version}":
    ensure => present,
    alias  => "mysql-server";
  }
}
