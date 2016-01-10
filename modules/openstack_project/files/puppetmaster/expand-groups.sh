#!/bin/bash

# Copyright 2016 IBM, Inc
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

outdir=$(mktemp -d)
trap "rm -rf $outdir" EXIT

outfile=$outdir/generated-groups
echo "# This file is autogenerated" > $outfile

IFS=$'\n'
for line in $(</etc/ansible/groups.txt); do
    name=$(echo $line | cut -f1 -d' ')
    pattern=$(echo $line | cut -f2 -d' ')
    echo "[${name}]" >> groups.ini
    ansible "~${pattern}" --list-hosts >> groups.ini
done

cp $outfile /etc/ansible/hosts/generated-groups
