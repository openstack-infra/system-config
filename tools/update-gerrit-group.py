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


def main():
    parser = argparse.ArgumentParser()
    # FIXME: Why does this use .gertty.yaml?  That's just silly.
    parser.add_argument('--config', default='~/.gertty.yaml')
    parser.add_argument('--server', 'openstack')
    parser.add_argument('--group', required=True)
    parser.add_argument('--owner')
    parser.add_argument('--include-group', nargs='*', default=[])
    parser.add_argument('--visible', action='store_true')

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
    group = gerrit.get('groups/%s/detail' % args.group)
    if not group:
        print("Create group %s" % args.group)
        d = dict(visible_to_all=args.visible)
        if args.owner:
            d['owner'] = args.owner
        gerrit.put('groups/%s' % args.group, d)
        group = gerrit.get('groups/%s/detail' % args.group)
    includes = set([g['name'] for g in group['includes']])
    for igroup in args.include_group:
        if igroup not in includes:
            print("Add included group %s" % igroup)
            gerrit.put('groups/%s/groups/%s' % (group['id'], igroup), {})
    if args.owner:
        print("Set owner to %s" % args.owner)
        gerrit.put('groups/%s/owner' % group['id'],
                   dict(owner=args.owner))
    if args.visible != group['options'].get('visible_to_all'):
        print("Set visible to %s" % args.visible)
        gerrit.put('groups/%s/options' % group['id'],
                   dict(visible_to_all=args.visible))

if __name__ == '__main__':
    main()
