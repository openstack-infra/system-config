#!/bin/bash -xe

# Copyright 2014 IBM Corp.
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

# The script is to push the updated English po to Transifex.

PROJECT="horizon"

if [ ! `echo $ZUUL_REFNAME | grep master` ]
then
    exit 0
fi

git config user.name "OpenStack Jenkins"
git config user.email "jenkins@openstack.org"

# initialize transifex client
tx init --host=https://www.transifex.com
# Horizon JavaScript Translations
tx set --auto-local -r ${PROJECT}.${PROJECT}-js-translations \
"${PROJECT}/locale/<lang>/LC_MESSAGES/djangojs.po" --source-lang en \
--source-file ${PROJECT}/locale/en/LC_MESSAGES/djangojs.po -t PO --execute
# Horizon Translations
tx set --auto-local -r ${PROJECT}.${PROJECT}-translations \
"${PROJECT}/locale/<lang>/LC_MESSAGES/django.po" --source-lang en \
--source-file ${PROJECT}/locale/en/LC_MESSAGES/django.po -t PO --execute
# OpenStack Dashboard Translations
tx set --auto-local -r ${PROJECT}.openstack-dashboard-translations \
"openstack_dashboard/locale/<lang>/LC_MESSAGES/django.po" --source-lang en \
--source-file openstack_dashboard/locale/en/LC_MESSAGES/django.po -t PO --execute

# Invoke run_tests.sh to update the po files
# Or else, "../manage.py makemessages" can be used.
./run_tests.sh --makemessages

# Add all changed files to git
git add ${PROJECT}/locale/en/LC_MESSAGES/*
git add openstack_dashboard/locale/en/LC_MESSAGES/*

if [ `git diff --cached | egrep -v "(POT-Creation-Date|^[\+\-]#|^\+{3}|^\-{3})" | egrep -c "^[\-\+]"` -gt 0 ] ]
then
    # Push source file changes to transifex
    tx --debug --traceback push -s
fi

