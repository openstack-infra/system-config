#!/usr/bin/env ruby

require 'pp'
require 'pty'
require 'optparse'
require 'optparse/time'
require 'ostruct'

COLOR_CYAN        = "\e[0;36m"
COLOR_RESET       = "\e[m"

class Sh
    @ignore_failed_exit_code = false
    def Sh.exit(code = 0); Kernel.exit(code) end
    def Sh.dry_run?
        return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
    end

    @@exit_code = 0
    def Sh.exit_code
        return @@exit_code
    end

    def Sh.spawn(cmd, debug = true, ignore_output = true)
        output = ""

        begin
        PTY.spawn(cmd) { |stdin, stdout, pid|
            begin
            # Do stuff with the output here. Just printing to show it works
            stdin.each { |line|
                output += line unless ignore_output
#               print "#{COLOR_CYAN}#{cmd}#{COLOR_RESET}: #{line}" if debug
                print %{<b><font color="cyan">#{cmd}:</font></b> #{line}} if debug
            }
            rescue Errno::EIO
            rescue PTY::ChildExited => e
                @@exit_code = e.status.exitstatus
            ensure
                begin
                    Process.wait(pid)
                    @@exit_code = $?.exitstatus
                rescue
                end
            end
        }
        rescue PTY::ChildExited => e
            @@exit_code = e.status.exitstatus
        end

        return output
    end
    private_class_method :spawn

    # Run a shell command and return its output to the caller.
    def Sh.rrun (cmd, ignore = @ignore_failed_exit_code, repeat = 1, wait = 1,
                 debug = true, ignore_output = false)
        return Sh.run(cmd, ignore, repeat, wait, debug, false)
    end

    # Run a shell command just printing output to stdput. Output is not
    # collected returned to the caller.
    def Sh.run (cmd, ignore = @ignore_failed_exit_code, repeat = 1, wait = 1,
                debug = true, ignore_output = true)
        output = ""
        @@exit_code = 0
        1.upto(repeat) { |i|
            if i != 1 then
                print "Retry #{i}/#{repeat}: " if debug
                sleep(wait)
            end
            puts "#{COLOR_CYAN}#{cmd}#{COLOR_RESET}: " if debug
            @@exit_code = 0
            if not dry_run? then
                if cmd =~ /^cd\s+(.*)/ then
                    Dir.chdir($1)
                else
                    output = spawn(cmd, debug, ignore_output)
                end
                return output.chomp if @@exit_code == 0
            end
        }

        if @@exit_code != 0 then
            if ignore then
                puts "IGNORED: Comamnd #{cmd} failed with exit code #{$?}" if debug
                @@exit_code = 0
            else
                puts "ERROR EXIT: Comamnd #{cmd} failed with exit code #{$?}" if debug
                exit @@exit_code
            end
        end
        return output.chomp
    end

    def Sh.crun (cmd, ignore = true, cloud_manager = "10.84.26.14")
        return Sh.rrun("ssh #{cloud_manager} ci-openstack.sh #{cmd}", ignore)
    end
end

class Vm
    def Vm.get_hostname(type="name")

        # Disable proxy..
        http_proxy=ENV['http_proxy']
        ENV['http_proxy'] = nil
        name = Sh.rrun(%{curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \\"#{type}\\": | awk -F '\"' '{print $4}'}, true, 10, 5)

        # Re-enable proxy ..
        ENV['http_proxy'] = http_proxy
        return name
    end

    def Vm.get_hostip (hostname = get_hostname)
        return $1 if hostname =~ /ci-.*?(\d+\.\d+\.\d+\.\d+)/
        return "127.0.0.1"
    end

    def Vm.get_primary_interface()
        # Check if vhost0 is present. If so, it is the primary interface
        `ifconfig vhost0`
        return $?.to_i == 0 ? "vhost0" : "eth0"
    end

    def Vm.get_interface_ip (interface = Vm.get_primary_interface)
        ip = "127.0.0.1"
        ip = $1 if Sh.rrun(%{ifconfig #{interface} |\grep "inet addr"}) =~ /inet addr:(\d+\.\d+\.\d+\.\d+)/
        return ip
    end
end

class Util
    def self.ci_setup
        ENV['WORKSPACE']=ENV['PWD'] if ENV['WORKSPACE'].nil?
        ENV['USER'] = "jenkins" if ENV['USER'].nil? or ENV['USER'].empty?
        ENV['ZUUL_BRANCH'] ||= "R1.05"
        pp ENV
        if File.file? "#{ENV['WORKSPACE']}/skip_jobs" then
            puts "Jobs skipped due to jenkins.opencontrail.org:/root/ci-test/skip_jobs"
            exit
        end
    end
end
