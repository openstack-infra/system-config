#!/usr/bin/env ruby

ENV['USER'] = "jenkins" if ENV['USER'].nil? or ENV['USER'].empty?
@zuul_project = ENV['ZUUL_PROJECT'] || "Juniper/contrail-controller-test"

@gerrit_setup = true

def init_gerrit_setup
    @gerrit_setup = !ENV['ZUUL_PROJECT'].nil?
    `ping -c 1 -q zuul.opencontrail.org 2>&1 > /dev/null`
    @gerrit_setup &&= $?.to_i == 0
    `ping -c 1 -q review.opencontrail.org 2>&1 > /dev/null`
    @gerrit_setup &&= $?.to_i == 0
end

# Find the project
if @zuul_project !~ /Juniper\/(.*)/ then
    puts "Error: Cannot find project information off ZUUL_PROJECT : " +
         "#{@zuul_project}"
#   exit -1
end

@project = $1
@project = "contrail-controller" if @project == "contrail-controller-test" # For testing
puts "Working with project #{@project}"

GERRIT_SITE="https://review.opencontrail.org" # ARGV[0]
GIT_ORIGIN="ssh://zuul@review.opencontrail.org:29418" # ARGV[1]
TOP=ENV['PWD']

def dry_run?
    return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true") == 0
end

def sh (cmd, ignore = false)
    puts "#{cmd}"
    exit_code = 0
    if not dry_run? then
        if cmd =~ /^cd\s+(.*)/ then
            Dir.chdir($1)
        else
            puts cmd
            output = `#{cmd}`
            exit_code = $?.to_i unless ignore
        end
    end
    puts output if !output.nil? and !output.empty?

    if exit_code != 0 then
        puts "Comamnd #{cmd} failed with exit code #{$?}"
        exit exit_code
    end
    return output
end

def setup_gerrit_repo
    return unless @gerrit_setup

    sh "rm -rf #{TOP}/#{@project}"
    sh "mkdir -p #{TOP}/#{@project}"
    sh "cd #{TOP}/#{@project}"

    # This clones a git repo with appropriate review patch
    sh "/usr/local/jenkins/slave_scripts/gerrit-git-prep.sh " +
       "#{GERRIT_SITE} #{GIT_ORIGIN}", false
end

def setup_contrail_repo
    # Restore to parent directory
    sh "rm -rf #{TOP}/repo"
    sh "mkdir -p #{TOP}/repo"
    sh "cd #{TOP}/repo"

    # Initialize a repo. TODO Do not hard code manifest.xml file path
    sh "repo init -u git@github.com:Juniper/contrail-vnc " +
       "-m default.xml"
#      "-m mainline/ubuntu-12-04/manifest-havana.xml"

    # Sync the repo
    sh "repo sync"
end

# TODO Ideally, we should tweak .repo/manifest.xml to directly fetch project
# off gerrit.
def switch_gerrit_repo
    return unless @gerrit_setup

    # Find the project git repo based on .repo/manifest.xml file
    out = sh "\grep name=\\\"#{@project} .repo/manifest.xml"
    if out !~ /path=\"(.*?)\"/ then
        puts "Error! Cannot find project #{@project} path in .repo/manifest.xml"
        exit -1
    end

    old_project = $1

    # Now, switch old_project to project's git repo fetched from gerrit.
    sh "mv #{TOP}/repo/#{old_project} #{TOP}/repo/#{old_project}.orig"
    sh "mv #{TOP}/#{@project} #{TOP}/repo/#{old_project}"
end

def pre_build_setup
    sh "python #{TOP}/repo/third_party/fetch_packages.py 2>&1"
#   sh "python #{TOP}/repo/distro/third_party/fetch_packages.py 2>&1"
end

def main
    setup_gerrit_repo
    setup_contrail_repo
    switch_gerrit_repo
    pre_build_setup
end

main

