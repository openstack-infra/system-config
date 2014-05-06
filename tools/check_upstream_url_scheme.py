#!/usr/bin/env python
"""
Allow git:// and https:// URLs for importing upstream repositories,
but not git@
"""

import argparse

import yaml


parser = argparse.ArgumentParser()
parser.add_argument('-v', '--verbose',
                    dest='verbose',
                    default=False,
                    action='store_true',
                    )
parser.add_argument(
    'infile',
    help='path to review.projects.yaml',
)
args = parser.parse_args()

projects = yaml.load(open(args.infile, 'r'))

for p in projects:
    name = p.get('project')
    if not name:
        # not a project
        continue
    upstream = p.get('upstream')
    if args.verbose:
        print 'Checking %s: %r' % (name, upstream)
    if not upstream:
        continue
    if not (upstream.startswith('https://') or upstream.startswith('git://')):
        raise ValueError(
            'Upstream URLs should use https:// or git:// schemes (%s)' %
            p['project']
        )
