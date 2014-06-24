#!/usr/bin/env ruby

$LOAD_PATH.unshift "/usr/local/jenkins/slave_scripts/",
                   "/usr/local/jenkins/slave_scripts/ci-infra"
require 'util'

class ContrailGitPrep

GERRIT_SITE="https://review.opencontrail.org" # ARGV[0]
GIT_ORIGIN="ssh://zuul@review.opencontrail.org:29418" # ARGV[1]

def self.init_project
    @zuul_project = ENV['ZUUL_PROJECT'] || "Juniper/contrail-controller-test"
    @gerrit_setup = !ENV['ZUUL_PROJECT'].nil?

    # Find the project
    if @zuul_project !~ /Juniper\/(.*)/ then
        puts "Error: Cannot find project information off ZUUL_PROJECT : " +
            "#{@zuul_project}"
    end
    @project = $1

    # For testing
    @project = "contrail-controller" if @project == "contrail-controller-test"
    puts "Working with project #{@project}"
end

def self.setup_gerrit_repo
    return unless @gerrit_setup

    Sh.run "rm -rf #{ENV['WORKSPACE']}/#{@project}"
    Sh.run "mkdir -p #{ENV['WORKSPACE']}/#{@project}"
    Sh.run "cd #{ENV['WORKSPACE']}/#{@project}"

    # This clones a git repo with appropriate review patch
    Sh.run "/usr/local/jenkins/slave_scripts/gerrit-git-prep.sh " +
       "#{GERRIT_SITE} #{GIT_ORIGIN}", false
end

def self.setup_contrail_repo(use_public)
    # Restore to parent directory
    Sh.run "rm -rf #{ENV['WORKSPACE']}/repo"
    Sh.run "mkdir -p #{ENV['WORKSPACE']}/repo"
    Sh.run "cd #{ENV['WORKSPACE']}/repo"

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
def self.switch_gerrit_repo
    return unless @gerrit_setup

    # Find the project git repo based on .repo/manifest.xml file
    out, e = Sh.rrun "\grep name=\\\"#{@project} .repo/manifest.xml"
    if out !~ /path=\"(.*?)\"/ then
        puts "Error! Cannot find project #{@project} path in .repo/manifest.xml"
        exit -1
    end

    old_project = $1

    # Now, switch old_project to project's git repo fetched from gerrit.
    Sh.run "mv #{ENV['WORKSPACE']}/repo/#{old_project} #{ENV['WORKSPACE']}/repo/#{old_project}.orig"
    Sh.run "mv #{ENV['WORKSPACE']}/#{@project} #{ENV['WORKSPACE']}/repo/#{old_project}"
end

def self.pre_build_setup

    # Setup cache first to avoid downloads over the Internet
    cache = "/tmp/cache/#{ENV['USER']}"
    Sh.run("mkdir -p #{cache}")
    Sh.run("sshpass -p c0ntrail123 rsync -az --no-owner --no-group ci-admin@ubuntu-build02:/tmp/cache/ci-admin/ #{cache}")
    Sh.run("chown -R #{ENV['USER']}.#{ENV['USER']} #{cache}")

    Sh.run "python #{ENV['WORKSPACE']}/repo/third_party/fetch_packages.py 2>&1 | tee #{ENV['WORKSPACE']}/third_party_fetch_packages.log"
    if ! @use_public then
        Sh.run "python #{ENV['WORKSPACE']}/repo/distro/third_party/fetch_packages.py 2>&1 | tee #{ENV['WORKSPACE']}/distro_fetch_packages.log"
    end
end

def self.main(use_public)
    init_project
    setup_gerrit_repo
    @use_public = use_public
    setup_contrail_repo(@use_public)
    switch_gerrit_repo
    pre_build_setup
end

end # class ContrailGitPrep

if __FILE__ == $0 then
    Util.ci_setup
    ContrailGitPrep.main(ARGV[0].nil? || ARGV[0] != "use_private")
end
