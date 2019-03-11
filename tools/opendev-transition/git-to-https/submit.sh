#!/bin/bash

while read line;
do
    todo=($line)
    change=${todo[3]}
    prefix='echo '
    if [[ ${DOIT:-0} == 1 ]]; then
	prefix=''
    fi
    $prefix ssh -n -p 29418 iwienand@review.openstack.org gerrit review --verified=+2 --workflow=+1 --code-review=+2 --submit  -m '"This change has been automatically committed to facilitate the OpenDev transition."' ${change}
done < ./to-push.txt
