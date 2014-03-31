#!/usr/bin/env bash

# reset_project contrail-controller

function set_date {
  date=`ssh anantha@fedora-build03 date`
  hwclock --set --date="$date" && hwclock -s
  date --set "$date"
}

function puppet_install {
  apt-get -y install git python-pip ruby puppet
  sed -e s%START=no%START=yes% /etc/default/puppet > /tmp/puppet
  cp /tmp/puppet /etc/default/puppet

  sed -e 's%\[main\]%\[main\]\nserver=ci-puppetmaster.opencontrail.org\ncertname=review.opencontrail.org\npluginsync=true%' /etc/puppet/puppet.conf > /tmp/puppet.conf
  cp /tmp/puppet.conf /etc/puppet/puppet.conf

  # Upgrade pip to be 1.4+
  pip install -U pip

  # Setup time
  set_date

  # Run puppet agent
  puppet agent --test
}

function reset_project {
  PROJECT=$1
  rm -rf ~gerrit2/review_site/git/stackforge/$PROJECT.git /var/lib/jeepyb/stackforge/$PROJECT
  service gerrit restart
  ssh -qp 29418 review.opencontrail.org gerrit flush-caches
  manage-projects -dv
}

function ls_projects {
  ssh -qp 29418 review.opencontrail.org gerrit ls-projects
}

function ls_groups {
  ssh -qp 29418 review.opencontrail.org gerrit ls-groups
}

function create_zuul_user {
  cat $HOME/.ssh/id_rsa.pub | ssh -qp 29418 review.opencontrail.org gerrit create-account --group "'Continuous Integration Tools'" --full-name "'Zuul'" --email zuul@lists.opencontrail.org --ssh-key - zuul
}

function gerrit_cmd {
  ssh -qp 29418 review.opencontrail.org gerrit $*
}
