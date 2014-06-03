# graphite::storage
#
# Handles adding storage schema rules
#
define graphite::storage (
  $pattern,
  $retentions,
  $order = 10
) {

  file_fragment { "${$name}_${::fqdn}":
    tag     => "carbon_cache_storage_config_${::fqdn}",
    content => template('graphite/storage-schemas-item.erb'),
    order   => $order
  }
}
