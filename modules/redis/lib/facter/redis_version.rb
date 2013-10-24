require 'facter'

Facter.add("redis_version") do
    setcode do
      %x{redis-server --version | cut -d ' ' -f 3}
    end
end


