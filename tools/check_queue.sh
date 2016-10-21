#!/bin/bash
#
# Script to queue changes in the check queue, a list of changes should be in a
# file you export to an env var for prior to running the script:
#
#   export CHANGES=changes.txt
#
# This is a comma-delimited file that needs to have the project, change number
# and patchset number, for instance:
#
# openstack/nova,123456,5
# openstack/neutron,123457,2
#
# You can get the JSON for changes from Gerrit using something like:
#
# curl -o changes.json \
# https://review.openstack.org/changes/?q=status:open+Label:Workflow%253D-1?&o=CURRENT_REVISION
#
# With a json file from the Gerrit API of changes you want to see, you can use
# something like the following to generate this list:
#
#   tail -n +2 changes.json |jq -r '.[] | \
#   [.project,._number,.revisions[]._number] | @csv' |tr -d "\"" > changes.txt

while IFS=, read -r -a input; do
    sudo zuul enqueue --trigger gerrit --pipeline check --project ${input[0]} --change ${input[1]},${input[2]}
done < $CHANGES
