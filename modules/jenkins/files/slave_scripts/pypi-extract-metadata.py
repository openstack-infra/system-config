#!/usr/bin/python
#
# Copyright 2012  Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Extract package info metadata for use by curl.

import pkginfo
import sys

if len(sys.argv) < 3:
    exit()

info = pkginfo.SDist(sys.argv[1])
curl_config = open(sys.argv[2], 'w')

meta_items = {
    'metadata_version': info.metadata_version,
    'summary': info.summary,
    'home_page': info.home_page,
    'author': info.author,
    'author_email': info.author_email,
    'license': info.license,
    'description': info.description,
    'keywords': info.keywords,
    'platform': info.platforms,
    'classifiers': info.classifiers,
    'download_url': info.download_url,
    'provides': info.provides,
    'requires': info.requires,
    'obsoletes': info.obsoletes,
}

for key, value in meta_items.items():
    if not value:
        continue
    if not isinstance(value, list):
        value = [value]
    for v in value:
        curl_config.write('form = "%s=%s"\n' % (key, v))

curl_config.write('\n')
curl_config.close()
