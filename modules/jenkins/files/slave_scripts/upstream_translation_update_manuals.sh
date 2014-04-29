#!/bin/bash -xe

# Copyright 2013 IBM Corp.
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

# The script is to push the updated PoT to Transifex.

DocFolder="doc"

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
for FILE in ${DocFolder}/*
do
    DOCNAME=${FILE#${DocFolder}/}
    # high-availability-guide needs to create new DocBook files
    if [ "$DOCNAME" == "high-availability-guide" ]
    then
        asciidoc -b docbook -d book -o - ${DocFolder}/high-availability-guide/ha-guide.txt \
| xsltproc -o - /usr/share/xml/docbook/stylesheet/docbook5/db4-upgrade.xsl - \
| xmllint  --format - | sed -e 's,<book,<book xml:id="bk-ha-guide",' \
| sed -e 's,<info,<?rax pdf.url="../high-availability-guide.pdf"?><info,' \
> ${DocFolder}/high-availability-guide/bk-ha-guide.xml
    fi
    # Update the .pot file
    ./tools/generatepot ${DOCNAME}
    if [ -f ${DocFolder}/${DOCNAME}/locale/${DOCNAME}.pot ]
    then 
        # Add all changed files to git
        git add ${DocFolder}/${DOCNAME}/locale/*
        # Set auto-local
        tx set --auto-local -r openstack-manuals-i18n.${DOCNAME} \
"${DocFolder}/${DOCNAME}/locale/<lang>.po" --source-lang en \
--source-file ${DocFolder}/${DOCNAME}/locale/${DOCNAME}.pot \
-t PO --execute
    fi
done

if [ ! `git diff --cached --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s
fi



