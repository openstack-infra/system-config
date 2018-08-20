$manage_afs = $::operatingsystem ? {
  'CentOS' => false,
  default  => true
}

class { 'openstack_project::server':
  afs                       => $manage_afs,
}
