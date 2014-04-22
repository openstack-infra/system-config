#!/usr/bin/python
"""
Utility to convert a subunit stream to an html results file.
Code is adapted from the pyunit Html test runner at
http://tungwaiyip.info/software/HTMLTestRunner.html

Takes two arguments. First argument is path to subunit log file, second
argument is path of desired output file. Second argument is optional,
defaults to 'results.html'.

Original HTMLTestRunner License:
------------------------------------------------------------------------
Copyright (c) 2004-2007, Wai Yip Tung
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name Wai Yip Tung nor the names of its contributors may be
  used to endorse or promote products derived from this software without
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

import collections
import datetime
import io
import sys
import traceback
from xml.sax import saxutils

import subunit
import testtools

__version__ = '0.1'


class TemplateData(object):
    """
    Define a HTML template for report customerization and generation.

    Overall structure of an HTML report

    HTML
    +------------------------+
    |<html>                  |
    |  <head>                |
    |                        |
    |   STYLESHEET           |
    |   +----------------+   |
    |   |                |   |
    |   +----------------+   |
    |                        |
    |  </head>               |
    |                        |
    |  <body>                |
    |                        |
    |   HEADING              |
    |   +----------------+   |
    |   |                |   |
    |   +----------------+   |
    |                        |
    |   REPORT               |
    |   +----------------+   |
    |   |                |   |
    |   +----------------+   |
    |                        |
    |   ENDING               |
    |   +----------------+   |
    |   |                |   |
    |   +----------------+   |
    |                        |
    |  </body>               |
    |</html>                 |
    +------------------------+
    """

    STATUS = {
        0: 'pass',
        1: 'fail',
        2: 'error',
        3: 'skip',
    }

    DEFAULT_TITLE = 'Unit Test Report'
    DEFAULT_DESCRIPTION = ''

    # ------------------------------------------------------------------------
    # HTML Template

    HTML_TMPL = r"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>%(title)s</title>
    <meta name="generator" content="%(generator)s"/>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    %(stylesheet)s
</head>
<body>
<script language="javascript" type="text/javascript"><!--
output_list = Array();

/* level - 0:Summary; 1:Failed; 2:All */
function showCase(level) {
    trs = document.getElementsByTagName("tr");
    for (var i = 0; i < trs.length; i++) {
        tr = trs[i];
        id = tr.id;
        if (id.substr(0,2) == 'ft') {
            if (level < 1) {
                tr.className = 'hiddenRow';
            }
            else {
                tr.className = '';
            }
        }
        if (id.substr(0,2) == 'pt') {
            if (level > 1) {
                tr.className = '';
            }
            else {
                tr.className = 'hiddenRow';
            }
        }
    }
}


function showClassDetail(cid, count) {
    var id_list = Array(count);
    var toHide = 1;
    for (var i = 0; i < count; i++) {
        tid0 = 't' + cid.substr(1) + '.' + (i+1);
        tid = 'f' + tid0;
        tr = document.getElementById(tid);
        if (!tr) {
            tid = 'p' + tid0;
            tr = document.getElementById(tid);
        }
        id_list[i] = tid;
        if (tr.className) {
            toHide = 0;
        }
    }
    for (var i = 0; i < count; i++) {
        tid = id_list[i];
        if (toHide) {
            document.getElementById('div_'+tid).style.display = 'none'
            document.getElementById(tid).className = 'hiddenRow';
        }
        else {
            document.getElementById(tid).className = '';
        }
    }
}


function showTestDetail(div_id){
    var details_div = document.getElementById(div_id)
    var displayState = details_div.style.display
    // alert(displayState)
    if (displayState != 'block' ) {
        displayState = 'block'
        details_div.style.display = 'block'
    }
    else {
        details_div.style.display = 'none'
    }
}


function html_escape(s) {
    s = s.replace(/&/g,'&amp;');
    s = s.replace(/</g,'&lt;');
    s = s.replace(/>/g,'&gt;');
    return s;
}

/* obsoleted by detail in <div>
function showOutput(id, name) {
    var w = window.open("", //url
                    name,
                    "resizable,scrollbars,status,width=800,height=450");
    d = w.document;
    d.write("<pre>");
    d.write(html_escape(output_list[id]));
    d.write("\n");
    d.write("<a href='javascript:window.close()'>close</a>\n");
    d.write("</pre>\n");
    d.close();
}
*/
--></script>

%(heading)s
%(report)s
%(ending)s

</body>
</html>
"""
    # variables: (title, generator, stylesheet, heading, report, ending)

    # ------------------------------------------------------------------------
    # Stylesheet
    #
    # alternatively use a <link> for external style sheet, e.g.
    #   <link rel="stylesheet" href="$url" type="text/css">

    STYLESHEET_TMPL = """
<style type="text/css" media="screen">
body        { font-family: verdana, arial, helvetica, sans-serif;
    font-size: 80%; }
table       { font-size: 100%; width: 100%;}
pre         { font-size: 80%; }

/* -- heading -------------------------------------------------------------- */
h1 {
        font-size: 16pt;
        color: gray;
}
.heading {
    margin-top: 0ex;
    margin-bottom: 1ex;
}

.heading .attribute {
    margin-top: 1ex;
    margin-bottom: 0;
}

.heading .description {
    margin-top: 4ex;
    margin-bottom: 6ex;
}

/* -- css div popup -------------------------------------------------------- */
a.popup_link {
}

a.popup_link:hover {
    color: red;
}

.popup_window {
    display: none;
    overflow-x: scroll;
    /*border: solid #627173 1px; */
    padding: 10px;
    background-color: #E6E6D6;
    font-family: "Ubuntu Mono", "Lucida Console", "Courier New", monospace;
    text-align: left;
    font-size: 8pt;
}

}
/* -- report --------------------------------------------------------------- */
#show_detail_line {
    margin-top: 3ex;
    margin-bottom: 1ex;
}
#result_table {
    width: 100%;
    border-collapse: collapse;
    border: 1px solid #777;
}
#header_row {
    font-weight: bold;
    color: white;
    background-color: #777;
}
#result_table td {
    border: 1px solid #777;
    padding: 2px;
}
#total_row  { font-weight: bold; }
.passClass  { background-color: #6c6; }
.failClass  { background-color: #c60; }
.errorClass { background-color: #c00; }
.passCase   { color: #6c6; }
.failCase   { color: #c60; font-weight: bold; }
.errorCase  { color: #c00; font-weight: bold; }
.hiddenRow  { display: none; }
.testcase   { margin-left: 2em; }
td.testname {width: 40%}
td.small {width: 40px}

/* -- ending --------------------------------------------------------------- */
#ending {
}

</style>
"""

    # ------------------------------------------------------------------------
    # Heading
    #

    HEADING_TMPL = """<div class='heading'>
<h1>%(title)s</h1>
%(parameters)s
<p class='description'>%(description)s</p>
</div>

"""  # variables: (title, parameters, description)

    HEADING_ATTRIBUTE_TMPL = """
<p class='attribute'><strong>%(name)s:</strong> %(value)s</p>
"""  # variables: (name, value)

    # ------------------------------------------------------------------------
    # Report
    #

    REPORT_TMPL = """
<p id='show_detail_line'>Show
<a href='javascript:showCase(0)'>Summary</a>
<a href='javascript:showCase(1)'>Failed</a>
<a href='javascript:showCase(2)'>All</a>
</p>
<table id='result_table'>
<colgroup>
<col align='left' />
<col align='right' />
<col align='right' />
<col align='right' />
<col align='right' />
<col align='right' />
<col align='right' />
<col align='right' />
</colgroup>
<tr id='header_row'>
    <td>Test Group/Test case</td>
    <td>Count</td>
    <td>Pass</td>
    <td>Fail</td>
    <td>Error</td>
    <td>Skip</td>
    <td>View</td>
    <td> </td>
</tr>
%(test_list)s
<tr id='total_row'>
    <td>Total</td>
    <td>%(count)s</td>
    <td>%(Pass)s</td>
    <td>%(fail)s</td>
    <td>%(error)s</td>
    <td>%(skip)s</td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
</tr>
</table>
"""  # variables: (test_list, count, Pass, fail, error)

    REPORT_CLASS_TMPL = r"""
<tr class='%(style)s'>
    <td class="testname">%(desc)s</td>
    <td class="small">%(count)s</td>
    <td class="small">%(Pass)s</td>
    <td class="small">%(fail)s</td>
    <td class="small">%(error)s</td>
    <td class="small">%(skip)s</td>
    <td class="small"><a href="javascript:showClassDetail('%(cid)s',%(count)s)"
>Detail</a></td>
    <td> </td>
</tr>
"""  # variables: (style, desc, count, Pass, fail, error, cid)

    REPORT_TEST_WITH_OUTPUT_TMPL = r"""
<tr id='%(tid)s' class='%(Class)s'>
    <td class='%(style)s'><div class='testcase'>%(desc)s</div></td>
    <td colspan='7' align='left'>

    <!--css div popup start-->
    <a class="popup_link" onfocus='this.blur();'
    href="javascript:showTestDetail('div_%(tid)s')" >
        %(status)s</a>

    <div id='div_%(tid)s' class="popup_window">
        <div style='text-align: right; color:red;cursor:pointer'>
        <a onfocus='this.blur();'
onclick="document.getElementById('div_%(tid)s').style.display = 'none' " >
           [x]</a>
        </div>
        <pre>
        %(script)s
        </pre>
    </div>
    <!--css div popup end-->

    </td>
</tr>
"""  # variables: (tid, Class, style, desc, status)

    REPORT_TEST_NO_OUTPUT_TMPL = r"""
<tr id='%(tid)s' class='%(Class)s'>
    <td class='%(style)s'><div class='testcase'>%(desc)s</div></td>
    <td colspan='6' align='center'>%(status)s</td>
</tr>
"""  # variables: (tid, Class, style, desc, status)

    REPORT_TEST_OUTPUT_TMPL = r"""
%(id)s: %(output)s
"""  # variables: (id, output)

    # ------------------------------------------------------------------------
    # ENDING
    #

    ENDING_TMPL = """<div id='ending'>&nbsp;</div>"""

