#!/bin/bash

# Copyright 2012 Hewlett-Packard Development Company, L.P.
# Copyright 2013 OpenStack Foundation
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

# Find out if jenkins has attempted to run any sudo commands by checking
# the auth.log or secure log files before and after a test run.

case $( facter osfamily ) in
    Debian)
	PATTERN="sudo.*jenkins.*:.*incorrect password attempts"
	OLDLOGFILE=/var/log/auth.log.1
	LOGFILE=/var/log/auth.log
	;;
    RedHat)
	PATTERN="sudo.*jenkins.*:.*command not allowed"
	OLDLOGFILE=$( ls /var/log/secure-* | sort | tail -n1 )
	LOGFILE=/var/log/secure
	;;
esac

case "$1" in
    pre)
	rm -fr /tmp/jenkins-sudo-log
	mkdir /tmp/jenkins-sudo-log
	if [ -f $OLDLOGFILE ]
	then
	    stat -c %Y $OLDLOGFILE > /tmp/jenkins-sudo-log/mtime-pre
	else
	    echo "0" > /tmp/jenkins-sudo-log/mtime-pre
	fi
	grep -h "$PATTERN" $LOGFILE > /tmp/jenkins-sudo-log/pre
	exit 0
	;;
    post)
	if [ -f $OLDLOGFILE ]
	then
	    stat -c %Y $OLDLOGFILE > /tmp/jenkins-sudo-log/mtime-post
	else
	    echo "0" > /tmp/jenkins-sudo-log/mtime-post
	fi
	if ! diff /tmp/jenkins-sudo-log/mtime-pre /tmp/jenkins-sudo-log/mtime-post > /dev/null
	then
	    echo "diff"
	    grep -h "$PATTERN" $OLDLOGFILE > /tmp/jenkins-sudo-log/post
	fi
	grep -h "$PATTERN" $LOGFILE >> /tmp/jenkins-sudo-log/post
	diff /tmp/jenkins-sudo-log/pre /tmp/jenkins-sudo-log/post
	;;
esac
