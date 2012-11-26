# == Define: ulimit::conf
#
define ulimit::conf (
  $limit_domain,
  $limit_item,
  $limit_value,
  $limit_type = 'soft',
) {

  file { "/etc/security/limits.d/99-${limit_domain}-${limit_type}-${limit_item}.conf":
    ensure  => present,
    content => template('ulimit/limits.erb'),
    replace => true,
    owner   => 'root',
    mode    => '0644',
    require => File['/etc/security/limits.d'],
  }
}
