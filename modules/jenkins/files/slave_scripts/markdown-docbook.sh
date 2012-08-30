#!/bin/bash -e

# Documentation can be submitted in markdown and then converted to docbook
# so it can be built with the maven plugin. This is used by Jenkins when
# invoking certain docs jobs and the resulting output is made available to maven.

# In case we start doing something more sophisticated with other refs
# later (such as tags).
BRANCH=$GERRIT_REFNAME

# Need to get the file name to insert here so it can be reused for multiple projects
MD_FILENAME=$
DOCBOOK_FILENAME=$
pandoc -f markdown -t docbook -s FILENAME.md |  xsltproc -o - /usr/share/xml/docbook/stylesheet/docbook5/db4-upgrade.xsl - |  xmllint  --format - | sed -e 's,<article,<book xml:id="DOCBOOK_FILENAME",' | sed -e 's,</article>,</book> > DOCBOOK_FILENAME.xml

echo "MD_FILENAME=$MD_FILENAME" >gerrit-doc.properties
echo "DOCBOOK_FILENAME=$DOCBOOK_FILENAME" >>gerrit-doc.properties

pwd
