# Define that adds a host to a cacti installation.
# Takes the fqdn of the host to be added as a parameter.
define openstack_project::cacti_device(
  $hostname
){
  exec { "cacti_create_${hostname}":
    command => "/usr/local/bin/create_graphs.sh ${hostname}",
    require => Exec['cacti_import_xml']
  }
}
