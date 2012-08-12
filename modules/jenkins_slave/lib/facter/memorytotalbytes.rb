# memorytotalbytes.rb

Facter.add("memorytotalbytes") do
  setcode do
    Facter::Util::Resolution.exec('free -bo | sed -n \'s/^Mem:\W\+\([0-9]\+\).*$/\1/p\'')
  end
end
