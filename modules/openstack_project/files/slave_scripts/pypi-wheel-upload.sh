#!/bin/bash -xe
#
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
#
# Retrieve supported python wheels and upload them to pypi with Curl.

PROJECT=$1
TARBALL_SITE=$2
TAG=`echo $ZUUL_REF | sed 's/^refs.tags.//'`

# Look in the setup.cfg to determine if a package name is specified, but
# fall back on the project name if necessary
DISTNAME=`/usr/local/jenkins/slave_scripts/pypi-extract-name.py --wheel \
    || echo $PROJECT`
# Look in the setup.cfg to see if this is a universal wheel or not
WHEELTYPE=`/usr/local/jenkins/slave_scripts/pypi-extract-universal.py`
FILENAME="$DISTNAME-$TAG.$WHEELTYPE-none-any.whl"

rm -rf *.whl
curl --fail -o $FILENAME http://$TARBALL_SITE/$PROJECT/$FILENAME

# Make sure we actually got a wheel
file -b $FILENAME | grep -i zip

twine upload -r pypi $FILENAME
