#!/bin/bash -xe
#
# Copyright 2014  Hewlett-Packard Development Company, L.P.
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
#
# Upload java artifacts (Jenkins plugins and java packages) to
# maven repositories

function show_options () {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "-a ARTIFACT_TYPE (accepted values: (jenkins-plugin/java-package))"
    echo "-c CREDENTIALS_FILE (credentials file, contains user/password to access repository)"
    echo "-p PROJECT (project name)"
    echo "-s SOURCE_URL (URL of the repository where the artifact is kept)"
    echo "-t TARGET_URL (URL of the repository where the artifact will be published)"
}

function check_artifact_type_parameter () {
    if [[ -z $ARTIFACT_TYPE ]]
    then
        echo "Missing artifact type option"
        show_options
        exit 1
    fi

    if [[ "$ARTIFACT_TYPE" != "jenkins-plugin" && "$ARTIFACT_TYPE" != "java-package" ]]
    then
        echo "Invalid artifact type argument"
        show_options
        exit 1
    fi
}

function check_project_parameter () {
    if [[ -z $PROJECT ]]
    then
        echo "Missing project option"
        show_options
        exit 1
    fi
}

function set_default_values_for_missing_parameters () {
    SOURCE_URL=${SOURCE_URL:-"http://tarballs.openstack.org/ci"}

    if [[ $ARTIFACT_TYPE=="jenkins-plugin" ]]
    then
        TARGET_URL=${TARGET_URL:-"http://repo.jenkins-ci.org/list/releases/org/jenkins-ci/plugins"}
        CREDENTIALS_FILE=${CREDENTIALS_FILE:-"/home/jenkins/.jenkinsci-curl"}
    else
        TARGET_URL=${TARGET_URL:-"https://oss.sonatype.org/content/groups/public/maven"}
        CREDENTIALS_FILE=${CREDENTIALS_FILE:-"/home/jenkins/.mavencentral-curl"}
    fi
}

function generate_pom () {
    METADATA_FILENAME="${PROJECT}-$TAG.pom"

    if [[ $ARTIFACT_TYPE == "jenkins-plugin" ]]
    then
        VERSION=`echo ${PLUGIN_FILE} | sed -n "s/${PROJECT}-\(.*\).hpi/\1/p"`
    else
        VERSION=`echo ${PLUGIN_FILE} | sed -n "s/${PROJECT}-\(.*\).jar/\1/p"`
    fi

    POM_IN_ZIP=`unzip -Z -1 ${ARTIFACT_FILENAME}|grep pom.xml`
    unzip -o -j ${ARTIFACT_FILENAME} ${POM_IN_ZIP}
    sed "s/\${{project-version}}/${VERSION}/g" <pom.xml >${METADATA_FILENAME}
}


function download_artifact () {
    TAG=`echo $ZUUL_REF | sed 's/^refs.tags.//'`

    if [[ $ARTIFACT_TYPE == "jenkins-plugin" ]]
    then
        ARTIFACT_FILENAME="${PROJECT}-$TAG.hpi"
        rm -rf *.hpi
    else
        ARTIFACT_FILENAME="${PROJECT}-$TAG.jar"
        rm -fr *.jar
    fi

    curl -o $ARTIFACT_FILENAME ${SOURCE_URL}/${PROJECT}/$ARTIFACT_FILENAME
}

function publish_artifact () {
    curl -T ${METADATA_FILENAME} \
         --config ${CREDENTIALS_FILE} \
         -i \
         "${URL}/${PROJECT}/${VERSION}/${METADATA_FILENAME}" > /dev/null 2>&1
    curl -T ${ARTIFACT_FILENAME} \
         --config ${CREDENTIALS_FILE} \
         -i \
         "${URL}/${PROJECT}/${VERSION}/${ARTIFACT_FILENAME}" > /dev/null 2>&1
}

function read_options () {
    if [[ $# == 0 ]]
    then
        show_options
        exit 1
    fi

    while getopts ":a:c:p:s:t:h" opt
    do
        case $opt in
        a)  ARTIFACT_TYPE=$OPTARG
            ;;
        c)  CREDENTIALS_FILE=$OPTARG
            ;;
        p)  PROJECT=$OPTARG
            ;;
        s)  SOURCE_URL=$OPTARG;
            ;;
        t)  TARGET_URL=$OPTARG;
            ;;
        h)  show_options
            exit
            ;;
        \?) echo "Invalid option $OPTARG"
            show_options
            exit 1
            ;;
        :)  echo "-$OPTARG requires an argument"
            show_options
            exit 1
            ;;
        esac
    done
}

read_options $@
check_artifact_type_parameter
check_project_parameter
set_default_values_for_missing_parameters
download_artifact
generate_pom
publish_artifact
