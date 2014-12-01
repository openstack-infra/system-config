#!/bin/bash

# ############################################################################ #
#                                                                              #
#   Created by Steve Weston (steve.weston@triniplex.com)                       #
#   Copyright (c) 2014 Triniplex                                               #
#                                                                              #
#                                                                              #
#    Licensed under the Apache License, Version 2.0 (the "License"); you may   #
#    not use this file except in compliance with the License. You may obtain   #
#    a copy of the License at                                                  #
#                                                                              #
#         http://www.apache.org/licenses/LICENSE-2.0                           #
#                                                                              #
#    Unless required by applicable law or agreed to in writing, software       #
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT #
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the  #
#    License for the specific language governing permissions and limitations   #
#    under the License.                                                        #
#                                                                              #
#    Description: This is a script to be used in preparation for splitting     #
#    the git repository github.com:openstack-infra/system-config.git into      #
#    individual github projects, based on the list of puppet modules in        #
#    the repository.                                                           #
#                                                                              #
#     Usage:                                                                   #
#     -o oauth_key - This is an OAuth access token called a "personal access   #
#                    "token" on github.  This must be used to create the       #
#                    repositories necessary for the split.                     #
#     -r - use this flag to create the repositories on github.  Using this     #
#          option will delete any existing repositories named puppet-module    #
#          where module is an enumeration of the directories in the repo.      #
#      -u github_user - This is the github user the repositories will be       #
#         managed with.                                                        #
#      -c config_repo_url - this is the url of the configuration repository    #
#         from which the modules are to be split from.                         #
#      -m merge_repo_url - this is a meta repository created in github which   #
#         is used to manage the state of the modules and construct the         #
#         history for the individual repositories created by the script.       #
#      -s sync_repos_only - use this option to keep the repositories in        #
#         sync with the config repository.                                     #
#                                                                              #
#      Instructions                                                            #
#      1. Place the script in it's own directory, i.e. /opt/modules/           #
#      2. To create the initial repositories (substitute your own user, OAuth  #
#         key, and merge repo url here):                                       #
#         /opt/modules/module_split -r -o oauth_key  -u Triniplex \            #
#         -c  github.com:openstack-infra/system-config.git                     #
#         -m git@github.com:Triniplex/puppet-modules.git                       #
#      3. To synchronize repositories:                                         #
#         /opt/modules/module_split -u Triniplex \                             #
#         -c github.com:openstack-infra/system-config.git \                    #
#         -m git@github.com:Triniplex/puppet-modules.git                       #
#      4. Run it from cron                                                     #
#                                                                              #
# ############################################################################ #

# Set globals
BASE="$(pwd)"
declare -a modules=()

print_help() {
    echo -e "\nUsage: `basename $0` options (-r) create_repos "
    echo -e "(-o oauth_key) (-u github_user) (-c config_repo_url) "
    echo -e "(-m merge_repo_url) (-s) sync_repos_only (-h) help\n"
    exit
}

exit_script() {
    echo "Ending: $(date -u)"
    exit 0
}

enter_script() {
    echo -e "\nstarting: $(date -u)"
}

# Get command line options
parse_command_line() {
    while getopts "hso:u:c:m:r" OPTION; do
        case "${OPTION}" in
            h)
                print_help
                ;;
            c)
                CONFIG_REPO=${OPTARG}
                ;;
            m)
                MERGE_REPO_URL=${OPTARG}
                ;;
            r)
                CREATE_REPOS="True"
                ;;
            s)
                SYNC_REPOS="True"
                ;;
            o)
                OAUTH_KEY=${OPTARG}
                ;;
            u)
                GITHUB_USER=${OPTARG}
                ;;
        esac
    done
    if [ -n "${CREATE_REPOS+1}" ] && [ ! -n "${OAUTH_KEY+1}" ]; then
        echo -e "Error parsing options.  If the create_repos option is used, "
        echo -e "then the oauth_key must be set."
        print_help
    fi
    if [ ! -n "${GITHUB_USER+1}" ]; then
        echo -e "The github user must be specified."
        print_help
    fi
    if [ ! -n "${MERGE_REPO_URL+1}" ]; then
        echo -e "The merge repo must be specified."
        print_help
    fi
    if [ ! -n "${CONFIG_REPO+1}" ]; then
        echo -e "The config repo must be specified."
        print_help
    fi
    if [ -n "${CREATE_REPOS+1}" ]; then
        echo -e "\nThe create repos option will distroy all github puppet "
        echo -e "module repositories for the ${GITHUB_USER} user. "
        echo -e "Continue? Enter yes and press enter, anything else "
        echo -n "will abort: "
        read answer
        if [ "${answer}" != "yes" ]; then
            exit 1
        fi
    fi
    GITHUB_URL=git@github.com:${GITHUB_USER}
    CONFIG_REPO_SUFFIX=$(echo ${CONFIG_REPO} | sed 's/.*\/\(.*\)\.git/\1/')
    MERGE_REPO_SUFFIX=$(echo ${MERGE_REPO_URL} | sed 's/.*\/\(.*\)\.git/\1/')
}

