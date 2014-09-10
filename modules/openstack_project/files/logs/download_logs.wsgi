#!/usr/bin/env python
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


""" Simple support for downloading a .tar.gz of an individual test result"""

import os
import re
import shutil
import tempfile
import wsgiref.util

LOG_ROOT = '/srv/static/logs'


def _application(environ, start_response,
                 tmp_dir, log_path, download_name):
    """Create a .tar.gz of log_path in
    tmp_dir/download_name.tar.gz and serve it up
    """
    try:
        base_name = os.path.join(tmp_dir, download_name)
        archive = shutil.make_archive(base_name, 'gztar', log_path)
        size = os.path.getsize(archive)
        # note wsgi handles the cleanup of this
        f = open(archive, 'r')
    except:
        # deliberately vague here to avoid leaking anything...
        status = '500 Server Error'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return ['Error creating zip archive']

    start_response('200 OK',
                   [
                       ('Content-Type', 'application/x-compressed'),
                       ('Content-Length', str(size),),
                       ('Content-Disposition',
                        'attachment; filename=%s.tar.gz' % download_name),
                   ])

    # as suggested by pep333
    if 'wsgi.file_wrapper' in environ:
        return environ['wsgi.file_wrapper'](f, 1024)
    else:
        return iter(lambda: f.read(1024), '')


def application(environ, start_response):
    # path e.g.
    #  http://logs.openstack.org/26/118226/1/gate/gate-grenade-dsvm/fb63ac0/
    req_path = wsgiref.util.request_uri(environ, include_query=0)
    match = re.search('download/(?P<path>.*)', req_path)
    if not match:
        status = '400 Bad Request'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return ['No path url']

    # build log_path to full on-disk directory.
    log_path = os.path.abspath(
        os.path.join(LOG_ROOT, match.group('path')))
    if not os.path.isdir(log_path):
        status = '400 Bad Request'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return ['No log directory %s' % log_path]

    # Check log_path starts with LOG_ROOT and has 10 elements in it;
    # this ensures our downloads are limited to a single test; e.g.
    #  "" / srv / static / logs / n / change / rev / [gate|check] / job / cs
    req_split = log_path.split('/')
    if not log_path.startswith(LOG_ROOT) or \
       len(req_split) != 10:
        status = '400 Bad Request'
        response_headers = [('Content-type', 'text/plain')]
        start_response(status, response_headers)
        return ['Invalid path request %s' % req_split]

    # create base filename as "change_rev_job_cs"
    download_name = "%s_%s_%s_%s" % (req_split[5],
                                     req_split[6],
                                     req_split[8],
                                     req_split[9])

    # tar.gz will be made and served from tmp_dir
    tmp_dir = tempfile.mkdtemp()
    try:
        return _application(environ, start_response,
                            tmp_dir, log_path, download_name)
    finally:
        shutil.rmtree(tmp_dir)

#from paste.evalexception.middleware import EvalException
#application = EvalException(application)

# Local variables:
# mode: python
# End:
