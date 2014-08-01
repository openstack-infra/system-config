#!/bin/sh
sleep $((RANDOM%600)) && \
flock -n /var/run/gziplogs.lock \
find -O3 /srv/static/logs/ -depth -not -name robots.txt -not -name lost+found \
        -not -wholename /srv/static/logs/help/\* \( \
    \( -type f -mmin +10 -not -name \*\[.-\]gz -not -name \*\[._-\]\[zZ\] \
        \( -name \*.txt -or -name \*.html -or -name tmp\* \) \
        -exec gzip \{\} \; \) \
    -o \( -type f -mtime +120 -execdir rm \{\} \; \) \
    -o \( -type d -empty -mtime +1 -execdir rmdir {} \; \) \)
find -O3 /srv/static/docs-draft/ -depth -not -name lost+found \( \
    \( -type f -mtime +21 -execdir rm \{\} \; \) \
    -o \( -type d -empty -mtime +1 -execdir rmdir {} \; \) \)
