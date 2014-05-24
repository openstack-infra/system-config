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

# The script is to pull the translations from Transifex,
# and push to Gerrit.

ORG="openstack"
PROJECT=$1

DocFolder="doc"
if [ $PROJECT = "api-site" ] ; then
    DocFolder="./"
fi

COMMIT_MSG="Imported Translations from Transifex"

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

setup_git
setup_review "$ORG" "$PROJECT"
setup_translation

# Generate pot one by one
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

# Pull upstream translations of files that are at least 75 %
# translated
tx pull -a -f --minimum-perc=75

# The common directory is used by the other guides, let's be more
# liberal here since teams might only translate the files used by a
# single guide. We use 8 % since that downloads the currently
# translated files.
if [ $PROJECT = "openstack-manuals" ] ; then
    tx pull -f  --minimum-perc=8 -r openstack-manuals-i18n.common
fi


for FILE in ${DocFolder}/*
do
    DOCNAME=${FILE#${DocFolder}/}
    if [ -d ${DocFolder}/${DOCNAME}/locale ]
    then
        git add ${DocFolder}/${DOCNAME}/locale/*
    fi
done

# Don't send files where the only things which have changed are the
# creation date, the version number, the revision date, or comment
# lines.
for f in `git diff --cached --name-only`
do
  if [ `git diff --cached $f |egrep -v "(POT-Creation-Date|Project-Id-Version|PO-Revision-Date|^\+{3}|^\-{3}|^[-+]#)" | egrep -c "^[\-\+]"` -eq 0 ]
  then
      git reset -q $f
      git checkout -- $f
  fi
done

# Don't send a review if nothing has changed.
if [ `git diff --cached |wc -l` -gt 0 ]
then
    # Commit and review
    git commit -F- <<EOF
$COMMIT_MSG
EOF
    git review -t transifex/translations

fi
