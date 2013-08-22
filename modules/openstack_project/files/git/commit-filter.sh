#!/bin/sh

sed -re '
s`(I[0-9a-f]{8,40})`<a href="https://review.openstack.org/\#q,\1,n,z">\0</a>`g
s`\b([0-9a-fA-F]{8,40})\b`<a href="./?id=\1">\0</a>`g
s`(\b[Bb]ug\b|\b[Ll][Pp]\b)[ \t#:]*([0-9]+)`<a href="https://code.launchpad.net/bugs/\2">\0</a>`g
s`(\b[Bb]lue[Pp]rint\b|\b[Bb][Pp]\b)[ \t#:]*([A-Za-z0-9\.-]+)`<a href="https://blueprints.launchpad.net/openstack/?searchtext=\2">\0</a>`g
'
