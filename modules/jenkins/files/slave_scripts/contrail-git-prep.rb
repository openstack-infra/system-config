#!/usr/bin/env ruby

# Find the project e.g. ZUUL_PROJECT : stackforge/contrail-controller
if ENV['ZUUL_PROJECT'] !~ /stackforge\/(.*)/ then
    puts "Error: Cannot find project information off ZUUL_PROJECT : " +
         "#{ENV['ZUUL_PROJECT']}"
    exit -1
end

@project = $1
@project = "controller" if @project == "contrail-controller" # Temporary hack
puts "Working with project #{@project}"

GERRIT_SITE="https://review.opencontrail.org" # ARGV[0]
GIT_ORIGIN="ssh://zuul@review.opencontrail.org:29418" # ARGV[1]
TOP=ENV['PWD']

def dry_run?
    return !ENV['DRY_RUN'].nil? && ENV['DRY_RUN'].casecmp("true")
end

def sh (cmd, ignore = false)
    puts "#{cmd}"
    if not dry_run? then
        if cmd =~ /^cd\s+(.*)/ then
            Dir.chdir($1)
        else
            output = `#{cmd}`
        end
    end
    puts output if !output.nil? and !output.empty?

    if !dry_run? and !ignore and $? != 0 then
        puts "Comamnd #{cmd} failed with exit code #{$?}"
    end
    return output
end

def setup_gerrit_repo
    sh "mkdir #{TOP}/#{@project}"
    sh "cd #{TOP}/#{@project}"

    # This clones a git repo with appropriate review patch
    sh "/usr/local/jenkins/slave_scripts/gerrit-git-prep.sh " +
       "#{GERRIT_SITE} #{GIT_ORIGIN}", false
end

def setup_contrail_repo

    # Restore to parent directory
    sh "mkdir #{TOP}/repo"
    sh "cd #{TOP}/repo"

    # Initialize a repo - Need to retrieve
    sh "/usr/local/jenkins/slave_scripts/repo init " +
       "-u git@github.com:Juniper/contrail-vnc-private " +
       "-m mainline/ubuntu-12-04/manifest-havana.xml"

    # Sync the repo
    sh "/usr/local/jenkins/slave_scripts/repo sync"
end

def switch_gerrit_repo

    # Now, switch to project's git repo.
    sh "mv #{TOP}/repo/#{@project} #{TOP}/repo/.#{@project}.orig"
    sh "mv #{TOP}/#{@project} #{TOP}/repo/#{@project}"
end

def pre_build_setup
    sh "python #{TOP}/repo/third_party/fetch_packages.py"
    sh "python #{TOP}/repo/distro/third_party/fetch_packages.py"
end

def main
    setup_gerrit_repo
    setup_contrail_repo
    switch_gerrit_repo
    pre_build_setup
end

main

