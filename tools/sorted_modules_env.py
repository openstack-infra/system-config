#!/usr/bin/env

import sys
import difflib

# Keep a failed bit around so we can run all the tests before exiting
global failed
failed = False


def assert_sorted(lines):
    if lines == sorted(lines):
        return
    else:
        print "Modules not sorted:"
        for line in difflib.context_diff(lines, sorted(lines)):
            print line
        failed = True

with open(sys.argv[1]) as f:
    lines = f.readlines()


integration = [i for i in lines if i.startswith('INTEGRATION')]
source = [i for i in lines if i.startswith('SOURCE')]

assert_sorted(integration)
assert_sorted(source)
if failed:
    sys.exit(1)
