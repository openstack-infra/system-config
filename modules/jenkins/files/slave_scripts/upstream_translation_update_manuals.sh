#!/bin/bash -xe

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
# because there is a existing .tx folder in openstack-manuals
# tx init --host=https://www.transifex.com

# generate pot one by one
for DOCNAME in ${DocNameList}
do
    tx set --auto-local -r openstack-manuals-i18n.${DOCNAME} \
"doc/src/docbkx/${DOCNAME}/locale/<lang>.po" --source-lang en \
--source-file doc/src/docbkx/${DOCNAME}/locale/${DOCNAME}.pot \
-t PO --execute
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
done

if [ ! `git diff-index --quiet HEAD --` ]
then
    # Push .pot changes to transifex
    tx --debug --traceback push -s
fi



