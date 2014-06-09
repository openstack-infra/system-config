#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"

require 'util'

Util.ci_setup
WORKSPACE=ENV['WORKSPACE']

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

def setup_gerrit_repo
    return unless @gerrit_setup

    Sh.run "rm -rf #{WORKSPACE}/#{@project}"
    Sh.run "mkdir -p #{WORKSPACE}/#{@project}"
    Sh.run "cd #{WORKSPACE}/#{@project}"

    # This clones a git repo with appropriate review patch
    Sh.run "/usr/local/jenkins/slave_scripts/gerrit-git-prep.sh " +
       "#{GERRIT_SITE} #{GIT_ORIGIN}", false
end

def setup_contrail_repo(use_public)
    # Restore to parent directory
    Sh.run "rm -rf #{WORKSPACE}/repo"
    Sh.run "mkdir -p #{WORKSPACE}/repo"
    Sh.run "cd #{WORKSPACE}/repo"

    # Initialize a repo. TODO Do not hard code manifest.xml file path
    branch = ENV['ZUUL_BRANCH'] || Util.ci_default_branch

    # Fix hardcoded ubuntu to the flavor from jenkins slave label
    # e.g. ENV['NODE_LABELS' = "ci-10.84.35.174 juniper-tests swarm"

    if use_public then
        Sh.run "repo init -u git@github.com:Juniper/contrail-vnc -b #{branch}"
    else
        branch = "mainline" if branch == "master"
        Sh.run "repo init -u git@github.com:Juniper/contrail-vnc-private " +
           "-m #{branch}/ubuntu-12-04/manifest-havana.xml"
    end

    # Sync the repo
    Sh.run "repo sync"

    # Remove annoying non-exsting shallow file symlink
    Sh.run "rm -rf third_party/euca2ools/.git/shallow"
end

# TODO Ideally, we should tweak .repo/manifest.xml to directly fetch project
# off gerrit.
def switch_gerrit_repo
    return unless @gerrit_setup

    # Find the project git repo based on .repo/manifest.xml file
    out = Sh.rrun "\grep name=\\\"#{@project} .repo/manifest.xml"
    if out !~ /path=\"(.*?)\"/ then
        puts "Error! Cannot find project #{@project} path in .repo/manifest.xml"
        exit -1
    end

    old_project = $1

    # Now, switch old_project to project's git repo fetched from gerrit.
    Sh.run "mv #{WORKSPACE}/repo/#{old_project} #{WORKSPACE}/repo/#{old_project}.orig"
    Sh.run "mv #{WORKSPACE}/#{@project} #{WORKSPACE}/repo/#{old_project}"
end

def pre_build_setup
    Sh.run "python #{WORKSPACE}/repo/third_party/fetch_packages.py 2>&1 | tee #{WORKSPACE}/third_party_fetch_packages.log"
    if ! @use_public then
        Sh.run "python #{WORKSPACE}/repo/distro/third_party/fetch_packages.py 2>&1 | tee #{WORKSPACE}/distro_fetch_packages.log"
    end
end

def main
    setup_gerrit_repo
    @use_public = (ARGV[0].nil? || ARGV[0] != "use_private")
    setup_contrail_repo(@use_public)
    switch_gerrit_repo
    pre_build_setup
end

main

