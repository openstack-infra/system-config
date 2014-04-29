#!/bin/sh

# Projects counting for code contribution
for project in $(
    wget -qO- \
        https://git.opencontrail.org/cgit/opencontrail/governance/plain/reference/programs.yaml \
    | grep '^ *- [A-Za-z_-]\+/[A-Za-z_-]\+$' \
    | sed 's/^ *- //'
) ; do
    python email-stats.py -p $project -o out/$( basename $project ).csv
done

# Confirmed list of non-code contributors
wget -qO- \
https://git.opencontrail.org/cgit/opencontrail/governance/plain/reference/extra-atcs \
| sed -e 's/#.*//' -e 's/^\s*//' -e 's/\s*$//' -e '/^$/d' \
-e 's/[^:]*: \(.*\) (\(.*\)) .*/,\1,\2/' > out/non-code-contributors.csv
