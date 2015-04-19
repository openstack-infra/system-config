source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false

  gem 'metadata-json-lint'
  # This next one _should_ be enabled, but it's way too much churn to fix
  # right now.
  # gem 'puppet-lint-absolute_classname-check'
  gem 'puppet-lint-absolute_template_path'
  gem 'puppet-lint-trailing_newline-check'

  # Puppet 4.x related lint checks
  gem 'puppet-lint-unquoted_string-check'
  # Empty string changed to mean "true" in puppet 4. While it's ok to
  # assign the empty string to a variable, if that variable is checked
  # with if $variable instead of if $variable == '', it'll be an opposite
  # behavior. However, the check is too violated by us to use right now.
  # gem 'puppet-lint-empty_string-check'
  gem 'puppet-lint-leading_zero-check'
  gem 'puppet-lint-variable_contains_upcase'
  gem 'puppet-lint-numericvariable'
  gem 'puppet-lint-spaceship_operator_without_tag-check'
  gem 'puppet-lint-undef_in_function-check'

  if puppetversion = ENV['PUPPET_GEM_VERSION']
    gem 'puppet', puppetversion, :require => false
  else
    gem 'puppet', '~> 3.7.0', :require => false
  end

end


# vim:ft=ruby
