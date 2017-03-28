#!/bin/bash

# Copyright 2016 IBM Corp.
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

set -e

date --iso-8601=ns
echo "Obtaining gem tokens and running gem mirror."
k5start -t -f /etc/gem.keytab service/gem-mirror -- timeout -k 2m 30m sudo -H -u rubygems bash -c 'gem mirror'

date --iso-8601=ns
echo "Gem mirror completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v mirror.gem

date --iso-8601=ns
echo "Done."
