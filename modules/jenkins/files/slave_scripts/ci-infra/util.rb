#!/usr/bin/env ruby

require 'pp'
require 'pty'

COLOR_CYAN        = "\e[0;36m"
COLOR_RESET       = "\e[m"

class Sh
    @ignore_failed_exit_code = false
    def Sh.exit(code = 0); Kernel.exit(code) end
    def Sh.dry_run?
        return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
    end

    def Sh.spawn(cmd, debug = true)
        output = ""
        exit_code = 0

        begin
        PTY.spawn(cmd) { |stdin, stdout, pid|
            begin
            # Do stuff with the output here. Just printing to show it works
            stdin.each { |line|
                output += line
                print "#{COLOR_CYAN}#{cmd}#{COLOR_RESET}: #{line}" if debug
            }
            rescue Errno::EIO
            rescue PTY::ChildExited => e
                exit_code = e.status.exitstatus
            ensure
                Process.wait(pid)
                exit_code = $?.exitstatus
            end
        }
        rescue PTY::ChildExited => e
            exit_code = e.status.exitstatus
	end

        return output, exit_code
    end
    private_class_method :spawn

    def Sh.run (cmd, ignore = @ignore_failed_exit_code, repeat = 1, wait = 1,
                debug = true)
        output = ""
        exit_code = 0
        1.upto(repeat) { |i|
            if i != 1 then
                print "Retry #{i}/#{repeat}: " if debug
                sleep(wait)
            end
            puts "#{COLOR_CYAN}#{cmd}#{COLOR_RESET}: " if debug
            exit_code = 0
            if not dry_run? then
                if cmd =~ /^cd\s+(.*)/ then
                    Dir.chdir($1)
                else
#                   output = `#{cmd}`
                    output, exit_code = spawn(cmd, debug)
                end
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
        name = Sh.run(%{curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \\"#{type}\\": | awk -F '\"' '{print $4}'}, true, 10, 5)

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

class Util
    def self.ci_setup
        ENV['WORKSPACE']=ENV['PWD'] if ENV['WORKSPACE'].nil?
        ENV['USER'] = "jenkins" if ENV['USER'].nil? or ENV['USER'].empty?
        ENV['ZUUL_BRANCH'] ||= "master"
        pp ENV
        if File.file? "#{ENV['WORKSPACE']}/skip_jobs" then
            puts "Jobs skipped due to jenkins.opencontrail.org:/root/ci-test/skip_jobs"
            exit
        end
    end
end
