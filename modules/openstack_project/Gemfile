source 'https://rubygems.org'

if File.exists?('/home/zuul/src/git.openstack.org/openstack-infra/puppet-openstack_infra_spec_helper')
  gem_checkout_method = {:path => '/home/zuul/src/git.openstack.org/openstack-infra/puppet-openstack_infra_spec_helper'}
else
  gem_checkout_method = {:git => 'https://git.openstack.org/openstack-infra/puppet-openstack_infra_spec_helper'}
end
gem_checkout_method[:require] = false

group :development, :test, :system_tests do
  gem 'puppet-openstack_infra_spec_helper',
      gem_checkout_method
end

# vim:ft=ruby
