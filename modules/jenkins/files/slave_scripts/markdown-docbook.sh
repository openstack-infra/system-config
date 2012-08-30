#!/bin/bash -e

# Documentation can be submitted in markdown and then converted to docbook
# so it can be built with the maven plugin. This is used by Jenkins when
# invoking certain docs jobs and the resulting output is made available to maven.

# In case we start doing something more sophisticated with other refs
# later (such as tags).
BRANCH=$ZUUL_REFNAME

# Need to get the file name to insert here so it can be reused for multiple projects
# Filenames for the known repos that could do this are openstackapi-programming.mdown
# and images-api-v2.0.md and openstackapi-programming and images-api-v2.0 are the names
# for the ID and xml filename.
MD_FILENAME=$1
DOCBOOK_FILENAME=$2
pandoc -f markdown -t docbook -s MD_FILENAME |  xsltproc -o - /usr/share/xml/docbook/stylesheet/docbook5/db4-upgrade.xsl - |  xmllint  --format - | sed -e 's,<article,<book xml:id="DOCBOOK_FILENAME",' | sed -e 's,</article>,</book> > DOCBOOK_FILENAME.xml

echo "MD_FILENAME=$MD_FILENAME" >gerrit-doc.properties
echo "DOCBOOK_FILENAME=$DOCBOOK_FILENAME" >>gerrit-doc.properties

pwd
