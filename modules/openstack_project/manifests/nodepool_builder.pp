# == Class: openstack_project::nodepool_builder
#
class openstack_project::nodepool_builder(
) {
  class { 'nodepool::builder':
      $statsd_host = undef,
  $image_log_document_root = '/var/log/nodepool/image',
  $builder_logging_conf_template = 'nodepool/nodepool-builder.logging.conf.erb',
  $environment = {},
  $build_workers = '1',
  $upload_workers = '4',
