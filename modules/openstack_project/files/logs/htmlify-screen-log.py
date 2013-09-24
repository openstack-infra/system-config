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
import os.path
import re
import sys
import wsgiref.util


DATEFMT = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{3})?'
STATUSFMT = '(DEBUG|INFO|WARN|ERROR|TRACE|AUDIT)'
LOGMATCH = '(?P<date>%s)(?P<pid> \d+)? (?P<status>%s)' % (DATEFMT, STATUSFMT)

SEVS = {
    'NONE': 0,
    'DEBUG': 1,
    'INFO': 2,
    'AUDIT': 3,
    'TRACE': 4,
    'WARN': 5,
    'ERROR': 6
    }


def _html_close():
    return ("</span></pre></body></html>\n")


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
.selector, .selector a {color: #888}
.selector a:hover {color: #c00}
</style>
<body>
<span class='selector'>
Display level: [
<a href='?'>ALL</a> |
<a href='?level=DEBUG'>DEBUG</a> |
<a href='?level=INFO'>INFO</a> |
<a href='?level=AUDIT'>AUDIT</a> |
<a href='?level=TRACE'>TRACE</a> |
<a href='?level=WARN'>WARN</a> |
<a href='?level=ERROR'>ERROR</a> ]
</span>
<pre><span>""")


def sev_of_line(line, oldsev="NONE"):
    m = re.match(LOGMATCH, line)
    if m:
        return m.group('status')
    else:
        return oldsev


def color_by_sev(line, sev):
    """Wrap a line in a span whose class matches it's severity."""
    return "<span class='%s'>%s</span>" % (sev, line)


def escape_html(line):
    """Escape the html in a line.

    We need to do this because we dump xml into the logs, and if we don't
    escape the xml we end up with invisible parts of the logs in turning it
    into html.
    """
    return cgi.escape(line)


def link_timestamp(line):
    m = re.match(
        '(<span class=\'(?P<class>[^\']+)\'>)?(?P<date>%s)(?P<rest>.*)' % DATEFMT,
        line)
    if m:
        date = "_" + re.sub('[\s\:\.]', '_', m.group('date'))

        return "</span><span class='%s %s'><a name='%s' class='date' href='#%s'>%s</a>%s\n" % (
            m.group('class'), date, date, date, m.group('date'), m.group('rest'))
    else:
        return line


def skip_line_by_sev(sev, minsev):
    """should we skip this line?

    If the line severity is less than our minimum severity,
    yes we should"""
    return SEVS.get(sev, 0) < SEVS.get(minsev, 0)


def passthrough_filter(fname, minsev):
    sev = "NONE"
    for line in fileinput.FileInput(fname, openhook=fileinput.hook_compressed):
        sev = sev_of_line(line, sev)

        if skip_line_by_sev(sev, minsev):
            continue

        yield line


def does_file_exist(fname):
    """Figure out if we'll be able to read this file.

    Because we are handling the file streams as generators, we actually raise
    an exception too late for us to be able to handle it before apache has
    completely control. This attempts to do the same open outside of the
    generator to trigger the IOError early enough for us to catch it, without
    completely changing the logic flow, as we really want the generator
    pipeline for performance reasons.

    This does open us up to a small chance for a race where the file comes
    or goes between this call and the next, however that is a vanishingly
    small possibility.
    """
    f = open(fname)
    f.close()


def html_filter(fname, minsev):
    """Generator to read logs and output html in a stream.

    This produces a stream of the htmlified logs which lets us return
    data quickly to the user, and use minimal memory in the process.
    """

    yield _css_preamble()
    sev = "NONE"
    for line in fileinput.FileInput(fname, openhook=fileinput.hook_compressed):
        newline = escape_html(line)
        sev = sev_of_line(newline, sev)
        if skip_line_by_sev(sev, minsev):
            continue
        newline = color_by_sev(newline, sev)
        newline = link_timestamp(newline)
        yield newline
    yield _html_close()


def htmlify_stdin():
    out = sys.stdout
    out.write(_css_preamble())
    for line in fileinput.FileInput():
        newline = escape_html(line)
        newline = color_by_sev(newline)
        newline = link_timestamp(newline)
        out.write(newline)
    out.write(_html_close())


def safe_path(root, environ):
    """Pull out a safe path from a url.

    Basically we need to ensure that the final computed path
    remains under the root path. If not, we return None to indicate
    that we are very sad.
    """
    path = wsgiref.util.request_uri(environ, include_query=0)
    match = re.search('htmlify/(.*)', path)
    raw = match.groups(1)[0]
    newpath = os.path.abspath(os.path.join(root, raw))
    if newpath.find(root) == 0:
        return newpath
    else:
        return None


def should_be_html(environ):
    """Simple content negotiation.

    If the client supports content negotiation, and asks for text/html,
    we give it to them, unless they also specifically want to override
    by passing ?content-type=text/plain in the query.

    This should be able to handle the case of dumb clients defaulting to
    html, but also let devs override the text format when 35 MB html
    log files kill their browser (as per a nova-api log).
    """
    text_override = False
    accepts_html = ('HTTP_ACCEPT' in environ and
                    'text/html' in environ['HTTP_ACCEPT'])
    parameters = cgi.parse_qs(environ.get('QUERY_STRING', ''))
    if 'content-type' in parameters:
        ct = cgi.escape(parameters['content-type'][0])
        if ct == 'text/plain':
            text_override = True

    return accepts_html and not text_override


def get_min_sev(environ):
    parameters = cgi.parse_qs(environ.get('QUERY_STRING', ''))
    if 'level' in parameters:
        return cgi.escape(parameters['level'][0])
    else:
        return "NONE"


def application(environ, start_response):
    status = '200 OK'

    logpath = safe_path('/srv/static/logs/', environ)
    if not logpath:
        status = '400 Bad Request'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return ['Invalid file url']

    try:
        minsev = get_min_sev(environ)
        if should_be_html(environ):
            response_headers = [('Content-type', 'text/html')]
            does_file_exist(logpath)
            generator = html_filter(logpath, minsev)
            start_response(status, response_headers)
            return generator
        else:
            response_headers = [('Content-type', 'text/plain')]
            does_file_exist(logpath)
            generator = passthrough_filter(logpath, minsev)
            start_response(status, response_headers)
            return generator
    except IOError:
        status = "404 Not Found"
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return ['File Not Found']


# for development purposes, makes it easy to test the filter output
if __name__ == "__main__":
    htmlify_stdin()
