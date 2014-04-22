#!/bin/bash

# Copyright 2012 Hewlett-Packard Development Company, L.P.
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

# Find out if jenkins has triggered the out-of-memory killer by checking
# the output of dmesg before and after a test run.

PATTERN=" invoked oom-killer: "

case "$1" in
    pre)
        rm -fr /tmp/jenkins-oom-log
        mkdir /tmp/jenkins-oom-log
        dmesg > /tmp/jenkins-oom-log/pre
        exit 0
        ;;
    post)
        dmesg > /tmp/jenkins-oom-log/post
        diff /tmp/jenkins-oom-log/{pre,post} \
            | grep "^> " | sed "s/^> //" > /tmp/jenkins-oom-log/diff
        if grep -q "$PATTERN" /tmp/jenkins-oom-log/diff
        then
            cat /tmp/jenkins-oom-log/diff
            exit 1
        fi
        ;;
esac
