require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')

# Disable check due to upstream bug: https://github.com/rodjek/puppet-lint/issues/170 
PuppetLint.configuration.send('disable_class_parameter_defaults')

# These are no good at the moment
PuppetLint.configuration.send('disable_documentation')
PuppetLint.configuration.send('disable_arrow_alignment')

# This is not simply fixable - there is a params class relationship
# with our puppetboard module. We should probably refactor it
PuppetLint.configuration.send('disable_inherits_across_namespaces')
