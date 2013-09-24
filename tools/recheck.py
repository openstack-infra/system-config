#!/usr/bin/env python

# Copyright 2013 IBM Corp.
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

import argparse
import getpass
import sys

import gerritlib.gerrit


def get_options(argv):
    parser = argparse.ArgumentParser(
        description='Programatically recheck bugs based on different criteria')
    parser.add_argument('-p', '--project', required=True,
            help='Name of project to run rechecks on old patches')
    parser.add_argument('-d', '--days', default=5,
                         help='Number of days old a review should be before '
                         'we auto recheck it')
    parser.add_argument('-u', '--user', default=getpass.getuser(),
                         help='gerrit user')
    parser.add_argument('-k', '--key', default=None,
                         help='ssh key for gerrit')

    return parser.parse_args()


def main(argv=None):
    opts = get_options(argv)
    gerrit = gerritlib.gerrit.Gerrit("review.openstack.org", opts.user,
                                     keyfile=opts.key)

    reviews = gerrit.bulk_query(
        "status:open project:%s age:%dd --patch-sets" %
        (opts.project, opts.days))

    for review in reviews:
        print review
        revid = review.get('number')
        if revid:
            number = review['patchSets'][-1]['number']
            change = "%s,%s" % (revid, number)
            # # print revid
            gerrit.review(opts.project, change, "recheck no bug")
            gerrit.review(opts.project, change, "rechecking because review is "
                          "older than %d days, and is at risk of merge "
                          "conflict." % opts.days
                          )

if __name__ == '__main__':
    sys.exit(main())
