#!/usr/bin/python
#
# Copyright (c) 2013 IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import cgi
import re
import sys

DATEFMT = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{3})?'
STATUSFMT = '(DEBUG|INFO|WARN|ERROR|TRACE|AUDIT)'
LOGMATCH = '(?P<date>%s)(?P<pid> \d+)? (?P<status>%s)' % (DATEFMT, STATUSFMT)


def write_html_close(writer):
    """Be nice, close our html."""
    writer.write("</pre></body></html>\n")


def write_css_preamble(writer):
    """Write a valid html start with css that we need."""
    writer.write("""<html>
<head>
<style>
a {color: #000; text-decoration: none}
a:hover {text-decoration: underline}
.DEBUG, .DEBUG a {color: #888}
.ERROR, .ERROR a {color: #c00; font-weight: bold}
.TRACE, .TRACE a {color: #c60}
.WARN, .WARN a {color: #D89100;  font-weight: bold}
.INFO, .INFO a {color: #006; font-weight: bold}
</style>
<body>
<pre>
""")


def color_by_sev(line):
    """Wrap a line in a span whose class matches it's severity."""
    m = re.match(LOGMATCH, line)
    if m:
        return "<span class='%s'>%s</span>" % (m.group('status'), line)
    else:
        return line


def escape_html(line):
    """Escape the html in a line.

    We need to do this because we dump xml into the logs, and if we don't
    escape the xml we end up with invisible parts of the logs in turning it
    into html.
    """
    return cgi.escape(line)


def link_timestamp(line):
    """Look for a standard date format and make it a link.

    This allows us to have hot links into the log files by timestamp. It should
    work for most of the openstack services that use the common log format.
    """
    return re.sub('^(?P<span><span[^>]*>)?(?P<date>%s)' % DATEFMT,
                  ('\g<span><a name="\g<date>" '
                   'class="date" href="#\g<date>">\g<date></a>'),
                  line)


def htmlify_log(fname):
    """Take in a file an turn it into a .html version.

    This works by processing the log in order:
      * add preamble
      * escape existing text
      * add span tags for log levels
      * add anchors for timestamps
      * close the html
    """
    with open("%s.html" % fname, "w") as out:
        write_css_preamble(out)
        with open(fname, 'r') as f:
            for line in f:
                newline = escape_html(line)
                newline = color_by_sev(newline)
                newline = link_timestamp(newline)
                out.write(newline)
        out.write("</pre></body></html>\n")


def main():
    for fname in sys.argv[1:]:
        print "HTMLifying %s to %s.html" % (fname, fname)
        htmlify_log(fname)

if __name__ == "__main__":
    main()
