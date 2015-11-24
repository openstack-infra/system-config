#!/usr/bin/env python

# Copyright (C) 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

import logging
import re
import socket
import time

from statsd.defaults.env import statsd

INTERVAL = 10
GAUGES =[
    'qcur',
    # 2. qcur [..BS]: current queued requests. For the backend this
    # reports the number queued without a server assigned.
    'scur',
    # 4. scur [LFBS]: current sessions
    'act',
    # 19. act [..BS]: number of active servers (backend), server is
    # active (server)
    'bck',
    # 20. bck [..BS]: number of backup servers (backend), server is
    # backup (server)
    'qtime',
    # 58. qtime [..BS]: the average queue time in ms over the 1024
    # last requests
    'ctime',
    # 59. ctime [..BS]: the average connect time in ms over the 1024
    # last requests
    'rtime',
    # 60. rtime [..BS]: the average response time in ms over the 1024
    # last requests (0 for TCP)
    'ttime',
    # 61. ttime [..BS]: the average total session time in ms over the
    # 1024 last requests
]

COUNTERS = [
    'stot',
    # 7. stot [LFBS]: cumulative number of connections
    'bin',
    # 8. bin [LFBS]: bytes in
    'bout',
    # 9. bout [LFBS]: bytes out
    'ereq',
    # 12. ereq [LF..]: request errors. Some of the possible causes
    # are:
    #     - early termination from the client, before the request has
    #       been sent.
    #     - read error from the client
    #     - client timeout
    #     - client closed connection
    #     - various bad requests from the client.
    #     - request was tarpitted.
    'econ',
    # 13. econ [..BS]: number of requests that encountered an error
    # trying to connect to a backend server. The backend stat is the
    # sum of the stat for all servers of that backend, plus any
    # connection errors not associated with a particular server (such
    # as the backend having no active servers).
    'eresp',
    # 14. eresp [..BS]: response errors. srv_abrt will be counted here
    # also.
    # Some other errors are:
    #     - write error on the client socket (won't be counted for the
    #       server stat)
    #     - failure applying filters to the response.
    'wretr',
    # 15. wretr [..BS]: number of times a connection to a server was
    # retried.
    'wredis',
    # 16. wredis [..BS]: number of times a request was redispatched to
    # another server. The server value counts the number of times that
    # server was switched away from.
]

class Socket(object):
    def __init__(self, path):
        self.path = path
        self.socket = None

    def open(self):
        s = socket.socket(socket.AF_UNIX)
        s.settimeout(5)
        s.connect(self.path)
        self.socket = s

    def __enter__(self):
        self.open()
        return self.socket

    def __exit__(self, etype, value, tb):
        self.socket.close()
        self.socket = None


class HAProxy(object):
    COMMENT_RE = re.compile('^#\s+(\S.*)')

    def __init__(self, path):
        self.socket = Socket(path)
        self.log = logging.getLogger("HAProxy")
        self.prevdata = {}

    def command(self, command):
        with self.socket as socket:
            socket.send(command + '\n')
            data = ''
            while True:
                r = socket.recv(4096)
                data += r
                if not r:
                    break
            return data

    def getStats(self):
        data = self.command('show stat')
        lines = data.split('\n')
        m = self.COMMENT_RE.match(lines[0])
        header = m.group(1)
        cols = header.split(',')[:-1]
        ret = []
        for line in lines[1:]:
            if not line:
                continue
            row = line.split(',')[:-1]
            row = dict(zip(cols, row))
            ret.append(row)
        return ret

    def reportStats(self, stats):
        for row in stats:
            base = 'haproxy.%s.%s.' % (row['pxname'], row['svname'])
            for key in GAUGES:
                value = row[key]
                if value != '':
                    statsd.gauge(base+key, int(value))
            for key in COUNTERS:
                metric = base+key
                newvalue = row[key]
                if newvalue == '':
                    continue
                newvalue = int(newvalue)
                oldvalue = self.prevdata.get(metric)
                if oldvalue is not None:
                    value = newvalue-oldvalue
                    statsd.incr(metric, value)
                self.prevdata[metric] = newvalue

    def run(self):
        while True:
            try:
                self._run()
            except Exception:
                self.log.exception("Exception in main loop:")

    def _run(self):
        time.sleep(INTERVAL)
        stats = self.getStats()
        self.reportStats(stats)


logging.basicConfig(level=logging.DEBUG)
p = HAProxy('/var/lib/haproxy/stats')
p.run()
