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
import sys
import tempfile
import time


def generate_log_index(file_list, logserver_prefix, swift_destination_prefix):
    """Create an index of logfiles and links to them"""

    output = '<html><head><title>Index of results</title></head><body>'
    output += '<ul>'
    for f in file_list:
        file_url = os.path.join(logserver_prefix, swift_destination_prefix, f)
        # Because file_list is simply a list to create an index for and it
        # isn't necessarily on disk we can't check if a  file is a folder or
        # not. As such we normalise the name to get the folder/filename but
        # then need to check if the last character was a trailing slash so to
        # re-append it to make it obvious that it links to a folder
        filename_postfix = '/' if f[-1] == '/' else ''
        filename = os.path.basename(os.path.normpath(f)) + filename_postfix
        output += '<li>'
        output += '<a href="%s">%s</a>' % (file_url, filename)
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


def get_file_mime(file_path):
    """Get the file mime using libmagic"""

    if not os.path.isfile(file_path):
        return None

    if hasattr(magic, 'from_file'):
        return magic.from_file(file_path, mime=True)
    else:
        # no magic.from_file, we might be using the libmagic bindings
        m = magic.open(magic.MIME)
        m.load()
        return m.file(file_path).split(';')[0]


def swift_form_post_submit(file_list, url, hmac_body, signature):
    """Send the files to swift via the FormPost middleware"""

    # We are uploading the file_list as an HTTP POST multipart encoded.
    # First grab out the information we need to send back from the hmac_body
    payload = {}

    (object_prefix,
     payload['redirect'],
     payload['max_file_size'],
     payload['max_file_count'],
     payload['expires']) = hmac_body.split('\n')
    payload['signature'] = signature

    # Loop over the file list in chunks of max_file_count
    for sub_file_list in (file_list[pos:pos + int(payload['max_file_count'])]
                          for pos in xrange(0, len(file_list),
                                            int(payload['max_file_count']))):
        if payload['expires'] < time.time():
            raise Exception("Ran out of time uploading files!")
        files = {}
        # Zuul's log path is generated without a tailing slash. As such the
        # object prefix does not contain a slash and the files would be
        # uploaded as 'prefix' + 'filename'. Assume we want the destination
        # url to look like a folder and make sure there's a slash between.
        filename_prefix = '/' if url[-1] != '/' else ''
        for i, f in enumerate(sub_file_list):
            if os.path.getsize(f['path']) > int(payload['max_file_size']):
                sys.stderr.write('Warning: %s exceeds %d bytes. Skipping...\n'
                                 % (f['path'], int(payload['max_file_size'])))
                continue
            files['file%d' % (i + 1)] = (filename_prefix + f['filename'],
                                         open(f['path'], 'rb'),
                                         get_file_mime(f['path']))
        requests.post(url, data=payload, files=files)


def build_file_list(file_path, logserver_prefix, swift_destination_prefix,
                    create_dir_indexes=True):
    """Generate a list of files to upload to zuul. Recurses through directories
       and generates index.html files if requested."""

    # file_list: a list of dicts with {path=..., filename=...} where filename
    #            is appended to the end of the object (paths can be used)
    file_list = []
    if os.path.isfile(file_path):
        file_list.append({'filename': os.path.basename(file_path),
                          'path': file_path})
    elif os.path.isdir(file_path):
        if file_path[-1] == os.sep:
            file_path = file_path[:-1]
        parent_dir = os.path.dirname(file_path)
        for path, folders, files in os.walk(file_path):
            folder_contents = []
            for f in files:
                full_path = os.path.join(path, f)
                relative_name = os.path.relpath(full_path, parent_dir)
                push_file = {'filename': relative_name,
                             'path': full_path}
                file_list.append(push_file)
                folder_contents.append(relative_name)

            for f in folders:
                full_path = os.path.join(path, f)
                relative_name = os.path.relpath(full_path, parent_dir)
                folder_contents.append(relative_name + '/')

            if create_dir_indexes:
                index_file = make_index_file(folder_contents, logserver_prefix,
                                             swift_destination_prefix)
                relative_name = os.path.relpath(path, parent_dir)
                file_list.append({
                    'filename': os.path.join(relative_name,
                                             os.path.basename(index_file)),
                    'path': index_file})

    return file_list


def grab_args():
    """Grab and return arguments"""
    parser = argparse.ArgumentParser(
        description="Upload results to swift using instructions from zuul"
    )
    parser.add_argument('--no-indexes', action='store_true',
                        help='do not generate any indexes at all')
    parser.add_argument('--no-root-index', action='store_true',
                        help='do not generate a root index')
    parser.add_argument('--no-dir-indexes', action='store_true',
                        help='do not generate a indexes inside dirs')
    parser.add_argument('-n', '--name', default="logs",
                        help='The instruction-set to use')
    parser.add_argument('files', nargs='+', help='the file(s) to upload')

    return parser.parse_args()


if __name__ == '__main__':
    args = grab_args()
    file_list = []
    root_list = []

    try:
        logserver_prefix = os.environ['SWIFT_%s_LOGSERVER_PREFIX' % args.name]
        swift_destination_prefix = os.environ['LOG_PATH']
        swift_url = os.environ['SWIFT_%s_URL' % args.name]
        swift_hmac_body = os.environ['SWIFT_%s_HMAC_BODY' % args.name]
        swift_signature = os.environ['SWIFT_%s_SIGNATURE' % args.name]
    except KeyError as e:
        print 'Environment variable %s not found' % e
        quit()

    for file_path in args.files:
        file_path = os.path.normpath(file_path)
        if os.path.isfile(file_path):
            root_list.append(os.path.basename(file_path))
        else:
            root_list.append(os.path.basename(file_path) + '/')

        file_list += build_file_list(
            file_path, logserver_prefix, swift_destination_prefix,
            (not (args.no_indexes or args.no_dir_indexes))
        )

    index_file = ''
    if not (args.no_indexes or args.no_root_index):
        index_file = make_index_file(root_list, logserver_prefix,
                                     swift_destination_prefix)
        file_list.append({
            'filename': os.path.basename(index_file),
            'path': index_file})

    swift_form_post_submit(file_list, swift_url, swift_hmac_body,
                           swift_signature)

    print os.path.join(logserver_prefix, swift_destination_prefix,
                       os.path.basename(index_file))
