# Define that adds a host to a cacti installation.
# Takes the fqdn of the host as the namevar for this define.
define openstack_project::cacti_device()
{
  exec { "cacti_create_${name}":
    command => "/usr/local/bin/create_graphs.sh ${name}",
    require => Exec['cacti_import_xml']
  }
}