execute_command() {
    cmd=$1
    eval echo ${cmd}
    eval ${cmd} 2>/dev/null 1>/dev/null
}

sync_repos() {
    execute_command 'cd "${BASE}/${CONFIG_REPO_SUFFIX}"'
    execute_command 'git checkout master'
    execute_command 'git fetch origin'
    echo "Populating module list to be updated from upstream commits."
    lines=$(git log HEAD..origin/master --oneline | wc -l | awk '{print $1}')
    if [ ${lines} -eq 0 ]; then
        echo "No changes have been made to the config repository."
        exit 0
    fi
    # Search the commits for changes which apply to the puppet modules
    commit_hash=$(git log HEAD..origin/master --oneline | awk '{print $1}')
    if [ $(git diff --name-status ${commit_hash} | grep modules 2>/dev/null \
    1>/dev/null && echo $?) -ne 0 ]; then
        # None of the commits made to the config repo apply to us
        exit 0
    fi
    for module in $(for commit in $(git log HEAD..origin/master -$lines \
    --oneline | awk '{print $1}'); do git diff-tree --no-commit-id \
    --name-only -r $commit | sed -e 's/[a-z]*\/\([a-z_]*\).*/\1/'; \
    done); do
        modules=($(printf "%s\n%s\n" "${modules[@]}" "$module" | sort -u));
    done
    echo "The following modules will be updated: ${modules[@]}"
    execute_command 'git pull origin master'
    execute_command 'git subtree split --prefix=modules/ --rejoin --branch modules_branch'
    # We need to update the merge repo's settings to allow pushes to the current branch
    execute_command 'pushd "${BASE}/${MERGE_REPO_SUFFIX}"'
    execute_command 'git config receive.denyCurrentBranch ignore'
    execute_command 'popd'
    execute_command 'git push "${BASE}/${MERGE_REPO_SUFFIX}" modules_branch:master'
    for MODULE in "${modules[@]}"; do
        execute_command 'cd "${BASE}"'
        if [ -d "${BASE}/${MODULE}-split" ]; then
            execute_command 'rm -rf "${BASE}/${MODULE}-split"'
        fi
        execute_command 'git clone "${MERGE_REPO_SUFFIX}" "${MODULE}-split"'
        execute_command 'cd "${MODULE}-split"'
        execute_command 'git remote rm origin'
        execute_command 'git tag -l \| xargs git tag -d'
        execute_command 'git filter-branch --tag-name-filter cat --prune-empty --subdirectory-filter ${MODULE} -- --all'
        execute_command 'git remote add origin ${GITHUB_URL}/puppet-${MODULE}.git'
        execute_command 'git push -u origin master'
    done
}

merge_repo_setup() {
    execute_command 'cd "${BASE}"'
    if [ ! -d "${MERGE_REPO_SUFFIX}" ]; then
        execute_command 'mkdir "${MERGE_REPO_SUFFIX}"'
        execute_command 'cd "${MERGE_REPO_SUFFIX}"'
        execute_command 'git init --bare'
        execute_command 'cd "${BASE}/${CONFIG_REPO_SUFFIX}"'
        execute_command 'git push "${BASE}/${MERGE_REPO_SUFFIX}" modules_branch:master'
        execute_command 'cd "${BASE}/${MERGE_REPO_SUFFIX}"'
        execute_command 'git remote add origin "${MERGE_REPO_URL}"'
        execute_command 'git push -u origin master'
        execute_command 'cd "${BASE}"'
        execute_command 'rm -rf "${MERGE_REPO_SUFFIX}"'
        execute_command 'git clone "${MERGE_REPO_URL}"'
    fi
}

