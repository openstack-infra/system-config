require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'openstack_project::server' do

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  def postconditions_puppet_manifest
    module_path = File.join(pp_path, 'postconditions.pp')
    File.read(module_path)
  end

  before(:all) do
    # The ssh_authorized_key resource uses the key comment as a universal
    # identifier, so if a user's key is already in root's authorized keys, it
    # conflicts with adding the key for the user itself. Move root's key list
    # aside temporarily.
    shell('cat /root/.ssh/authorized_keys')
    shell('cat /etc/ssh/sshd_config')
    shell('mv /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak')
  end

  it 'should work with no errors' do
    apply_manifest(puppet_manifest, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(puppet_manifest, catch_changes: true)
  end

  it 'should turn root ssh back on' do
    apply_manifest(postconditions_puppet_manifest, catch_failures: true)
    shell('mv /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys')
    shell('cat /root/.ssh/authorized_keys')
    shell('cat /etc/ssh/sshd_config')
  end

  ['mordred',
   'corvus',
   'clarkb',
   'fungi',
   'jhesketh',
   'yolanda',
   'pabelanger',
   'rcarrillocruz',
   'ianw',
   'shrews',
   'dmsimard',
   'frickler'].each do |user|
    describe user(user) do
      it { should exist }
    end
  end

  ['slukjanov', 'elizabeth', 'nibz'].each do |user|
    describe user(user) do
      it { should_not exist }
    end
  end

  exim = os[:family] == 'ubuntu' ? 'exim4' : 'exim'
  ['rsyslog',
   'unbound',
   exim,
   'openafs-client',
   'snmpd',
   'ntp'].each do |service|
    describe service(service) do
      it { should be_running }
    end
  end

  describe command('iptables -S') do
    its(:stdout) { should contain('-A openstack-INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT') }
    its(:stdout) { should contain('-A openstack-INPUT -s 172.99.116.215/32 -p udp -m udp --dport 161 -j ACCEPT') }
    its(:stdout) { should contain('-A openstack-INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT') }
    its(:stdout) { should contain('-A openstack-INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT') }
    its(:stdout) { should contain('-A openstack-INPUT -p tcp -m state --state NEW -m tcp --dport 29418 -j ACCEPT') }
    its(:stdout) { should contain('-A openstack-INPUT -p tcp -m tcp --dport 29418 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 100 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with icmp-port-unreachable') }
    its(:stdout) { should contain('-A openstack-INPUT -j REJECT --reject-with icmp-host-prohibited') }
  end

end
