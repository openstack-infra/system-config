#!/usr/bin/env ruby

require 'pp'

pp ENV

ENV['USER'] = "jenkins" if ENV['USER'].nil? or ENV['USER'].empty?
@zuul_project = ENV['ZUUL_PROJECT'] || "Juniper/contrail-controller-test"

@gerrit_setup = !ENV['ZUUL_PROJECT'].nil?

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
ENV['WORKSPACE']=ENV['PWD']
WORKSPACE=ENV['WORKSPACE']

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

    sh "rm -rf #{WORKSPACE}/#{@project}"
    sh "mkdir -p #{WORKSPACE}/#{@project}"
    sh "cd #{WORKSPACE}/#{@project}"

    # This clones a git repo with appropriate review patch
    sh "/usr/local/jenkins/slave_scripts/gerrit-git-prep.sh " +
       "#{GERRIT_SITE} #{GIT_ORIGIN}", false
end

def setup_contrail_repo(use_public)
    # Restore to parent directory
    sh "rm -rf #{WORKSPACE}/repo"
    sh "mkdir -p #{WORKSPACE}/repo"
    sh "cd #{WORKSPACE}/repo"

    # Initialize a repo. TODO Do not hard code manifest.xml file path
    branch = ENV['ZUUL_BRANCH'] || "master"

    # Fix hardcoded ubuntu to the flavor from jenkins slave label
    # e.g. ENV['NODE_LABELS' = "ci-10.84.35.174 juniper-tests swarm"

    if use_public then
        sh "repo init -u git@github.com:Juniper/contrail-vnc -b #{branch}"
    else
        branch = "mainline" if branch == "master"
        sh "repo init -u git@github.com:Juniper/contrail-vnc-private " +
           "-m #{branch}/ubuntu-12-04/manifest-havana.xml"
    end

    # Sync the repo
    sh "repo sync"

    # Remove annoying non-exsting shallow file symlink
    sh "rm -rf third_party/euca2ools/.git/shallow"
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
    sh "mv #{WORKSPACE}/repo/#{old_project} #{WORKSPACE}/repo/#{old_project}.orig"
    sh "mv #{WORKSPACE}/#{@project} #{WORKSPACE}/repo/#{old_project}"
end

def pre_build_setup
    sh "rm -rf /tmp/cache"
    sh "mkdir -p ~#{ENV['USER']}/tmp/cache"
    sh "ln -sf /home/#{ENV['USER']}/tmp/cache /tmp/cache"
    sh "python #{WORKSPACE}/repo/third_party/fetch_packages.py 2>&1 | tee #{WORKSPACE}/third_party_fetch_packages.log"
#   sh "python #{WORKSPACE}/repo/distro/third_party/fetch_packages.py 2>&1 | tee #{WORKSPACE}/distro_fetch_packages.log"
end

def main
    setup_gerrit_repo
    setup_contrail_repo(ARGV[0].nil? or ARGV[0] != "use_private")
    switch_gerrit_repo
    pre_build_setup
end

main

