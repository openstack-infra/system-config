module Puppet::Parser::Functions
  newfunction(:puppetdb_create_subsetting_resource_hash, :type => :rvalue) do |args|
    java_args = args[0]
    params = args[1]
    resource_hash = {}
    
    java_args.each { |k,v|
      item_params = { 'subsetting' => k, 'value' => (v || '') }
      item_params.merge!(params)
      resource_hash.merge!({ "'#{k}'" => item_params })
    }
    
    resource_hash
  end
end