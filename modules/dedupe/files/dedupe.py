#!/usr/bin/env python

import sys
import os

"""
Takes the output of `fdupes -r` and creates hardlinks of the duplicates
"""

link_blocks = sys.stdin.read().split("\n\n")[:-1]

for block in link_blocks:
    files = block.split("\n")
    links = files[1:]
    source = files[0]
    for link_name in links:
        print "%s -> %s" % (link_name, source)
        if ("--dry-run" not in sys.argv):
            # keep the original as a backup until the hardlink is created
            # just in case something goes wrong
            os.rename(link_name, link_name + '_tmp_dedupe_backup')
            os.link(source, link_name)
            os.unlink(link_name + '_tmp_dedupe_backup')
