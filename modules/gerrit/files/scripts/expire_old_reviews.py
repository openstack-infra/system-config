#!/usr/bin/env python
# Copyright (c) 2012 OpenStack, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# This script is designed to expire old code reviews that have not been touched
# using the following rules:
# 1. if open and no activity in 2 weeks, expire
# 2. if negative comment and no activity in 1 week, expire

import os
import argparse
import paramiko
import json
import logging

parser = argparse.ArgumentParser()
parser.add_argument("--user", dest="user", help="Gerrit SSH user name")
parser.add_argument("--key", dest="key", help="Gerrit SSH key file")
options = parser.parse_args()

GERRIT_USER = options.user
GERRIT_SSH_KEY = "/home/gerrit2/.ssh/{0}".format(options.key)

logging.basicConfig(format='%(asctime)-6s: %(name)s - %(levelname)s - %(message)s', filename='/var/log/gerrit/expire_reviews.log')
logger= logging.getLogger('expire_reviews')
logger.setLevel(logging.INFO)

logger.info('Starting expire reviews')
logger.info('Connecting to Gerrit')

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('localhost', username=GERRIT_USER, key_filename=GERRIT_SSH_KEY, port=29418)

def expire_patch_set(patch_id, patch_subject, has_negative):
  if has_negative:
    message= 'code review expired after 1 week of no activity after a negative review'
  else:
    message= 'code review expired after 2 weeks of no activity'
  command='gerrit review --abandon --message="{0}" {1}'.format(message, patch_id)
  logger.info('Expiring: %s - %s: %s', patch_id, patch_subject, message)
  stdin, stdout, stderr = ssh.exec_command(command)
  if stdout.channel.recv_exit_status() != 0:
    logger.error(stderr.read())

# Query all open with no activity for 2 weeks
logger.info('Searching no activity for 2 weeks')
stdin, stdout, stderr = ssh.exec_command('gerrit query --current-patch-set --format JSON status:open age:2w')

for line in stdout:
  row= json.loads(line)
  if not row.has_key('rowCount'):
    expire_patch_set(row['currentPatchSet']['revision'], row['subject'], False)

# Query all reviewed with no activity for 1 week
logger.info('Searching no activity on negative review for 1 week')
stdin, stdout, stderr = ssh.exec_command('gerrit query --current-patch-set --all-approvals --format JSON status:reviewed age:1w')

for line in stdout:
  row= json.loads(line)
  if not row.has_key('rowCount'):
    # Search for negative approvals
    for approval in row['currentPatchSet']['approvals']:
      if approval['value'] == '-1':
        expire_patch_set(row['currentPatchSet']['revision'], row['subject'], True)
        break

logger.info('End expire review')
