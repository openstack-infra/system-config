#!/bin/bash -xe

# It checks that projects.yaml alphabetized and prints list of projects that
# should be sorted.

export TMPDIR=`/bin/mktemp -d`
trap "rm -rf $TMPDIR" EXIT
if [ -f $OLDPWD/modules/openstack_project/templates/review.projects.yaml.erb ]
then
    PROJECTS_LIST=$OLDPWD/modules/openstack_project/templates/review.projects.yaml.erb
else
    PROJECTS_LIST=$OLDPWD/modules/openstack_project/files/review.projects.yaml
fi

pushd $TMPDIR

sed -e '/^- project: /!d' -e 's/^- project: //' $PROJECTS_LIST > projects_list

LC_ALL=C sort --ignore-case projects_list -o projects_list.sorted

if ! diff projects_list projects_list.sorted > projects_list.diff; then
    echo "The following projects should be alphabetized: "
    cat projects_list.diff | grep -e '> '
    exit 1
else
    echo "Projects alphabetized."
fi

popd
