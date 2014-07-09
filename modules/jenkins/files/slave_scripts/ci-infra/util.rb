#!/usr/bin/env ruby

# Utility routines to do shell and other operations.

require 'pp'
require 'pty'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'launch_vms'

COLOR_RESET       = "\e[m"
COLOR_BLACK       = "\e[0;30m"
COLOR_RED         = "\e[0;31m"
COLOR_GREEN       = "\e[0;32m"
COLOR_BROWN       = "\e[0;33m"
COLOR_BLUE        = "\e[0;34m"
COLOR_MAGENTA     = "\e[0;35m"
COLOR_CYAN        = "\e[0;36m"
COLOR_GRAY        = "\e[0;37m"
COLOR_DARKGRAY    = "\e[1;30m"
COLOR_DARKBLUE    = "\e[1;34m"
COLOR_DARKGREEN   = "\e[1;32m"
COLOR_DARKCYAN    = "\e[1;36m"
COLOR_DARKRED     = "\e[1;31m"
COLOR_DARKPURPLE  = "\e[1;35m"
COLOR_YELLOW      = "\e[1;33m"
COLOR_WHITE       = "\e[1;37m"

class Sh
    @@ignore_failed_exit_code = false
    @@exit_code = 0

    @@always_exit_as_success = false
    def self.always_exit_as_success() return @@always_exit_as_success end
    def self.always_exit_as_success=(flag) @@always_exit_as_success = flag end

    def self.exit(code = 0)
        @@exit_code = code
        Kernel.exit(code)
    end

    def self.exit!(code = @@exit_code)
        if code != 0 then
            if always_exit_as_success then
                puts "IGNORE failed exit code!"
                code = 0
            else
                puts "Job failed to complete successfully, exit code #{code}"
            end
        else
            puts "Job successfully completed, exit code #{code}"
        end
        Process.exit!(code)
    end

    def self.dry_run?
        return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
    end

    def self.exit_code() return @@exit_code end

    def self.spawn(cmd, debug = true, ignore_output = true)
        output = ""

        begin
        count = 0
        frame = "#{COLOR_YELLOW}#{caller[4]}() #{caller[5]}() " if debug
        PTY.spawn(cmd) { |stdin, stdout, pid|
            begin
            # Do stuff with the output here. Just printing to show it works
            stdin.each { |line|
                output += line unless ignore_output
                next unless debug
                count += 1
                if count % 100 == 0 then
                    puts "#{frame} #{COLOR_CYAN}#{cmd}#{COLOR_RESET}"
                end
                print line
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
    def self.rrun (cmd, ignore = @@ignore_failed_exit_code, repeat = 1, wait = 1,
                 debug = true, ignore_output = false)
        return self.run(cmd, ignore, repeat, wait, debug, false)
    end

    # Run a shell command just printing output to stdput. Output is not
    # collected returned to the caller.
    def self.run (cmd, ignore = @@ignore_failed_exit_code, repeat = 1, wait = 1,
                debug = true, ignore_output = true)
        output = ""
        @@exit_code = 0
        frame = "#{COLOR_YELLOW}#{caller[2]}() #{caller[3]}() "
        1.upto(repeat) { |i|
            if i != 1 then
                print "Retry #{i}/#{repeat}: " if debug
                sleep(wait)
            end
            puts "#{frame} #{COLOR_CYAN}#{cmd}#{COLOR_RESET}: " if debug
            @@exit_code = 0
            if not dry_run? then
                if cmd =~ /^cd\s+(.*)/ then
                    Dir.chdir($1)
                else
                    output = spawn(cmd, debug, ignore_output)
                end
                return output.chomp, 0 if @@exit_code == 0
            end
        }

        ret_code = @@exit_code
        if @@exit_code != 0 then
            if ignore then
                puts "IGNORED: Comamnd #{cmd} failed with exit code #{$?}" if debug
                @@exit_code = 0
            else
                puts "ERROR EXIT: Comamnd #{cmd} failed with exit code #{$?}" if debug
                exit @@exit_code
            end
        end
        return output.chomp, ret_code
    end

    # Cloud run, to run openstack manage commands in the build cluster.
    def self.crun (cmd, ignore = true, cloud_manager = "10.84.26.14")
        return self.rrun("ssh #{cloud_manager} ci-openstack.sh #{cmd}", ignore)
    end
end # class Sh

# Add some useful routines to Vm class.
class Vm
    def self.get_hostname(type="name")

        # Disable proxy..
        http_proxy=ENV['http_proxy']
        ENV['http_proxy'] = nil
        name, e = Sh.rrun(%{curl -s http://169.254.169.254/openstack/2012-08-10/meta_data.json | python -m json.tool | \grep \\"#{type}\\": | awk -F '\"' '{print $4}'}, true, 40, 5)

        # Re-enable proxy ..
        ENV['http_proxy'] = http_proxy
        return name
    end

    def self.get_hostip (hostname = get_hostname)
        return $1 if hostname =~ /ci-.*?(\d+\.\d+\.\d+\.\d+)/
        return "127.0.0.1"
    end

    def self.get_primary_interface()
        # Check if vhost0 is present. If so, it is the primary interface
        `ifconfig vhost0`
        return $?.to_i == 0 ? "vhost0" : "eth0"
    end

    def self.get_interface_ip (interface = self.get_primary_interface)
        ip = "127.0.0.1"
        o, e = Sh.rrun(%{ifconfig #{interface} |\grep "inet addr"})
        ip = $1 if o =~ /inet addr:(\d+\.\d+\.\d+\.\d+)/
        return ip
    end
end # class Vm

# Install exit routine
at_exit { Util.ci_cleanup }

class Util
    def self.ci_default_branch
        return ENV['ZUUL_BRANCH'] unless ENV['ZUUL_BRANCH'].nil?

        return "master"
#       return (!ENV['JOB_NAME'].nil? and
#               ENV['JOB_NAME'] == "contrail-systest-job") ? "R1.05" : "master"
    end

    def self.ci_setup
        $stdout.sync = true
        ENV['WORKSPACE'] ||= ENV['PWD']
        ENV['USER'] ||= "jenkins"
        ENV['ZUUL_BRANCH'] ||= Util.ci_default_branch
        pp ENV
        if File.file? "#{ENV['WORKSPACE']}/skip_jobs" then
            puts "Jobs skipped due to jenkins.opencontrail.org:/root/ci-test/skip_jobs"
            exit
        end
    end

    def self.wait
        puts "Sleeping until /root/ci_job_wait is gone"
        loop do
            break unless File.file? "/root/ci_job_wait"
            sleep 10
        end
    end

    @@cleanup_on_exit = false
    def self.cleanup_on_exit() return @@cleanup_on_exit end
    def self.cleanup_on_exit=(flag) @@cleanup_on_exit = flag end

    def self.ci_cleanup
        Sh.exit! unless @@cleanup_on_exit

        exit_code = Sh.exit_code # Note down the current exit code
        wait

        # Clean up the workspace, if the job is successful.
        Sh.run("rm -rf #{ENV['WORKSPACE']}/* #{ENV['WORKSPACE']}/.* 2>/dev/null", true) if exit_code == 0

        Vm.clean_all
        Sh.exit!(exit_code)
    end
end # class Util
