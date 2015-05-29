# Copyright 2015 Hewlett-Packard Development Company, L.P.
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

import argparse
import requests
import os
import sys
import logging
import json
import pprint
import yaml
import requests.packages.urllib3
requests.packages.urllib3.disable_warnings()

TIMEOUT = 30
PROJECTS_YAML = ('http://git.openstack.org/cgit/openstack/'
                 'governance/plain/reference/projects.yaml')


logging.basicConfig(level=logging.WARNING)


class Gerrit(object):
    def __init__(self, url, username, password):
        authclass = requests.auth.HTTPDigestAuth
        self._url = url
        self.auth = authclass(username, password)
        self.session = requests.Session()
        self.log = logging.getLogger('gerrit')
        self.verify_ssl = True
        self.user_agent = 'update-gerrit-group.py'

    def url(self, path):
        return self._url + 'a/' + path

    def get(self, path):
        url = self.url(path)
        self.log.debug('GET: %s' % (url,))
        r = self.session.get(url,
                             verify=self.verify_ssl,
                             auth=self.auth, timeout=TIMEOUT,
                             headers={'Accept': 'application/json',
                                      'Accept-Encoding': 'gzip',
                                      'User-Agent': self.user_agent})
        if r.status_code == 200:
            ret = json.loads(r.text[4:])
            if len(ret):
                self.log.debug('200 OK, Received: %s' % (ret,))
            else:
                self.log.debug('200 OK, No body.')
            return ret
        else:
            self.log.warn('HTTP response: %d', r.status_code)

    def post(self, path, data):
        url = self.url(path)
        self.log.debug('POST: %s' % (url,))
        self.log.debug('data: %s' % (data,))
        r = self.session.post(url, data=json.dumps(data).encode('utf8'),
                              verify=self.verify_ssl,
                              auth=self.auth, timeout=TIMEOUT,
                              headers={'Content-Type':
                                       'application/json;charset=UTF-8',
                                       'User-Agent': self.user_agent})
        self.log.debug('Received: %s' % (r.text,))
        ret = None
        if r.text and len(r.text) > 4:
            try:
                ret = json.loads(r.text[4:])
            except Exception:
                self.log.exception(
                    "Unable to parse result %s from post to %s" %
                    (r.text, url))
        return ret

    def put(self, path, data):
        url = self.url(path)
        self.log.debug('PUT: %s' % (url,))
        self.log.debug('data: %s' % (data,))
        r = self.session.put(url, data=json.dumps(data).encode('utf8'),
                             verify=self.verify_ssl,
                             auth=self.auth, timeout=TIMEOUT,
                             headers={'Content-Type':
                                      'application/json;charset=UTF-8',
                                      'User-Agent': self.user_agent})
        self.log.debug('Received: %s' % (r.text,))

    def delete(self, path, data):
        url = self.url(path)
        self.log.debug('DELETE: %s' % (url,))
        self.log.debug('data: %s' % (data,))
        r = self.session.delete(url, data=json.dumps(data).encode('utf8'),
                                verify=self.verify_ssl,
                                auth=self.auth, timeout=TIMEOUT,
                                headers={'Content-Type':
                                         'application/json;charset=UTF-8',
                                         'User-Agent': self.user_agent})
        self.log.debug('Received: %s' % (r.text,))


def configure_group(gerrit, groupname, include_groups):
    owner = 'infra-ptl'
    group = gerrit.get('groups/%s/detail' % groupname)
    print("Configure group %s" % groupname)
    if not group:
        print("Create group %s" % groupname)
        d = dict(visible_to_all=True)
        if owner:
            d['owner'] = owner
        gerrit.put('groups/%s' % groupname, d)
        group = gerrit.get('groups/%s/detail' % groupname)
    includes = set([g['name'] for g in group['includes']])
    for igroup in include_groups:
        if igroup not in includes:
            print("Add included group %s" % igroup)
            gerrit.put('groups/%s/groups/%s' % (group['id'], igroup), {})
    if owner and group['owner'] != owner:
        print("Set owner to %s" % owner)
        gerrit.put('groups/%s/owner' % group['id'],
                   dict(owner=owner))
    if not group['options'].get('visible_to_all'):
        print("Set visible")
        gerrit.put('groups/%s/options' % group['id'],
                   dict(visible_to_all=True))


def main():
    parser = argparse.ArgumentParser()
    # FIXME: Why does this use .gertty.yaml?  That's just silly.
    parser.add_argument('--config', default='~/.gertty.yaml')
    parser.add_argument('--server', default='openstack')

    args = parser.parse_args()
    configpath = os.path.expanduser(args.config)
    config = yaml.load(open(configpath))
    if args.server:
        for gconfig in reversed(config['servers']):
            if gconfig['name'] == args.server:
                break
    else:
        gconfig = config['servers'][0]

    gerrit = Gerrit(gconfig['url'], gconfig['username'], gconfig['password'])

    pyaml = yaml.load(requests.get(PROJECTS_YAML, stream=True).raw)
    projects = [x['repo'] for x in pyaml['Infrastructure']['projects']]

    core_groups = ['infra-core']
    for project in projects:
        shortname = project.split('/')[1]
        for suffix in ['-core', '-release']:
            group = shortname+suffix
            configure_group(gerrit, group, include_groups=['infra-core'])
        group = shortname+'-core'
        core_groups.append(group)

    configure_group(gerrit, 'infra-council', include_groups=core_groups)


if __name__ == '__main__':
    main()
