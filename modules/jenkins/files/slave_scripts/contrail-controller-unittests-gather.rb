#!/usr/bin/env ruby

require 'rubygems'
require 'json'

# "apt-get -y install rubygems"
# "yum -y install rubygems"
# "gem install json"

exit(0) if ENV["ZUUL_CHANGES"] !~ /refs\/changes\/(.*)/
change_set = $1

dir = "#{ENV["WORKSPACE"]}/repo/controller"
json_file = "#{dir}/ci_unittests.json"

exit(0) unless File.file?(json_file)
Dir.chdir(dir)

# Get the files changes in this change-set.
cmd = %{git ls-remote 2>/dev/null | \grep #{change_set} | \grep refs | awk '{print $1}' | xargs git show --pretty="format:" --name-only}

@dirs = { }
`#{cmd}`.split.each { |file|
    next if file !~ /(src\/.*?)\//
    @dirs["controller/#{$1}"] = true
}

# Load unit-tests configuration
json = JSON.parse(File.read(json_file))

# Find all applicable scons test targets
@tests = [ ]
json.each_pair { |module_name, module_data|
    skip = true
    @dirs.each_key { |dir|
        if module_data["source_directories"].include?(dir) then

            # We need to run associated tests as the path matches.
            skip = false
            break
        end
    }
    next if skip

    @tests += module_data["scons_test_targets"]
    module_data["misc_test_targets"].each { |m|
        @tests += json[m]["scons_test_targets"]
    }
}

puts @tests.sort.uniq.join(" ") unless @tests.empty?
