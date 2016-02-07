# == define: openstack_project::gpg_key
#
define openstack_project::gpg_key (
  $keyid
) {
  exec { "fetch ${keyid}":
    command => "gpg --recv-keys ${keyid}",
    unless  => "gpg --list-keys ${keyid}",
    user    => 'root',
    path    => '/bin:/usr/bin',
  }
}
