#!/usr/bin/env python
# Copyright 2016 Red Hat, Inc.
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

from datetime import datetime
import re
import subprocess
import logging

VOLUMES = ['docs',
           'docs.dev',
           'project.starlingx',
           'project.zuul',
           ]

log = logging.getLogger("release")

UPDATE_RE = re.compile("^\s+Last Update (.*)$")


def get_last_update(volume):
    ret = []
    out = subprocess.check_output(['vos', 'examine', volume, '-localauth'])
    state = 0
    for line in out.split('\n'):
        if state == 0 and line.startswith(volume):
            state = 1
            site = None
        elif state == 1:
            site = line.strip()
            state = 0
        m = UPDATE_RE.match(line)
        if m:
            ret.append(dict(site=site,
                            volume=volume,
                            updated=datetime.strptime(m.group(1),
                                                      '%a %b %d %H:%M:%S %Y')))

    return ret


def release(volume):
    log.info("Releasing %s" % volume)
    subprocess.check_output(['vos', 'release', volume, '-localauth'])


def check_release(volume):
    log.info("Checking %s" % volume)
    rw = get_last_update(volume)[0]
    log.debug("  %s %s %s" % (rw['site'], rw['updated'], rw['volume']))
    ros = get_last_update(volume + '.readonly')
    update = False
    for ro in ros:
        log.debug("  %s %s %s" % (ro['site'], ro['updated'], ro['volume']))
        if ro['updated'] < rw['updated']:
            update = True
    if update:
        release(volume)


def main():
    logging.basicConfig(level=logging.DEBUG,
                        format='%(asctime)s %(name)s '
                        '%(levelname)-8s %(message)s')
    for volume in VOLUMES:
        check_release(volume)


if __name__ == '__main__':
    main()
