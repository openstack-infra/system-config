require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'openstack_project::firehose' do

  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def puppet_manifest
    manifest_path = File.join(pp_path, 'firehose.pp')
    File.read(manifest_path)
  end

  def postconditions_puppet_manifest
    manifest_path = File.join(pp_path, 'firehose_postconditions.pp')
    File.read(manifest_path)
  end

  before(:all) do
    # epel is needed to install exim
    if os[:family] == 'redhat'
      shell('yum-config-manager --enable epel')
    end
  end

  it 'should work with no errors' do
    apply_manifest(puppet_manifest, catch_failures: true)
  end

  it 'should be idempotent' do
    pending("mosquitto::server is not idempotent, it runs mosquitto_passwd unconditionally")
    apply_manifest(puppet_manifest, catch_changes: true)
  end

  ['mosquitto', 'lpmqtt', 'germqtt', 'statsd_mqtt'].each do |service|
    describe service(service) do
      it { should be_running }
    end
  end

  describe port(1883) do
    it { should be_listening }
  end
end
