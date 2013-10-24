require 'facter'

if  FileTest.exists?("/usr/bin/dpkg-query")
    Facter.add("redis_version") do
        setcode do
            %x{/usr/bin/dpkg-query -W -f='${Version}' redis-server}
        end
    end
end

