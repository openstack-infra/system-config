#!/bin/sh
sleep $((RANDOM%600)) && \
flock -n /var/run/gziplogs.lock \
find /srv/static/logs/ -depth \
    \( \
      \( -type f -not -name robots.txt -not -name \*.gz \
          \( -name \*.txt -or -name \*.html -or -name tmp\* \) \
          -exec gzip \{\} \; \) \
      -o \( -type f -mtime +183 -name \*.gz -execdir rm \{\} \; \) \
      -o \( -type d -empty -mtime +1 -execdir rmdir {} \; \) \
    \)
