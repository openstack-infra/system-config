#!/bin/bash -xe
#
# Copyright 2013  Hewlett-Packard Development Company, L.P.
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
# Upload artifacts (Jenkins plugins, java packages, pypi tarbals and wheels) to 
# maven and pypi repositories
 
function show_options () {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "-t ARTIFACT_TYPE (accepted values (jenkins-plugin/java-package/pypi-tarball/pypi-wheel))"
    echo "-u URL (url of the artifacts repository, for jenkins and java packages default to upstream repositories)"
    echo "-c CREDENTIALS_FILE (credentials file, contains user/password to access repository)"
    echo "-p PROJECT (project name)"
    echo "-m METADATA_FILENAME (metadata file, this is only used for java package uploads)"
    echo "-f ARTIFACT_FILENAME (artifact file to upload)"
}

function check_missing_url () {
    if [[ -z $URL ]]
    then
        echo "Missing url option or default value not defined"
        show_options
        exit 1
    fi
}

function check_missing_project () {
    if [[ -z $PROJECT ]]
    then 
        echo "Missing project option"
	show_options
	exit 1
    fi
}

function check_missing_artifact_filename () {
    if [[ -z $ARTIFACT_FILENAME ]]
    then
        echo "Missing artifact filename option"
	show_options
	exit 1
    fi
}

function check_missing_metadata_filename () {
    if [[ -z $METADATA_FILENAME ]]
    then
        echo "Missing metadata filename option"
	show_options
	exit 1
    fi
}

function check_required_parameters () {
    check_missing_project
    if [[ "$ARTIFACT_TYPE" == "jenkins-plugin" || "$ARTIFACT_TYPE" == "java-package" ]]
    then
        check_missing_artifact_filename
	check_missing_metadata_filename
    else
	check_missing_url
    fi
}

function generate_pom_file () {
    POM_IN_ZIP=`unzip -Z -1 ${ARTIFACT_FILENAME}|grep pom.xml`
    unzip -o -j ${ARTIFACT_FILENAME} ${POM_IN_ZIP}
    sed "s/\${{project-version}}/${VERSION}/g" <pom.xml >${METADATA_FILENAME}
}

function set_parameters () {
    case $ARTIFACT_TYPE in
    jenkins-plugin)
	URL=${URL:-"http://repo.jenkins-ci.org/list/releases/org/jenkins-ci/plugins"}
	CREDENTIALS_FILE=${CREDENTIALS_FILE:-"/home/jenkins/.jenkinsci-curl"}
        VERSION=`echo ${ARTIFACT_FILENAME} | sed -n "s/${PROJECT}-\(.*\).hpi/\1/p"`
	generate_pom_file
	;;
    java-package)
	URL=${URL:-"https://oss.sonatype.org/content/groups/public/maven"}
	CREDENTIALS_FILE=${CREDENTIALS_FILE:-"/home/jenkins/.mavencentral-curl"}
	VERSION=`echo ${ARTIFACT_FILENAME} | sed -n "s/${PROJECT}-\(.*\).jar/\1/p"`
	generate_pom_file
	;;    
    pypi-tarball)
        TAG=`echo $ZUUL_REF | sed 's/^refs.tags.//'`
        DISTNAME=`/usr/local/jenkins/slave_scripts/pypi-extract-name.py --tarball \
                  || echo $PROJECT`
        ARTIFACT_FILENAME="$DISTNAME-$TAG.tar.gz"
	;;
    pypi-wheel)
        TAG=`echo $ZUUL_REF | sed 's/^refs.tags.//'`
        DISTNAME=`/usr/local/jenkins/slave_scripts/pypi-extract-name.py --wheel \
                  || echo $PROJECT`
        WHEELTYPE=`/usr/local/jenkins/slave_scripts/pypi-extract-universal.py`
        ARTIFACT_FILENAME="$DISTNAME-$TAG-$WHEELTYPE-none-any.whl"
	;;
    *)
        echo "Missing or unknown artifact type option"
	show_options
        exit 1
	;;
    esac
} 

function upload_artifact () {
    case $ARTIFACT_TYPE in
    jenkins-plugin|java-package)
        curl -T \
             --config ${CREDENTIALS_FILE} \
             -i \
             "${URL}/${PROJECT}/${VERSION}/${METADATA_FILENAME}" > /dev/null 2>&1
        curl -T \
             --config ${CREDENTIALS_FILE} \
             -i \
             "${URL}/${PROJECT}/${VERSION}/${ARTIFACT_FILENAME}" > /dev/null 2>&1
        ;;
    pypi-tarball)
        rm -rf *tar.gz
        curl --fail -o $ARTIFACT_FILENAME http://$URL/$PROJECT/$ARTIFACT_FILENAME
        file -b $ARTIFACT_FILENAME | grep gzip
        twine upload -r pypi $ARTIFACT_FILENAME
        ;;
     pypi-wheel)
        rm -rf *.whl
	curl --fail -o $ARTIFACT_FILENAME http://$URL/$PROJECT/$ARTIFACT_FILENAME
        file -b $ARTIFACT_FILENAME | grep -i zip
        twine upload -r pypi $ARTIFACT_FILENAME
        ;;
    esac
}

function read_options () {
    if [[ $# == 0 ]] 
    then 
        show_options
        exit 1
    fi
 
    while getopts ":t:u:c:p:m:f:t:h" opt
    do
        case $opt in
            t)   ARTIFACT_TYPE=$OPTARG
	         ;;
	    u)   URL=$OPTARG
	         ;;
            c)   CREDENTIALS_FILE=$OPTARG
		 ;;
	    p)   PROJECT=$OPTARG
	         ;;	
	    m)   METADATA_FILENAME=$OPTARG
	         ;;
	    f)   ARTIFACT_FILENAME=$OPTARG
                 ;;
	    t)   TAG=$OPTARG
	         ;;
            h)   show_options
		 exit 
	         ;;	
	    \?) echo "Invalid option $OPTARG"
	         show_options
	         exit 1
	         ;;
	    :) echo "-$OPTARG requires an argument"
	         show_options
	         exit 1
	         ;;
            esac
    done
}

read_options $@
check_required_parameters
set_parameters
upload_artifact
