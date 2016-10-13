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
echo "Obtaining bandersnatch tokens and running bandersnatch."
k5start -t -f /etc/bandersnatch.keytab service/bandersnatch -- timeout -k 2m 4h run-bandersnatch

date --iso-8601=ns
echo "Bandersnatch completed successfully, running vos release."
k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release -v mirror.pypi

date --iso-8601=ns
echo "Done."
