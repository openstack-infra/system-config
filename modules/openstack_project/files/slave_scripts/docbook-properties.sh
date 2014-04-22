#!/bin/bash -ex

# Documentation is published to a URL depending on the branch of the
# openstack-manuals project.  This script determines what that location
# should be, and writes a properties file.  This is used by Jenkins when
# invoking certain docs jobs and made available to maven.

# In case we start doing something more sophisticated with other refs
# later (such as tags).
BRANCH=$ZUUL_REFNAME

# The master branch should get published to /trunk
if [[ $BRANCH == "master" ]]; then
    DOC_RELEASE_PATH="trunk"
    DOC_COMMENTS_ENABLED=0
elif [[ $BRANCH =~ ^stable/(.*)$ ]]; then
    # The stable/<releasename> branch should get published to /releasename, such as icehouse or havana
    DOC_RELEASE_PATH=${BASH_REMATCH[1]}
    DOC_COMMENTS_ENABLED=1
else
    echo "Error: Branch($BRANCH) is invalid"
    exit 1
fi

echo "DOC_RELEASE_PATH=$DOC_RELEASE_PATH" >gerrit-doc.properties
echo "DOC_COMMENTS_ENABLED=$DOC_COMMENTS_ENABLED" >>gerrit-doc.properties

pwd