# -------------------- The end of the Template class -------------------


class ClassInfoWrapper(object):
    def __init__(self, name, mod):
        self.name = name
        self.mod = mod

    def __repr__(self):
        return "%s" % (self.name)


class HtmlOutput(testtools.TestResult):
    """Output test results in html."""

    def __init__(self, html_file='result.html'):
        super(HtmlOutput, self).__init__()
        self.success_count = 0
        self.failure_count = 0
        self.error_count = 0
        self.skip_count = 0
        self.result = []
        self.html_file = html_file

    def addSuccess(self, test):
        self.success_count += 1
        output = test.shortDescription()
        if output is None:
            output = test.id()
        self.result.append((0, test, output, ''))

    def addSkip(self, test, err):
        output = test.shortDescription()
        if output is None:
            output = test.id()
        self.skip_count += 1
        self.result.append((3, test, output, ''))

    def addError(self, test, err):
        output = test.shortDescription()
        if output is None:
            output = test.id()
        # Skipped tests are handled by SkipTest Exceptions.
        #if err[0] == SkipTest:
        #    self.skip_count += 1
        #    self.result.append((3, test, output, ''))
        else:
            self.error_count += 1
            _exc_str = self.formatErr(err)
            self.result.append((2, test, output, _exc_str))

    def addFailure(self, test, err):
        print(test)
        self.failure_count += 1
        _exc_str = self.formatErr(err)
        output = test.shortDescription()
        if output is None:
            output = test.id()
        self.result.append((1, test, output, _exc_str))

    def formatErr(self, err):
        exctype, value, tb = err
        return ''.join(traceback.format_exception(exctype, value, tb))

    def stopTestRun(self):
        super(HtmlOutput, self).stopTestRun()
        self.stopTime = datetime.datetime.now()
        report_attrs = self._getReportAttributes()
        generator = 'subunit2html %s' % __version__
        heading = self._generate_heading(report_attrs)
        report = self._generate_report()
        ending = self._generate_ending()
        output = TemplateData.HTML_TMPL % dict(
            title=saxutils.escape(TemplateData.DEFAULT_TITLE),
            generator=generator,
            stylesheet=TemplateData.STYLESHEET_TMPL,
            heading=heading,
            report=report,
            ending=ending,
        )
        if self.html_file:
            with open(self.html_file, 'wb') as html_file:
                html_file.write(output.encode('utf8'))

    def _getReportAttributes(self):
        """Return report attributes as a list of (name, value)."""
        status = []
        if self.success_count:
            status.append('Pass %s' % self.success_count)
        if self.failure_count:
            status.append('Failure %s' % self.failure_count)
        if self.error_count:
            status.append('Error %s' % self.error_count)
        if self.skip_count:
            status.append('Skip %s' % self.skip_count)
        if status:
            status = ' '.join(status)
        else:
            status = 'none'
        return [
            ('Status', status),
        ]

    def _generate_heading(self, report_attrs):
        a_lines = []
        for name, value in report_attrs:
            line = TemplateData.HEADING_ATTRIBUTE_TMPL % dict(
                name=saxutils.escape(name),
                value=saxutils.escape(value),
            )
            a_lines.append(line)
        heading = TemplateData.HEADING_TMPL % dict(
            title=saxutils.escape(TemplateData.DEFAULT_TITLE),
            parameters=''.join(a_lines),
            description=saxutils.escape(TemplateData.DEFAULT_DESCRIPTION),
        )
        return heading

    def _generate_report(self):
        rows = []
        sortedResult = self._sortResult(self.result)
        for cid, (cls, cls_results) in enumerate(sortedResult):
            # subtotal for a class
            np = nf = ne = ns = 0
            for n, t, o, e in cls_results:
                if n == 0:
                    np += 1
                elif n == 1:
                    nf += 1
                elif n == 2:
                    ne += 1
                else:
                    ns += 1

            # format class description
            if cls.mod == "__main__":
                name = cls.name
            else:
                name = "%s" % (cls.name)
            doc = cls.__doc__ and cls.__doc__.split("\n")[0] or ""
            desc = doc and '%s: %s' % (name, doc) or name

            row = TemplateData.REPORT_CLASS_TMPL % dict(
                style=(ne > 0 and 'errorClass' or nf > 0
                       and 'failClass' or 'passClass'),
                desc = desc,
                count = np + nf + ne + ns,
                Pass = np,
                fail = nf,
                error = ne,
                skip = ns,
                cid = 'c%s' % (cid + 1),
            )
            rows.append(row)

            for tid, (n, t, o, e) in enumerate(cls_results):
                self._generate_report_test(rows, cid, tid, n, t, o, e)

        report = TemplateData.REPORT_TMPL % dict(
            test_list=''.join(rows),
            count=str(self.success_count + self.failure_count +
                      self.error_count + self.skip_count),
            Pass=str(self.success_count),
            fail=str(self.failure_count),
            error=str(self.error_count),
            skip=str(self.skip_count),
        )
        return report

    def _sortResult(self, result_list):
        # unittest does not seems to run in any particular order.
        # Here at least we want to group them together by class.
        rmap = {}
        classes = []
        for n, t, o, e in result_list:
            if hasattr(t, '_tests'):
                for inner_test in t._tests:
                    self._add_cls(rmap, classes, inner_test,
                                  (n, inner_test, o, e))
            else:
                self._add_cls(rmap, classes, t, (n, t, o, e))
        classort = lambda s: str(s)
        sortedclasses = sorted(classes, key=classort)
        r = [(cls, rmap[str(cls)]) for cls in sortedclasses]
        return r

    def _add_cls(self, rmap, classes, test, data_tuple):
        if hasattr(test, 'test'):
            test = test.test
        if test.__class__ == subunit.RemotedTestCase:
            #print(test._RemotedTestCase__description.rsplit('.', 1)[0])
            cl = test._RemotedTestCase__description.rsplit('.', 1)[0]
            mod = cl.rsplit('.', 1)[0]
            cls = ClassInfoWrapper(cl, mod)
        else:
            cls = ClassInfoWrapper(str(test.__class__), str(test.__module__))
        if not str(cls) in rmap:
            rmap[str(cls)] = []
            classes.append(cls)
        rmap[str(cls)].append(data_tuple)

    def _generate_report_test(self, rows, cid, tid, n, t, o, e):
        # e.g. 'pt1.1', 'ft1.1', etc
        # ptx.x for passed/skipped tests and ftx.x for failed/errored tests.
        has_output = bool(o or e)
        tid = ((n == 0 or n == 3) and
               'p' or 'f') + 't%s.%s' % (cid + 1, tid + 1)
        name = t.id().split('.')[-1]
        # if shortDescription is not the function name, use it
        if t.shortDescription().find(name) == -1:
            doc = t.shortDescription()
        else:
            doc = None
        desc = doc and ('%s: %s' % (name, doc)) or name
        tmpl = (has_output and TemplateData.REPORT_TEST_WITH_OUTPUT_TMPL
                or TemplateData.REPORT_TEST_NO_OUTPUT_TMPL)

        script = TemplateData.REPORT_TEST_OUTPUT_TMPL % dict(
            id=tid,
            output=saxutils.escape(o + e),
        )

        row = tmpl % dict(
            tid=tid,
            Class=((n == 0 or n == 3) and 'hiddenRow' or 'none'),
            style=(n == 2 and 'errorCase' or
                   (n == 1 and 'failCase' or 'none')),
            desc=desc,
            script=script,
            status=TemplateData.STATUS[n],
        )
        rows.append(row)
        if not has_output:
            return

    def _generate_ending(self):
        return TemplateData.ENDING_TMPL

    def startTestRun(self):
        super(HtmlOutput, self).startTestRun()


