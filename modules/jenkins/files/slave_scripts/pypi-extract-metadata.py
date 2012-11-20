#!/usr/bin/python
# Extract package info metadata for use by curl.
import pkginfo
import sys

if len(sys.argv) < 2:
    exit()

info = pkginfo.SDist('jenkins-job-builder-0.3.0.tar.gz')
curl_config = open(sys.argv[1], 'w')

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
