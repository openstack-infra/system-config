#!/usr/bin/python
#
# Copyright 2014 Rackspace Australia
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

"""
Utility to upload folders to swift using the form post middleware
credentials provided by zuul
"""

import argparse
import magic
import os
import requests
import tempfile


def generate_log_index(file_list, logserver_prefix, swift_destination_prefix):
    """Create an index of logfiles and links to them"""

    output = '<html><head><title>Index of results</title></head><body>'
    output += '<ul>'
    for f in file_list:
        file_url = os.path.join(logserver_prefix, swift_destination_prefix,
                                f['filename'])

        output += '<li>'
        output += '<a href="%s">%s</a>' % (file_url, f['filename'])
        output += '</li>'

    output += '</ul>'
    output += '</body></html>'
    return output


def make_index_file(file_list, logserver_prefix, swift_destination_prefix,
                    index_filename='index.html'):
    """Writes an index into a file for pushing"""

    index_content = generate_log_index(file_list, logserver_prefix,
                                       swift_destination_prefix)
    tempdir = tempfile.mkdtemp()
    fd = open(os.path.join(tempdir, index_filename), 'w')
    fd.write(index_content)
    return os.path.join(tempdir, index_filename)


def swift_form_post_submit(file_list, url, hmac_body, signature):
    """Send the files to swift via the FormPost middleware"""

    # We are uploading the file_list as an HTTP POST multipart encoded.
    # First grab out the information we need to send back from the hmac_body
    payload = {}

    (object_prefix,
     payload['redirect'],
     payload['max_file_size'],
     payload['max_file_count'],
     payload['expires']) = hmac_body.split('\\n')
    payload['signature'] = signature

    if len(file_list) > payload['max_file_count']:
        # We can't upload this many files! We'll do what we can but the job
        # should be reconfigured
        file_list = file_list[:payload['max_file_count']]

    files = {}

    for i, f in enumerate(file_list):
        files['file%d' % (i + 1)] = (f['filename'], open(f['path'], 'rb'),
                                     magic.from_file(f['path'], mime=True))

    requests.post(url, data=payload, files=files)


def zuul_swift_upload(file_path, swift_url, swift_hmac_body, swift_signature,
                      logserver_prefix, swift_destination_prefix):
    """Upload to swift using instructions from zuul"""

    # file_list: a list of dicts with {path=..., filename=...} where filename
    #            is appended to the end of the object (paths can be used)
    file_list = []
    if os.path.isfile(file_path):
        file_list.append({'filename': os.path.basename(file_path),
                          'path': file_path})
        index_file = file_path
    elif os.path.isdir(file_path):
        for path, folders, files in os.walk(file_path):
            for f in files:
                full_path = os.path.join(path, f)
                relative_name = os.path.relpath(full_path, file_path)
                file_list.append({'filename': relative_name,
                                  'path': full_path})
        index_file = make_index_file(file_list, logserver_prefix,
                                     swift_destination_prefix)
        file_list.append({'filename': os.path.basename(index_file),
                          'path': index_file})

    swift_form_post_submit(file_list, swift_url, swift_hmac_body,
                           swift_signature)

    return (logserver_prefix + swift_destination_prefix +
            os.path.basename(index_file))


def grab_args():
    """Grab and return arguments"""
    parser = argparse.ArgumentParser(
        description="Upload results to swift using instructions from zuul"
    )
    parser.add_argument('-n', '--name', default="logs",
                        help='The instruction-set to use')
    parser.add_argument('files', nargs='+', help='the file(s) to upload')

    return parser.parse_args()

if __name__ == '__main__':
    args = grab_args()
    for file_path in args.files:
        try:
            result_url = zuul_swift_upload(
                file_path,
                os.environ['SWIFT_%s_URL' % args.name],
                os.environ['SWIFT_%s_HMAC_BODY' % args.name],
                os.environ['SWIFT_%s_SIGNATURE' % args.name],
                os.environ['SWIFT_%s_LOGSERVER_PREFIX' % args.name],
                os.environ['SWIFT_%s_DESTINATION_PREFIX' % args.name]
            )
            print result_url
        except KeyError as e:
            print 'Environment variable %s not found' % e
