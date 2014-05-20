#!/usr/bin/env ruby

require 'pp'

ENV['USER'] = "jenkins" if ENV['USER'].nil? or ENV['USER'].empty?
pp ENV

class Sh
    @ignore_failed_exit_code = false
    def Sh.exit; Kernel.exit end
    def Sh.dry_run?
        return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
    end

    def Sh.run (cmd, ignore = @ignore_failed_exit_code, repeat = 1, wait = 1,
                debug = true)
        output = ""
        exit_code = 0
        1.upto(repeat) { |i|
            if i == 1 then
                puts "#{cmd}" if debug
            else
                puts "Retry #{i}/#{repeat}: #{cmd}" if debug
                sleep(wait)
            end
            exit_code = 0
            if not dry_run? then
                if cmd =~ /^cd\s+(.*)/ then
                    Dir.chdir($1)
                else
                    output = `#{cmd}`
                end
                exit_code = $?.to_i
                return output.chomp if exit_code == 0
            end
        }

        if exit_code != 0 then
            if ignore then
                puts "IGNORED: Comamnd #{cmd} failed with exit code #{$?}" if debug
            else
                puts "ERROR EXIT: Comamnd #{cmd} failed with exit code #{$?}" if debug
                exit exit_code
            end
        end
        return output.chomp
    end

    def Sh.crun (cmd, ignore = true, cloud_manager = "10.84.26.14")
        return run("ssh #{cloud_manager} ci-openstack.sh #{cmd}", ignore)
    end
end

class Vm
    def Vm.get_hostname(type="name")

        # Disable proxy..
        http_proxy=ENV['http_proxy']
        ENV['http_proxy'] = nil
        name = Sh.run %{curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \\"#{type}\\": | awk -F '\"' '{print $4}'}

        # Re-enable proxy ..
        ENV['http_proxy'] = http_proxy
        return name
    end

    def Vm.get_hostip (hostname = get_hostname)
        return $1 if hostname =~ /ci-.*?(\d+\.\d+\.\d+\.\d+)/
        return "127.0.0.1"
    end

    def Vm.get_interface_ip (interface = "eth0")
        ip = "127.0.0.1"
        ip = $1 if Sh.run(%{ifconfig #{interface} |\grep "inet addr"}) =~ /inet addr:(\d+\.\d+\.\d+\.\d+)/
        return ip
    end
end