class FileAccumulator(testtools.StreamResult):

    def __init__(self):
        super(FileAccumulator, self).__init__()
        self.route_codes = collections.defaultdict(io.BytesIO)

    def status(self, **kwargs):
        if kwargs.get('file_name') != 'stdout':
            return
        file_bytes = kwargs.get('file_bytes')
        if not file_bytes:
            return
        route_code = kwargs.get('route_code')
        stream = self.route_codes[route_code]
        stream.write(file_bytes)


def main():
    if len(sys.argv) < 2:
        print("Need at least one argument: path to subunit log.")
        exit(1)
    subunit_file = sys.argv[1]
    if len(sys.argv) > 2:
        html_file = sys.argv[2]
    else:
        html_file = 'results.html'

    html_result = HtmlOutput(html_file)
    stream = open(subunit_file, 'rb')

    # Feed the subunit stream through both a V1 and V2 parser.
    # Depends on having the v2 capable libraries installed.
    # First V2.
    # Non-v2 content and captured non-test output will be presented as file
    # segments called stdout.
    suite = subunit.ByteStreamToStreamResult(stream, non_subunit_name='stdout')
    # The HTML output code is in legacy mode.
    result = testtools.StreamToExtendedDecorator(html_result)
    # Divert non-test output
    accumulator = FileAccumulator()
    result = testtools.StreamResultRouter(result)
    result.add_rule(accumulator, 'test_id', test_id=None)
    result.startTestRun()
    suite.run(result)
    # Now reprocess any found stdout content as V1 subunit
    for bytes_io in accumulator.route_codes.values():
        bytes_io.seek(0)
        suite = subunit.ProtocolTestCase(bytes_io)
        suite.run(html_result)
    result.stopTestRun()


if __name__ == '__main__':
    main()
