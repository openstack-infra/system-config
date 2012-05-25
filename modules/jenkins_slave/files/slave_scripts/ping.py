#!/usr/bin/env python

import sys
from subprocess import Popen, PIPE

p = Popen(["ping", sys.argv[1]], stdout=PIPE)
while True:
    line = p.stdout.readline().strip()
    if 'bytes from' in line:
        p.terminate()
        sys.exit(0)
