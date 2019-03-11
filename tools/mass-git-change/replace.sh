#!/bin/bash

to_push=$(pwd)/to-push.txt
rm -f ${to_push}
cd repos
for p in *
do
    echo $p
    pushd $p
    branches="master "
    branches+=$(git branch -a | grep remotes/origin/stable/)

    for branch in $branches;
    do
	local_branch=opendev-gerrit-${branch#"remotes/origin/stable/"}
	push_branch=${branch#"remotes/origin/"}
	echo "$p / $branch"
	git checkout $branch
    
	if git grep -q 'git://git.openstack'; then
	    echo $p >> ${to_push} ${local_branch} ${push_branch}
	else
	    continue
	fi
	git checkout -b ${local_branch}
	git grep -l 'git://git.openstack' | xargs sed -i 's|git://git.openstack|https://git.openstack|'
	git add -A
	git commit -F- <<EOF
Replace openstack.org git:// URLs with https://

This is a mechanically generated change to replace openstack.org
git:// URLs with https:// equivalents.

This is in aid of a planned future move of the git hosting
infrastructure to a self-hosted instance of gitea (https://gitea.io),
which does not support the git wire protocol at this stage.

This review should result in no functional change.

Story: #2004627
Task: #29701

EOF
    done

    popd
done
	 
