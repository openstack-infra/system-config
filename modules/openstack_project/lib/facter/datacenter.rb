# which cloud provider?
Facter.add('cloudprovider') do
  setcode do
    ip = Facter.value(:ipaddress)
    if ip.start_with?('10')
        "hpcloud"
    else
        "rackspace"
    end
  end
end
