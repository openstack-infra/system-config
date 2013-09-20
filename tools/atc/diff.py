#!/usr/bin/python

import csv
import sys

old = {}
new = {}

for row in csv.reader(open(sys.argv[1])):
    old[row[0]] = row

writer = csv.writer(open(sys.argv[3], 'w'))
for row in csv.reader(open(sys.argv[2])):
    if row[0] not in old:
        writer.writerow(row)
