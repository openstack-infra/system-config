#!/usr/bin/python

import cgi
import fileinput
import re
import sys

DATEFMT = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d{3})?'
STATUSFMT = '(DEBUG|INFO|WARN|ERROR|TRACE|AUDIT)'
LOGMATCH = '(?P<date>%s)(?P<pid> \d+)? (?P<status>%s)' % (DATEFMT, STATUSFMT)


def write_html_close(writer):
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
                  '\g<span><a name="\g<date>" class="date" href="#\g<date>">\g<date></a>', line)


def htmlify_stdin():
    out = sys.stdout
    write_css_preamble(out)
    for line in fileinput.input(openhook=fileinput.hook_compressed):
        newline = escape_html(line)
        newline = color_by_sev(newline)
        newline = link_timestamp(newline)
        out.write(newline)
    write_html_close(out)


def main():
    htmlify_stdin()


if __name__ == "__main__":
    main()
