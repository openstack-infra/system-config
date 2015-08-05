# Create a veth pair to connect the neutron bridge to the vlan bridge
class openstack_project::infracloud::veth {
  exec { 'create veth pair':
    command => '/sbin/ip link add veth1 type veth peer name veth2',
    unless  => '/sbin/ip link show | /bin/grep veth1 && /sbin/ip link show | /bin/grep veth2',
  }

  exec { 'attach veth pair':
    command => '/sbin/brctl addif br-vlan25 veth1',
    unless  => '/sbin/brctl show br-vlan25 | /bin/grep veth1',
    require => Exec['create veth pair'],
  }

  exec { 'turn on veth1':
    command => '/sbin/ip link set dev veth1 up',
    unless  => '/sbin/ip link show dev veth1 | /bin/grep "state UP"',
    require => Exec['attach veth pair'],
  }

  exec { 'turn on veth2':
    command => '/sbin/ip link set dev veth2 up',
    unless  => '/sbin/ip link show dev veth2 | /bin/grep "state UP"',
    require => Exec['attach veth pair'],
  }
}
