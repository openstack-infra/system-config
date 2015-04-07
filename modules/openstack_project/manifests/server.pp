# == Class: openstack_project::server
#
# A server that we expect to run for some time
class openstack_project::server (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $sysadmins                 = [],
  $certname                  = $::fqdn,
  $pin_puppet                = '3.',
  $ca_server                 = undef,
  $afs                       = false,
  $puppetmaster_server       = 'puppetmaster.openstack.org',
) {
  class { 'openstack_project::template':
    iptables_public_tcp_ports    => $iptables_public_tcp_ports,
    iptables_public_udp_ports    => $iptables_public_udp_ports,
    iptables_rules4              => $iptables_rules4,
    iptables_rules6              => $iptables_rules6,
    certname                     => $certname,
    pin_puppet                   => $pin_puppet,
    ca_server                    => $ca_server,
    afs                          => $afs,
    puppetmaster_server          => $puppetmaster_server,
    pypi_index_url               => $pypi_index_url,
    pypi_trusted_hosts           => $pypi_trusted_hosts,
    enable_puppet                => $enable_puppet,
    puppet_http_proxy            => $puppet_http_proxy,
    puppet_https_proxy           => $puppet_https_proxy,
    puppet_agent_http_proxy_host => $puppet_agent_http_proxy_host,
    puppet_agent_http_proxy_port => $puppet_agent_http_proxy_port,
    puppet_dns_alt_names         => $puppet_dns_alt_names,
    puppet_environment_path      => $puppet_environment_path,
    puppet_basemodule_path       => $puppet_basemodule_path,
    puppet_environment_timeout   => $puppet_environment_timeout,
    puppet_store_configs         => $puppet_store_configs,
    puppet_store_backend         => $puppet_store_backend,
    puppet_reports               => $puppet_reports,
    puppet_agent_runinterval     => $puppet_agent_runinterval,
    puppet_release               => $puppet_release,
  }
  class { 'exim':
    sysadmins => $sysadmins,
  }
}
