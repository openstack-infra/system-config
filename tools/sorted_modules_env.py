#!/usr/bin/env python

import sys
import difflib


def assert_sorted(lines):
    if lines == sorted(lines):
        return True
    else:
        print "Modules not sorted:"
        for line in difflib.context_diff(lines, sorted(lines)):
            print line
        sys.exit(1)


with open(sys.argv[1]) as f:
    lines = f.readlines()

integration = [i for i in lines if i.startswith('INTEGRATION')]
source = [i for i in lines if i.startswith('SOURCE')]

assert_sorted(integration)
assert_sorted(source)
