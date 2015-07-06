#!/usr/bin/env

import sys
import difflib


def assert_sorted(lines):
    if lines == sorted(lines):
        return True
    else:
        print "Modules not sorted:"
        diff = difflib.context_diff(lines, sorted(lines))
        print '\n'.join(list(diff))
        sys.exit(1)


with open(sys.argv[1]) as f:
    lines = f.readlines()

integration = [i.rstrip() for i in lines if i.startswith('INTEGRATION')]
source = [i.rstrip() for i in lines if i.startswith('SOURCE')]

assert_sorted(integration)
assert_sorted(source)
