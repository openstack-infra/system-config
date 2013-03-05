class jeepyb::openstackwatch(

) {
  include jeepyb

  cron { 'openstackwatch':
    ensure  => present,
    command => 'gather current changes and publish them',
    minute  => 18,
  }

  file { 'config':
    ensure      => present,
    put_it      => here,
    get_it_from => here,
    user        => gerrit,
  }
}
