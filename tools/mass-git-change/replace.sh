#!/bin/bash

to_push=$(pwd)/to-push.txt
rm -f ${to_push}
cd repos
for p in *
do
    echo $p
    pushd $p
    if git grep -q 'git://git.openstack'; then
	echo $p >> ${to_push}
    else
	popd
	continue
    fi
    git checkout -b opendev-gerrit
    git grep -l 'git://git.openstack' | xargs sed -i 's|git://git.openstack|https://git.openstack|'
    git add -A
    git commit -F- <<EOF
Replace openstack.org git:// URLs with https://
    
This is a mechanically generated change to replace openstack.org
git:// URLs with https:// equivalents.
    
This is in aid of a planned future move of the git hosting
infrastructure to a self-hosted instance of gitea (https://gitea.io),
which does not support the git wire protocol at this stage.

For more information see:

  http://lists.openstack.org/pipermail/openstack-discuss/2019-March/003603.html
    
This review should result in no functional change.
    
Story: #2004627
Task: #29701

EOF
    popd
done
	 
