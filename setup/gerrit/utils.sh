#!/usr/bin/env bash

# reset_project contrail-controller

function set_date {
  date=`ssh anantha@fedora-build03 date`
  hwclock --set --date="$date" && hwclock -s
  date --set "$date"
}

function puppet_install {
  apt-get -y install git python-pip ruby puppet git-review
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

function create_ci_users {
  cat $HOME/.ssh/id_rsa.pub | ssh -qp 29418 review.opencontrail.org gerrit create-account --group "'Continuous Integration Tools'" --full-name "'Zuul'" --email zuul@lists.opencontrail.org --ssh-key - zuul
  cat $HOME/.ssh/id_rsa.pub | ssh -qp 29418 review.opencontrail.org gerrit create-account --group "'Continuous Integration Tools'" --full-name "'Jenkins'" --email jenkins@lists.opencontrail.org --ssh-key - jenkins
}

function gerrit_cmd {
  ssh -qp 29418 review.opencontrail.org gerrit $*
}

function abandon_all_reviews {
  ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit query --patch-sets status:open |\grep revision | awk '{print $2}' | xargs ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit review --abandon
}

function add_review {
  export FILE=1 && echo hello > $FILE && git add $FILE && git commit -m "sample commit" $FILE && git review -y

  echo 1 >> README.md && git commit -m "sample commit" . && git review -y
}

function list_reviews {
    ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit query --patch-sets status:open
}

# Pass revision id
function delete_review {
    ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit query --patch-sets status:abandoned |\grep revision | awk '{print $2}' | xargs ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit review --delete $1
}

# deleted abandoned

# ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit gsql
#     update changes set status='d';
#     update patch_sets set draft='Y';
# ssh -p 29418 opencontrail-admin@review.opencontrail.org gerrit flush-caches --all

function flip_jenkins_job {
    java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 disable-job gate-contrail-controller-build
    java -jar jenkins-cli.jar -s http://jenkins.opencontrail.org:8080 enable-job gate-contrail-controller-build
}

function create_sample_review() {
    export FILE=$1 && git checkout origin/master && git checkout test$FILE && echo hello > $FILE && git add $FILE && git commit -m "sample commit" $FILE && git review
}
