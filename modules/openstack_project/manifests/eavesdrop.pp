class openstack_project::eavesdrop {
  class { 'openstack_project::server':

    iptables_public_tcp_ports => [80]
  }
  include meetbot

  meetbot::site { "openstack":
    nick => "openstack",
    nickpass => hiera('openstack_meetbot_password'),
    network => "FreeNode",
    server => "chat.us.freenode.net:7000",
    channels => "#openstack #openstack-dev #openstack-meeting",
    use_ssl => "True"
  }
}
