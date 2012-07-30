class generic::mysql::packages::client($version = "5.5") {
  package { "mysql-client-${version}":
    ensure => latest,
    alias  => "mysql-client";
  }
  package { "libmysqlclient-dev":
    ensure => latest;
  }
}
