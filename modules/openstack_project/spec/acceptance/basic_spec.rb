require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'openstack_project::server' do

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    manifest_path = File.join(pp_path, 'default.pp')
    File.read(manifest_path)
  end

  def postconditions_puppet_manifest
    manifest_path = File.join(pp_path, 'postconditions.pp')
    File.read(manifest_path)
  end

  before(:all) do
    # The ssh_authorized_key resource uses the key comment as a universal
    # identifier, so if a user's key is already in root's authorized keys, it
    # conflicts with adding the key for the user itself. Move root's key list
    # aside temporarily.
    shell('mv /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak')
    # epel is needed to install exim
    if os[:family] == 'redhat'
      shell('yum-config-manager --enable epel')
    end
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
  end

  ['mordred',
   'corvus',
   'clarkb',
   'fungi',
   'jhesketh',
   'pabelanger',
   'ianw',
   'shrews',
   'dmsimard',
   'yolanda',
   'rcarrillocruz',
   'frickler'].each do |user|
    describe user(user) do
      it { should exist }
    end
  end

  ['slukjanov',
   'elizabeth',
   'nibz'].each do |user|
    describe user(user) do
      it { should_not exist }
    end
  end

  exim = os[:family] == 'ubuntu' ? 'exim4' : 'exim'
  ntp = os[:family] == 'ubuntu' ? 'ntp' : 'ntpd'
  services = ['rsyslog', 'unbound', exim, 'snmpd', ntp]
  if os[:family] == 'ubuntu'
    services.push('openafs-client')
  end
  services.each do |service|
    describe service(service) do
      it { should be_running }
    end
  end

end
