#!/bin/bash -xe

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# See if there is an open change in the launchpad/translations topic
# If so, amend the commit with new changes since then
previous=`ssh -p 29418 review.openstack.org gerrit query --current-patch-set status:open project:openstack/PROJECT topic:launchpad/translations | grep "^  number:" | awk '{print $2}'`
if [ "x${previous}" != "x" ] ; then
  git review -d ${previous}
  amend="--amend"
fi

tar xvfz po.tgz
rm po.tgz
for f in po/*po ; do
  lang=`echo $f | cut -f2 -d/ | cut -f1 -d.`
  if [ -d $PROJECT/locale/$lang ] ; then
    cp $f $PROJECT/locale/$lang/LC_MESSAGES/$PROJECT.po
  fi
done
python setup.py extract_messages
git add $PROJECT/locale/$PROJECT.pot
python setup.py update_catalog
for f in po/*po ; do
  lang=`echo $f | cut -f2 -d/ | cut -f1 -d.`
  if [ -d $PROJECT/locale/$lang ] ; then
    git add $PROJECT/locale/$lang/LC_MESSAGES/$PROJECT.po
  fi
done
git commit ${amend} -m "Imported Translations from Launchpad"
git review -t launchpad/translations
