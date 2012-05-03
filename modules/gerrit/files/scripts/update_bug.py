#!/usr/bin/env python
# Copyright (c) 2011 OpenStack, LLC.
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

from launchpadlib.launchpad import Launchpad
from launchpadlib.uris import LPNET_SERVICE_ROOT
import os
import argparse
import re
import subprocess


BASE_DIR = '/home/gerrit2/review_site'
GERRIT_CACHE_DIR = os.path.expanduser(os.environ.get('GERRIT_CACHE_DIR',
                                '~/.launchpadlib/cache'))
GERRIT_CREDENTIALS = os.path.expanduser(os.environ.get('GERRIT_CREDENTIALS',
                                '~/.launchpadlib/creds'))


def add_change_proposed_message(bugtask, change_url, project, branch):
    subject = 'Fix proposed to %s (%s)' % (short_project(project), branch)
    body = 'Fix proposed to branch: %s\nReview: %s' % (branch, change_url)
    bugtask.bug.newMessage(subject=subject, content=body)


def add_change_merged_message(bugtask, change_url, project, commit,
                              submitter, branch, git_log):
    subject = 'Fix merged to %s (%s)' % (short_project(project), branch)
    git_url = 'http://github.com/%s/commit/%s' % (project, commit)
    body = '''Reviewed:  %s
Committed: %s
Submitter: %s
Branch:    %s\n''' % (change_url, git_url, submitter, branch)
    body = body + '\n' + git_log
    bugtask.bug.newMessage(subject=subject, content=body)


def set_in_progress(bugtask, launchpad, uploader, change_url):
    """Set bug In progress with assignee being the uploader"""

    # Retrieve uploader from Launchpad. Use email as search key if
    # provided, and only set if there is a clear match.
    try:
        searchkey = uploader[uploader.rindex("(") + 1:-1]
    except ValueError:
        searchkey = uploader
    persons = launchpad.people.findPerson(text=searchkey)
    if len(persons) == 1:
        bugtask.assignee = persons[0]

    bugtask.status = "In Progress"
    bugtask.lp_save()


def set_fix_committed(bugtask):
    """Set bug fix committed"""

    bugtask.status = "Fix Committed"
    bugtask.lp_save()


def release_fixcommitted(bugtask):
    """Set bug FixReleased if it was FixCommitted"""

    if bugtask.status == u'Fix Committed':
        bugtask.status = "Fix Released"
        bugtask.lp_save()


def tag_in_branchname(bugtask, branch):
    """Tag bug with in-branch-name tag (if name is appropriate)"""

    lp_bug = bugtask.bug
    branch_name = branch.replace('/', '-')
    if branch_name.replace('-', '').isalnum():
        lp_bug.tags = lp_bug.tags + ["in-%s" % branch_name]
        lp_bug.tags.append("in-%s" % branch_name)
        lp_bug.lp_save()


def short_project(full_project_name):
    """Return the project part of the git repository name"""
    return full_project_name.split('/')[-1]


def git2lp(full_project_name):
    """Convert Git repo name to Launchpad project"""
    project_map = {
        'openstack/python-cinderclient': 'cinder',
        'openstack/python-glanceclient': 'glance',
        'openstack/python-keystoneclient': 'keystone',
        'openstack/python-melangeclient': 'melange',
        'openstack/python-novaclient': 'nova',
        'openstack/python-quantumclient': 'quantum',
        'openstack/openstack-ci-puppet': 'openstack-ci',
        'openstack-ci/devstack-gate': 'openstack-ci',
        }
    return project_map.get(full_project_name, short_project(full_project_name))


def process_bugtask(launchpad, bugtask, git_log, args):
    """Apply changes to bugtask, based on hook / branch..."""

    if args.hook == "change-merged":
        if args.branch == 'master':
            set_fix_committed(bugtask)
        elif args.branch == 'milestone-proposed':
            release_fixcommitted(bugtask)
        else:
            tag_in_branchname(bugtask, args.branch)
        add_change_merged_message(bugtask, args.change_url, args.project,
                                  args.commit, args.submitter, args.branch,
                                  git_log)

    if args.hook == "patchset-created":
        if args.branch == 'master':
            set_in_progress(bugtask, launchpad, args.uploader, args.change_url)
        if args.patchset == '1':
            add_change_proposed_message(bugtask, args.change_url,
                                        args.project, args.branch)


def find_bugs(launchpad, git_log, args):
    """Find bugs referenced in the git log and return related bugtasks"""

    bug_regexp = r'([Bb]ug|[Ll][Pp])[\s#:]*(\d+)'
    tokens = re.split(bug_regexp, git_log)

    # Extract unique bug tasks
    bugtasks = {}
    for token in tokens:
        if re.match('^\d+$', token) and (token not in bugtasks):
            try:
                lp_bug = launchpad.bugs[token]
                for lp_task in lp_bug.bug_tasks:
                    if lp_task.bug_target_name == git2lp(args.project):
                        bugtasks[token] = lp_task
                        break
            except KeyError:
                # Unknown bug
                pass

    return bugtasks.values()


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

    # Connect to Launchpad
    launchpad = Launchpad.login_with('Gerrit User Sync', LPNET_SERVICE_ROOT,
                                     GERRIT_CACHE_DIR,
                                     credentials_file=GERRIT_CREDENTIALS,
                                     version='devel')

    # Get git log
    git_log = extract_git_log(args)

    # Process bugtasks found in git log
    for bugtask in find_bugs(launchpad, git_log, args):
        process_bugtask(launchpad, bugtask, git_log, args)


if __name__ == '__main__':
    main()
