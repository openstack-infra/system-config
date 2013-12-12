export TMPDIR=`/bin/mktemp -d`
trap "rm -rf $TMPDIR" EXIT

pushd $TMPDIR

grep -e '- project' modules/openstack_project/templates/review.projects.yaml.erb \
    | cut -d: -f2-   `: # take everything after - project:` \
    | sed 's/^ *//g' `: # trim leading spaces` \
    | sed 's/ *$//g' `: # trim trailing spaces` \
    > projects_list

sort projects_list -o projects_list.sorted

diff projects_list projects_list.sorted > projects_list.diff

if [[ -n `cat projects_list.diff` ]]; then
    echo "The following projects should be alphabetized: "
    cat projects_list.diff | grep -e '> '
    exit 1
else
    echo "Projects alphabetized."
fi

popd
