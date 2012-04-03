#!/bin/bash -xe

# Make sure there is a location on this builder to cache pip downloads
mkdir -p ~/cache/pip
export PIP_DOWNLOAD_CACHE=~/cache/pip

# Start with a clean slate
rm -fr jenkins_venvs
mkdir -p jenkins_venvs

# Update the list of remote refs to pick up new branches
git remote update

# Build a venv for every known branch
for branch in `git branch -r |grep "origin/"|grep -v HEAD|sed "s/origin\///"`
do
  echo "Building venv for $branch"
  git checkout $branch
  mkdir -p jenkins_venvs/$branch
  python tools/install_venv.py
  virtualenv --relocatable .venv
  if [ -e tools/test-requires ]
  then
    pip bundle .cache.bundle -r tools/pip-requires -r tools/test-requires 
  else
    pip bundle .cache.bundle -r tools/pip-requires
  fi
  tar cvfz jenkins_venvs/$branch/venv.tgz .venv .cache.bundle
  rm -fr .venv
  mv .cache.bundle jenkins_venvs/$branch/
done
git checkout master
