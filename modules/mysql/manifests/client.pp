class mysql::client {
  package { ["mysql-client"]:
    ensure => latest;
  }
}
