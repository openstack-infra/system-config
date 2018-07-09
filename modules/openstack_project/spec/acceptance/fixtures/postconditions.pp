# Turn root ssh back on, otherwise we can't post logs
class { 'ssh':
  trusted_ssh_type   => 'address',
  trusted_ssh_source => '23.253.245.198,2001:4800:7818:101:3c21:a454:23ed:4072',
  permit_root_login  => 'yes',
}
