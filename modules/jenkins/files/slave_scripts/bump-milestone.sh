#!/bin/bash -xe

# This script store release meta information in the git repository for
# a project.  It does so on an isolated, hidden branch called
# refs/meta/openstack/release.  Because it's not under refs/heads, a
# standard clone won't retrieve it or cause it to show up in the list
# of remote branches.  The branch shares no history witht the project
# itself; it starts with its own root commit.  Jenkins is permitted to
# push directly to refs/meta/openstack/*.

GIT_HOST="review.openstack.org:29418"
PROJECT_PREFIX="openstack"

if [[ ! -e ${PROJECT} ]]; then
  git clone ssh://$GIT_HOST/$PROJECT_PREFIX/$PROJECT
fi
cd $PROJECT
git checkout master

# Get the list of meta refs
git fetch origin +refs/meta/*:refs/remotes/meta/*

# Checkout or create the meta/openstack/release branch
if ! { git branch -a |grep ^[[:space:]]*remotes/meta/openstack/release$; }
then
  git checkout --orphan release
  # Delete everything so the first commit is truly empty:
  git rm -rf .
  # git rm -rf leaves submodule directories:
  find -maxdepth 1 -not -regex '\./\.git\(/.*\)?' -not -name . -exec rm -fr {} \;
  ls -la
else
  git branch -D release || /bin/true
  git checkout -b release remotes/meta/openstack/release
fi

# Normally a branch name will just be a file, but we can have branches
# like stable/diablo, so in that case, make the "stable/" directory
# if needed:
mkdir -p `dirname $BRANCH`

# Read and update the value for the branch
if [ -e "$BRANCH" ]
then
  echo "Current contents of ${BRANCH}:"
  cat "${BRANCH}"
else
  echo "${BRANCH} does not exist. Creating it."
fi

echo "Updating ${BRANCH} to read $VALUE"
echo "$VALUE" > ${BRANCH}
git add ${BRANCH}

git commit -m "Milestone ${BRANCH} set to $VALUE"
git push origin HEAD:refs/meta/openstack/release
