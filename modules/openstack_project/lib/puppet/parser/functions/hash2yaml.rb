# Function returns YAML representation of hash

module Puppet::Parser::Functions
  newfunction(:hash2yaml,
              :doc => 'Returns YAML representation of a hash, or part of a hash pinted by second parameter',
              :arity => -2,
              :type => :rvalue) do |args|
    hash_in = args[0]
    if ( args.length() == 2 )
      key_top = args[1]
      YAML.dump(hash_in[key_top])
    else
      YAML.dump(hash_in)
    end
  end
end
