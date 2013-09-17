#!/bin/bash
#
# Copyright 2013  OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Drupal site deploy tool. Install and setup Drupal from a distribution file.
#
# See drupal_site_deploy.sh --help for further parameters and examples.
#
# Basic deployment flow:
#   1. clean-up destination directory (optional)
#   2. extract dist tarball to destination with proper permissions,
#      create settings.php and files directory under sites/default
#   3. install drupal with drush si command, setup admin password and 
#      proper filename, and repair sites/default/files ownership
#   4. create flag-file that marks successfull installation (optional)

site_admin_user=admin
profile_name=standard
file_group=www-data
file_owner=ubuntu

_print_help() {
  echo "$(basename "$0") -- Deploy and configure a Drupal site from distribution file

## Global options ##

  -st, --site-tarball <tar-file>        source tarball file used for deployment
  -db, --db-url <db-url>                database url: mysql://user:pass@hostname[:port]/dbname
  -sn, --site-name <sitename>           name of the website
  -su, --site-admin-user <username>     username of admin account
  -sp, --site-admin-password <password> password of admin account
  -pn, --profile-name <profilename>     profile used to install (defaults to standard)
  -p, --prepare                         prepare for deployment, but skip the install phase
  -c, --clean                           clean target directory
  -dst, --dest-dir <target-directory>   target directory
  -ff, --flag-file <flagfile>           create a flagfile after successfull run
  -bu, --base-url <base-url>            base_url parameter of settings.php
  -in, --config                         read parameters from configuration file
  -fo, --file-owner <user>              file owner
  -fg, --file-group <group>             group owner
  -h, --help                            display this help


## Examples ##

install using cli parameters:

  drupal_site_deploy.sh -st drupal-7.23.tar.gz -pn standard \\
    --db-url mysql://root:pass@localhost:port/dbname \\
    --site-name drupal-dev.local \\
    --site-admin-user admin \\
    --site-admin-password Wr5pUF@f8*Wr

install using config file params:

  drupal_site_deploy.sh -in l10n-dev.config
"
}

_set_args() {
  while [ "$1" != "" ]; do
    case $1 in 
      "-st" | "--site-tarball")
        shift
        site_tarball=$1
        ;;
      "-db" | "--db-url")
        shift
        db_url=$1
        ;;
      "-sn" | "--site-name")
        shift
        site_name=$1
        ;;
      "-su" | "--site-admin-user")
        shift
        site_admin_user=$1
        ;;
      "-sp" | "--site-admin-password")
        shift
        site_admin_password=$1
        ;;
      "-pn" | "--profile-name")
        shift
        profile_name=$1
        ;;
      "-p" | "--prepare")
        is_prepare=true
        ;;
      "-c" | "--clean")
        is_clean=true
        ;;
      "-dst" | "--dest-dir")
        shift
        dest_dir=$1
        ;;
      "-ff" | "--flag-file")
        shift
        flag_file=$1
        ;;
      "-bu" | "--base-url")
        shift
        base_url=$1
        ;;
      "-in" | "--config-file")
        shift
        config_rc=$1
        ;;
      "-fo" | "--file-owner")
        shift
        file_owner=$1
        ;;
      "-fg" | "--file-group")
        shift
        file_group=$1
        ;;
      "-h" | "--help")
        _print_help
        exit 1
        ;;
    esac
    shift
  done
}

_validate_args() {
  if [ ! $dest_dir ]; then
    echo "Error: Mandatory parameter destination directory is missing."
    exit 1
  fi
  if [ ! -d $dest_dir ]; then
    echo "Error: Invalid destination directory: $dest_dir"
    exit 1
  fi
  if [ ! $site_tarball ]; then
    echo "Error: Mandatory parameter site tarball is missing."
    exit 1
  fi
  if [ ! -f $site_tarball ]; then
    echo "Error: Invalid site tarball file: $site_tarball"
    exit 1
  fi
  if [ ! $db_url ]; then
    echo "Error: Mandatory parameter db url is missing."
    exit 1
  fi
}

_stage_cleanup() {
  echo "cleanup site directory"
  rm -rf $dest_dir/*
}

_stage_prepare() {
  echo "prepare installation"
  umask 0027
  tar xfz $site_tarball --strip-components=1 --no-same-permissions -C $dest_dir
  cp $dest_dir/sites/default/default.settings.php $dest_dir/sites/default/settings.php
  if [ $base_url ]; then
    echo "\$base_url='$base_url';" >> $dest_dir/sites/default/settings.php
  fi
  mkdir -p $dest_dir/sites/default/files
  chmod g+rwxs $dest_dir/sites/default/files
  chown -R $file_owner:$file_group $dest_dir
  chmod 0664 $dest_dir/sites/default/settings.php
  umask 0022
}

_stage_install() {
  echo "install distribution file"
  save_dir=`pwd`
  cd $dest_dir
  drush si -y $profile_name --db-url=$db_url
  chmod 0440 $dest_dir/sites/default/settings.php
  chgrp -R www-data $dest_dir/sites/default/files
  if [ $site_name ]; then
    drush vset site_name $site_name
  fi
  if [ $site_admin_password ]; then
    drush upwd $site_admin_user --password="$site_admin_password"
  fi
  drush features-revert-all -y
  cd $save_dir
}

set -e

_set_args $*

if [ -f $config_rc ]; then
  source $config_rc
fi

_validate_args

if [ $is_clean ]; then
  _stage_cleanup
fi

_stage_prepare

if [ ! $is_prepare ]; then
  _stage_install
fi

if [ $flag_file ]; then
  touch $flag_file
  chown root:root $flag_file
fi

echo "sitedeploy completed in $SECONDS seconds."
