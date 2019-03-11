#!/bin/bash

# line in format
#  repo local-branch remote-branch change

while read line;
do
    todo=($line)
    change=${todo[3]}
    prefix='echo '
    if [[ ${DOIT:-0} == 1 ]]; then
	prefix=''
    fi
    $prefix ssh -n -p 29418 iwienand@review.openstack.org gerrit review -m "'The gitea transition is currently scheduled for the 19th April, 2019.  To facilitate this, infra may merge this change around 1 week before (12th April) if no repsonse.  Thanks'" ${change}
    
done < ./to-push.txt
