require 'spec_helper_acceptance'

describe 'basic tests:' do
  it 'make sure we have copied the module across' do
    # No point diagnosing any more if the module wasn't copied properly
    shell("ls /etc/puppet/modules/puppetdb") do |r|
      r.exit_code.should == 0
      r.stdout.should =~ /Modulefile/
      r.stderr.should == ''
    end
  end

  describe 'single node setup' do
    pp = <<-EOS
      # Single node setup
      class { 'ntp': panic => false } ->
      class { 'puppetdb': disable_ssl => true, } ->
      class { 'puppetdb::master::config': puppetdb_port => '8080', puppetdb_server => 'localhost' }
    EOS

    it 'make sure it runs without error' do
      apply_manifest(pp, :catch_errors  => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end

  describe 'enabling report processor' do
    pp = <<-EOS
      class { 'ntp': panic => false } ->
      class { 'puppetdb': disable_ssl => true, } ->
      class { 'puppetdb::master::config':
        puppetdb_port => '8080',
        manage_report_processor => true,
        enable_reports => true,
        puppetdb_server => 'localhost'
      }
    EOS

    it 'should add the puppetdb report processor to puppet.conf' do
      apply_manifest(pp, :catch_errors  => true)
      apply_manifest(pp, :catch_changes => true)

      shell('cat /etc/puppet/puppet.conf') do |r|
        expect(r.stdout).to match(/^reports\s*=\s*([^,]+,)*puppetdb(,[^,]+)*$/)
      end
    end
  end
end
