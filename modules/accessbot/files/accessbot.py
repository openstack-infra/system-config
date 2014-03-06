#! /usr/bin/env python

# Copyright 2011, 2013-2014 OpenStack Foundation
# Copyright 2012 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import ConfigParser
import argparse
import irc.client
import logging
import random
import string
import sys
import time
import yaml

logging.basicConfig(level=logging.DEBUG)


class SetAccess(irc.client.SimpleIRCClient):
    log = logging.getLogger("setaccess")

    def __init__(self, config, nick, password, server, port):
        irc.client.SimpleIRCClient.__init__(self)
        self.identify_msg_cap = False
        self.config = config
        self.nick = nick
        self.password = password
        self.server = server
        self.port = int(port)
        print self.config
        self.channels = [x['name'] for x in self.config['channels']]
        self.current_channel = None
        self.current_list = []
        self.changes = []
        self.identified = False
        print self.server, self.port, self.nick
        self.connect(self.server, self.port, self.nick)

    def on_disconnect(self, connection, event):
        sys.exit(0)

    def on_welcome(self, c, e):
        self.identify_msg_cap = False
        self.log.debug("Requesting identify-msg capability")
        c.cap('REQ', 'identify-msg')
        c.cap('END')

    def on_cap(self, c, e):
        self.log.debug("Received cap response %s" % repr(e.arguments))
        if e.arguments[0] == 'ACK' and 'identify-msg' in e.arguments[1]:
            self.log.debug("identify-msg cap acked")
            self.identify_msg_cap = True
            self.log.debug("Identifying to nickserv")
            c.privmsg("nickserv", "identify %s " % self.password)

    def on_privnotice(self, c, e):
        if not self.identify_msg_cap:
            self.log.debug("Ignoring message because identify-msg "
                           "cap not enabled")
            return
        nick = e.source.split('!')[0]
        auth = e.arguments[0][0]
        msg = e.arguments[0][1:]
        if auth == '+' and nick == 'NickServ' and not self.identified:
            if msg.startswith('You are now identified'):
                self.identified = True
                self.advance()
                return
        if auth != '+' or nick != 'ChanServ':
            self.log.debug("Ignoring message from unauthenticated "
                           "user %s" % nick)
            return
        self.failed = False
        self.advance(msg)

    def _get_access_list(self, channel_name):
        ret = {}
        channel = None
        for c in self.config['channels']:
            if c['name'] == channel_name:
                channel = c
        if channel is None:
            raise Exception("Unknown channel %s" % (channel_name,))
        for access, nicks in (self.config['global'].items() +
                              channel.items()):
            flags = self.config['access'].get(access)
            if flags is None:
                continue
            for nick in nicks:
                ret[nick] = flags
        return ret

    def advance(self, msg=None):
        if self.changes:
            #for x in self.changes:
            #    print x
            #self.changes = []
            change = self.changes.pop()
            self.connection.privmsg('chanserv', change)
            time.sleep(1)
            return
        if not self.current_channel:
            if not self.channels:
                self.connection.quit()
                return
            self.current_channel = self.channels.pop()
            self.current_list = []
            self.connection.privmsg('chanserv', 'access list #%s' %
                                    self.current_channel)
            time.sleep(1)
            return
        if msg.startswith('End of'):
            target = self._get_access_list(self.current_channel)
            nicks_seen = set()
            for nick, flags, msg in self.current_list:
                if nick not in target and nick != self.nick:
                    self.changes.append('access #%s del %s' %
                                        (self.current_channel, nick))
                    continue
                nicks_seen.add(nick)
                if target[nick] != flags and nick != self.nick:
                    self.changes.append('access #%s del %s' %
                                        (self.current_channel, nick))
                    self.changes.append('access #%s add %s %s' %
                                        (self.current_channel, nick, target[nick]))
                    continue
            for nick, flags in target.items():
                if nick not in nicks_seen and nick != self.nick:
                    self.changes.append('access #%s add %s %s' %
                                        (self.current_channel, nick, target[nick]))
            for x in self.changes:
                print x
            self.current_channel = None
            self.advance()
            return
        parts = msg.split()
        print parts
        if parts[2].startswith('+'):
            self.current_list.append((parts[1], parts[2], msg))


def main():
    parser = argparse.ArgumentParser(description='IRC channel access check')
    parser.add_argument('-c', dest='config', nargs=1,
                        help='specify the config file')
    parser.add_argument('-l', dest='channels',
                        default='/etc/irc/channels.yaml',
                        help='path to the channel config')
    args = parser.parse_args()

    config = ConfigParser.ConfigParser()
    config.read(args.config)

    channels = yaml.load(open(args.channels))

    a = SetAccess(channels,
                  config.get('ircbot', 'nick'),
                  config.get('ircbot', 'pass'),
                  config.get('ircbot', 'server'),
                  config.get('ircbot', 'port'))
    a.start()


if __name__ == "__main__":
    main()
