require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

hosts.each do |host|
  if host['platform'] =~ /debian/
    on host, 'echo \'export PATH=/var/lib/gems/1.8/bin/:${PATH}\' >> ~/.bashrc'
  end
  if host.is_pe?
    install_pe
  else
    #install_puppet
    if host['platform'] =~ /el-(5|6)/
      relver = $1
      on host, "rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-#{relver}.noarch.rpm"
      on host, 'yum install -y puppet puppet-server'
    elsif host['platform'] =~ /fedora-(\d+)/
      relver = $1
      on host, "rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-fedora-#{relver}.noarch.rpm"
      on host, 'yum install -y puppet-server'
    elsif host['platform'] =~ /(ubuntu|debian)/
      if ! host.check_for_package 'curl'
        on host, 'apt-get install -y curl'
      end
      on host, 'curl -O http://apt.puppetlabs.com/puppetlabs-release-$(lsb_release -c -s).deb'
      on host, 'dpkg -i puppetlabs-release-$(lsb_release -c -s).deb'
      on host, 'apt-get -y -f -m update'
      on host, 'apt-get install -y puppet puppetmaster'
    else
      raise "install_puppet() called for unsupported platform '#{host['platform']}' on '#{host.name}'"
    end
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'puppetdb')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-ntp'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-postgresql', '--version', '">= 3.1.0 <4.0.0"'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-inifile', '--version', '1.x'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
