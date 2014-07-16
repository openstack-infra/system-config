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
Utility to generate an index.html file containing a UL of logs/links.
"""

import argparse
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


def grab_args():
    """Grab and return arguments"""
    parser = argparse.ArgumentParser(
        description="Create an index.html linking to files passed in"
    )
    parser.add_argument('-n', '--name', default="logs",
                        help='The instruction-set to use')
    parser.add_argument(
        '-o', '--output', default="index.html",
        help='The output file to write to (relative or absolute)')
    parser.add_argument('files', nargs='+', help='the file(s) to list')

    return parser.parse_args()


if __name__ == '__main__':
    args = grab_args()

    file_list = []
    for file_path in arg.files:
         if os.path.isfile(file_path):
             file_list.append({'filename': os.path.basename(file_path),
                               'path': file_path})
         elif os.path.isdir(file_path):
             for path, folders, files in os.walk(file_path):
                 for f in files:
                     full_path = os.path.join(path, f)
                     relative_name = os.path.relpath(full_path, file_path)
                     file_list.append({'filename': relative_name,
                                       'path': full_path})

    try:
        result_path = make_index_file(
             file_list,
             os.environ['SWIFT_%s_LOGSERVER_PREFIX' % args.name],
             os.environ['LOG_PATH']
        )
        print result_path
    except KeyError as e:
        print 'Environment variable %s not found' % e
