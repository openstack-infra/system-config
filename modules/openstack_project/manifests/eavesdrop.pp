class openstack_project::eavesdrop($nickpass) {
  class { 'openstack_project::server':

    iptables_public_tcp_ports => [80]
  }
  include meetbot

  meetbot::site { "openstack":
    nick => "openstack",
    nickpass => $nickpass,
    network => "FreeNode",
    server => "chat.us.freenode.net:7000",
    channels => "#openstack #openstack-dev #openstack-meeting",
    use_ssl => "True"
  }
}
