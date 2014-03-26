#!/usr/bin/env bash

# reset_project contrail-controller

PROJECT=$1

function puppet_install {
  apt-get -y install git python-pip
  pip install -U pip

  # Run puppet agent
  puppet agent --test
}

function reset_project() {
  PROJECT=$1
  rm -rf ~gerrit2/review_site/git/stackforge/$PROJECT.git /var/lib/jeepyb/stackforge/$PROJECT
  service gerrit restart
  manage-projects -dv
}

function list_projects() {
    ssh -qp 29418 review.opencontrail.org gerrit ls-projects
}

