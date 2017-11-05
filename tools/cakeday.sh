#!/bin/bash
if [[ $# < 3 ]]; then
    echo "Usage: $0 myuser sshkey ciuser"
    exit 1
fi

myuser=$1
sshkey=$2
ciuser=$3

date -d @$(ssh -i $sshkey -p 29418 $ciuser@review.openstack.org "gerrit query --format=JSON owner:'$myuser' is:merged" | tail -n 2 | head -n 1 | python -c "import sys, json; print(json.loads(sys.stdin.read())['createdOn'])")
