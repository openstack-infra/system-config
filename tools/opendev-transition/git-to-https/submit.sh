#!/bin/bash

ssh -p 29418 iwienand@review.openstack.org gerrit query --current-patch-set topic:opendev-gerrit-git status:open is:mergeable NOT label:'Code-Review<0' NOT label:'Workflow<0' limit:2000 | grep 'revision:' | awk '{print $2}' > to-submit.txt
todo=$(cat to-submit.txt | wc -l)

while read change;
do
    echo $todo
    todo=$(( todo-1 ))
    prefix='echo '
    if [[ ${DOIT:-0} == 1 ]]; then
        prefix=''
    fi
    $prefix ssh -n -p 29418 iwienand@review.openstack.org gerrit review --verified=+2 --workflow=+1 --code-review=+2 --submit  -m '"This change has been automatically committed to facilitate the OpenDev transition."' ${change}
    sleep 2
done < ./to-submit.txt
