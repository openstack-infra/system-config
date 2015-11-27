#!/bin/bash
# Copyright 2014 OpenStack Foundation.
# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

MODULE_PATH=`puppet config print modulepath | cut -d ':' -f 1`
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(readlink -f "$(dirname $0)")
JUST_CLONED=0

function remove_module {
    local SHORT_MODULE_NAME=$1
    if [ -n "$SHORT_MODULE_NAME" ]; then
        rm -Rf "$MODULE_PATH/$SHORT_MODULE_NAME"
    else
        echo "ERROR: remove_module requires a SHORT_MODULE_NAME."
    fi
}

function git_clone {
    local MOD=$1
    local DEST=$2

    JUST_CLONED=1
    for attempt in $(seq 0 3); do
        clone_error=0
        git clone $MOD $DEST && break || true
        rm -rf $DEST
        clone_error=1
    done
    return $clone_error
}

# Array of modules to be installed key:value is module:version.
declare -A MODULES

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES

# Array of modues to be installed from source and without dependency resolution from openstack git
# key:value is source location, revision to checkout
declare -A INTEGRATION_MODULES

# load modules.env to populate MODULES[*] and SOURCE_MODULES[*]
# for processing.
MODULE_ENV_FILE=${MODULE_FILE:-modules.env}
MODULE_ENV_PATH=${MODULE_ENV_PATH:-${SCRIPT_DIR}}
if [ -f "${MODULE_ENV_PATH}/${MODULE_ENV_FILE}" ] ; then
    . "${MODULE_ENV_PATH}/${MODULE_ENV_FILE}"
fi

if [ -z "${!MODULES[*]}" ] && [ -z "${!SOURCE_MODULES[*]}" ] ; then
    echo ""
    echo "WARNING: nothing to do, unable to find MODULES or SOURCE_MODULES"
    echo "  export options, try setting MODULE_ENV_PATH or MODULE_ENV_FILE"
    echo "  export to the proper location of modules.env file."
    echo ""
    exit 0
fi

MODULE_LIST=`puppet module list --color=false`

# Install modules from source
for MOD in ${!SOURCE_MODULES[*]} ; do
    JUST_CLONED=0
    # get the name of the module directory
    if [ `echo $MOD | awk -F. '{print $NF}'` = 'git' ]; then
        echo "Remote repos of the form repo.git are not supported: ${MOD}"
        exit 1
    fi

    MODULE_NAME=`echo $MOD | awk -F- '{print $NF}'`

    # set up git base command to use the correct path
    GIT_CMD_BASE="git --git-dir=${MODULE_PATH}/${MODULE_NAME}/.git --work-tree ${MODULE_PATH}/${MODULE_NAME}"
    # treat any occurrence of the module as a match
    if ! echo $MODULE_LIST | grep "${MODULE_NAME}" >/dev/null 2>&1; then
        # clone modules that are not installed
        git_clone $MOD "${MODULE_PATH}/${MODULE_NAME}"
    else
        if [ ! -d ${MODULE_PATH}/${MODULE_NAME}/.git ]; then
            echo "Found directory ${MODULE_PATH}/${MODULE_NAME} that is not a git repo, deleting it and reinstalling from source"
            remove_module $MODULE_NAME
            git_clone $MOD "${MODULE_PATH}/${MODULE_NAME}"
        elif [ `${GIT_CMD_BASE} remote show origin | grep 'Fetch URL' | awk -F'URL: ' '{print $2}'` != $MOD ]; then
            echo "Found remote in ${MODULE_PATH}/${MODULE_NAME} that does not match desired remote ${MOD}, deleting dir and re-cloning"
            remove_module $MODULE_NAME
            git_clone $MOD "${MODULE_PATH}/${MODULE_NAME}"
        fi
    fi

    # fetch the latest refs from the repo
    if [[ $JUST_CLONED -eq 0 ]] ; then
        # If we just cloned the repo, we do not need to remote update
        for attempt in $(seq 0 3); do
            clone_error=0
            $GIT_CMD_BASE remote update && break || true
            clone_error=1
        done
        if [[ $clone_error -ne 0 ]] ; then
            exit $clone_error
        fi
    fi
    # make sure the correct revision is installed, I have to use rev-list b/c rev-parse does not work with tags
    if [ `${GIT_CMD_BASE} rev-list HEAD --max-count=1` != `${GIT_CMD_BASE} rev-list ${SOURCE_MODULES[$MOD]} --max-count=1` ]; then
        # checkout correct revision
        $GIT_CMD_BASE checkout ${SOURCE_MODULES[$MOD]}
    fi
done
