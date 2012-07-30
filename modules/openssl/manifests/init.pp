class openssl {
  package { ["openssl", "ssl-cert"]:
    ensure => present;
  }
}
