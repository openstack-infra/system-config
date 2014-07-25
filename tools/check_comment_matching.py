#!/usr/bin/env python

"""
Check comment matching
"""

import argparse
import re
import sys
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('-v', '--verbose',
                    dest='verbose',
                    default=False,
                    action='store_true',
                    )
parser.add_argument(
    'infile',
    help='path to layout.yaml',
)
args = parser.parse_args()

layout = yaml.load(open(args.infile, 'r'))

# check job comments

to_check = dict(

    # add to this dict a key for each pipeline to check.  We will look
    # at the re's for comments in that pipeline and try to match the
    # string in each tuple of that key's list.  The second value is if
    # the string is expected to match in this pipeline (True) or not
    # (False)

    # to see what is really being sent by gerrit, something like
    #  $ wget http://review.openstack.org/changes/<change_id>/detail
    # will return some json with the raw strings

    check=[
        # pass
        ('Patch Set 1:\n\nrecheck bug 1234', True),

        ('Patch Set 1:\n\nrecheck no bug', True),
        ('Patch Set 1:\n\nrecheck no bug\n\nextra stuff', False),

        # fail, not a number
        ('Patch Set 1:\n\nrecheck bug abcd', False),

        # fail, not a patch number
        ('Patch Set abc:\n\nrecheck bug 123', False),

        # match workflow
        ('Patch Set 2: Workflow-1\n\nrecheck bug 1234', True),
        ('Patch Set 2: -Workflow\n\nrecheck bug 1234', True),
        ('Patch Set 2: Workflow-1\n\nrecheck bug abcd', False),

        # reverify should have bug
        ('Patch Set 2: Workflow-1\n\nreverify', False),
        ('Patch Set 2: Workflow-1\n\nreverify bug 1234', True),
        ('Patch Set 2: Workflow-1\n\nreverify bug abcd', False),
        ('Patch Set 2: Workflow-1\n\nreverify no bug', False),
    ],

    experimental=[
        ('Patch Set 1:\n\ncheck experimental', True),
        ('Patch Set 2: Workflow-1\n\ncheck experimental', True),
        ('Patch Set 2: -Workflow\n\ncheck experimental', True),
    ]
)

for p in layout['pipelines']:

    name = p['name']

    if not name in to_check:
        print "Nothing to check for pipeline %s" % (p['name'])
        continue
    print "%d checks for pipeline %s" % (len(to_check[name]),
                                         name)

    re_to_check = []

    # find all the "comment" triggers and make a list of re's to try
    for t in p['trigger']['gerrit']:
        if 'comment' in t:
            re_to_check.append(t['comment'])

    # run our check comment past all re's for this pipeline and record
    # any matches.  Then check if we were supposed to match or not.
    for check, expected in to_check[name]:
        matched = False

        for r in re_to_check:
            m = re.match(r, check)
            if m is not None:
                matched = True

        if matched != expected:
            print "failure in %s: %s %s match" % \
                (name,
                 check.encode('string_escape'),
                 "should" if expected is True else "should not")
            sys.exit(1)

    print " ... pass"

print "done!"
sys.exit(0)
