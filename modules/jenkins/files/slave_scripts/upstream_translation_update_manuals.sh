#!/bin/bash -xe

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

# The script is to push the updated PoT to Transifex.

DocNameList="basic-install cli-guide common openstack-block-storage-admin \
openstack-compute-admin openstack-ha openstack-install \
openstack-network-connectivity-admin openstack-object-storage-admin \
openstack-ops"

if [ ! `echo $ZUUL_REFNAME | grep master` ]
then
    exit 0
fi

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# no need to initialize transifex client,
# because there is an existing .tx folder in openstack-manuals
# tx init --host=https://www.transifex.com

# generate pot one by one
for DOCNAME in ${DocNameList}
do
    # openstack-ha needs to create new DocBook files
    if [ "$DOCNAME" == "openstack-ha" ]
    then
        asciidoc -b docbook -d book -o - doc/src/docbkx/openstack-ha/ha-guide.txt \
| xsltproc -o - /usr/share/xml/docbook/stylesheet/docbook5/db4-upgrade.xsl - \
| xmllint  --format - | sed -e 's,<book,<book xml:id="bk-ha-guide",' \
| sed -e 's,<info,<?rax pdf.url="../openstack-ha-guide-trunk.pdf"?><info,' \
> doc/src/docbkx/openstack-ha/bk-ha-guide.xml
    fi
    # Update the .pot file
    ./tools/generatepot ${DOCNAME}
    # Add all changed files to git
    git add doc/src/docbkx/${DOCNAME}/locale/*
    # Set auto-local
    tx set --auto-local -r openstack-manuals-i18n.${DOCNAME} \
"doc/src/docbkx/${DOCNAME}/locale/<lang>.po" --source-lang en \
--source-file doc/src/docbkx/${DOCNAME}/locale/${DOCNAME}.pot \
-t PO --execute
done

if [ ! `git diff --cached --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s
fi



