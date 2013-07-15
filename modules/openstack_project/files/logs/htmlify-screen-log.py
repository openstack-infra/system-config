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
import fileinput
import re
import sys
import wsgiref.util


DATEFMT = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{3})?'
STATUSFMT = '(DEBUG|INFO|WARN|ERROR|TRACE|AUDIT)'
LOGMATCH = '(?P<date>%s)(?P<pid> \d+)? (?P<status>%s)' % (DATEFMT, STATUSFMT)


def _html_close():
    return ("</pre></body></html>\n")


def _css_preamble():
    """Write a valid html start with css that we need."""
    return ("""<html>
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
<body><pre>\n""")


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
    return re.sub('^(?P<span><span[^>]*>)?(?P<date>%s)' % DATEFMT,
                  ('\g<span><a name="\g<date>" class="date" '
                   'href="#\g<date>">\g<date></a>'),
                  line)


def passthrough_filter(fname):
    for line in fileinput.input(fname, openhook=fileinput.hook_compressed):
        yield line


def html_filter(fname):
    """Generator to read logs and output html in a stream.

    This produces a stream of the htmlified logs which lets us return
    data quickly to the user, and use minimal memory in the process.
    """
    yield _css_preamble()
    for line in fileinput.input(fname, openhook=fileinput.hook_compressed):
        newline = escape_html(line)
        newline = color_by_sev(newline)
        newline = link_timestamp(newline)
        yield newline
    yield _html_close()


def htmlify_stdin():
    out = sys.stdout
    out.write(_css_preamble())
    for line in fileinput.input():
        newline = escape_html(line)
        newline = color_by_sev(newline)
        newline = link_timestamp(newline)
        out.write(newline)
    out.write(_html_close())


def application(environ, start_response):
    status = '200 OK'
    path = wsgiref.util.request_uri(environ)
    match = re.search('htmlify/(.*)', path)
    # TODO(sdague): scrub all .. chars out of the path, for security reasons
    fname = "/srv/static/logs/%s" % match.groups(1)[0]
    if 'HTTP_ACCEPT' in environ and 'text/html' in environ['HTTP_ACCEPT']:
        response_headers = [('Content-type', 'text/html')]
        start_response(status, response_headers)
        return html_filter(fname)
    else:
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return passthrough_filter(fname)


# for development purposes, makes it easy to test the filter output
if __name__ == "__main__":
    htmlify_stdin()