config_repo_setup() {
    execute_command 'cd "${BASE}"'
    if [ ! -d "${CONFIG_REPO_SUFFIX}" ]; then
        execute_command 'git clone "${CONFIG_REPO}"'
        execute_command 'cd "${CONFIG_REPO_SUFFIX}"'
        execute_command 'git subtree split --prefix=modules/ --rejoin --branch modules_branch'
    fi
}


# Create the local repositories
create_repos() {
    merge_repo_setup
    execute_command 'cd "${BASE}"'
    for MODULE in $(ls "${BASE}/${CONFIG_REPO_SUFFIX}/modules"); do
        DEST_REPO="puppet-${MODULE}"
        execute_command 'cd "${BASE}"'
        if [ -d "${MODULE}-split" ]; then
            execute_command 'rm -rf "${MODULE}-split"'
        fi
        execute_command 'git clone "${MERGE_REPO_SUFFIX}" "${DEST_REPO}"'
        execute_command 'cd "${DEST_REPO}"'
        execute_command 'git remote rm origin'
        execute_command 'git tag -l \| xargs git tag -d'
        execute_command 'git filter-branch --tag-name-filter cat --prune-empty --subdirectory-filter ${MODULE} -- --all'
        execute_command 'git remote add origin "${GITHUB_URL}/${DEST_REPO}.git"'
        execute_command 'git push -u origin master'
    done
}


# Create the github repos
create_github_repos() {
 # xtrace interferes with reading the curl response
    if [[ $- = *x* ]]; then
        SETXTRACE=ON
        set +x
    fi
    execute_command 'cd "${BASE}/${MERGE_REPO_SUFFIX}"'
    create_github_repo ${MERGE_REPO_SUFFIX}
    merge_repo_setup
    for MODULE in $(ls "${BASE}/${CONFIG_REPO_SUFFIX}/modules"); do
        create_github_repo "puppet-${MODULE}"
    done
    if [ -n "${SETXTRACE+1}" ]; then
        set -x
    fi
}

create_github_repo() {
    DEST_REPO=$1
    RECREATE_REPO=0
    echo "Creating repository ${DEST_REPO} ..."
    REPOS=$(curl -s -H "Authorization: token ${OAUTH_KEY}" https://api.github.com/orgs/${GITHUB_USER}/repos)
    echo $REPOS | grep "${DEST_REPO}" 2>/dev/null 1>/dev/null
    if [ $? -eq 0 ]; then
        RESPONSE=""
        RESPONSE=$(curl -s -X DELETE -H "Authorization: token ${OAUTH_KEY}" \
        https://api.github.com/repos/${GITHUB_USER}/${DEST_REPO})
        if [ "${RESPONSE+1}" ]; then
            RECREATE_REPO=1
        fi
    else
        RECREATE_REPO=1
    fi
    if [ ${RECREATE_REPO} -eq 1 ]; then
        RESPONSE=""
        RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"name\":\"${DEST_REPO}\"" \
                        -H "Authorization: token ${OAUTH_KEY}" https://api.github.com/orgs/${GITHUB_USER}/repos)
        echo $RESPONSE | grep "id" 2>/dev/null 1>/dev/null
        if [ $? -ne 0 ]; then
            echo "Repository ${DEST_REPO} creation failed!"
            exit 1
        fi
    fi
}

create_setup_repos() {
    if [ ! -d "${BASE}/${CONFIG_REPO_SUFFIX}/" ]; then
        config_repo_setup
    fi
}

# Where it all starts
main() {
    enter_script
    if [ -n "${OAUTH_KEY+1}" ]; then
        create_setup_repos
        create_github_repos
    fi
    if [ -n "${SYNC_REPOS+1}" ]; then
        sync_repos
    else
        create_repos
    fi
    exit_script
}

# Execute the functions
parse_command_line $@
time main
