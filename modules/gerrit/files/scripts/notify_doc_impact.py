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

# This is designed to be called by a gerrit hook.  It searched new
# patchsets for strings like "bug FOO" and updates corresponding Launchpad
# bugs status.

import argparse
import re
import subprocess
import smtplib

from email.mime.text import MIMEText

BASE_DIR = '/home/gerrit2/review_site'
EMAIL_TEMPLATE = """
Hi, I'd like you to take a look at this patch for potential
documentation impact.
%s

Log:
%s
"""
DEST_ADDRESS = 'openstack-doc-core@lists.launchpad.net'

def process_impact(git_log, args):
    """Notify doc team of doc impact"""
    email_content = EMAIL_TEMPLATE % (args.change_url, git_log)
    msg = MIMEText(email_content)
    msg['Subject'] = '[%s] DocImpact review request' % args.project
    msg['From'] = 'gerrit2@review.openstack.org'
    msg['To'] = DEST_ADDRESS

    s = smtplib.SMTP('localhost')
    s.sendmail('gerrit2@review.openstack.org', DEST_ADDRESS, msg.as_string())
    s.quit()

def docs_impacted(git_log):
    """Determine if a changes log indicates there is a doc impact"""
    impact_regexp = r'DocImpact'
    return re.search(impact_regexp, git_log, re.IGNORECASE)

def extract_git_log(args):
    """Extract git log of all merged commits"""
    cmd = ['git',
           '--git-dir=' + BASE_DIR + '/git/' + args.project + '.git',
           'log', '--no-merges', args.commit + '^1..' + args.commit]
    return subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('hook')
    #common
    parser.add_argument('--change', default=None)
    parser.add_argument('--change-url', default=None)
    parser.add_argument('--project', default=None)
    parser.add_argument('--branch', default=None)
    parser.add_argument('--commit', default=None)
    #change-merged
    parser.add_argument('--submitter', default=None)
    #patchset-created
    parser.add_argument('--uploader', default=None)
    parser.add_argument('--patchset', default=None)

    args = parser.parse_args()

    # Get git log
    git_log = extract_git_log(args)

    # Process doc_impacts found in git log
    if docs_impacted(git_log):
        process_impact(git_log, args)


if __name__ == '__main__':
    main()
