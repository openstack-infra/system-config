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

import argparse
import irc.client
import logging
import random
import string
import sys
import yaml

logging.basicConfig(level=logging.INFO)


class CheckAccess(irc.client.SimpleIRCClient):
    log = logging.getLogger("checkaccess")

    def __init__(self, channels, nick, flags):
        irc.client.SimpleIRCClient.__init__(self)
        self.identify_msg_cap = False
        self.channels = channels
        self.nick = nick
        self.flags = flags
        self.current_channel = None
        self.current_list = []
        self.failed = True

    def on_disconnect(self, connection, event):
        if self.failed:
            sys.exit(1)
        else:
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
            self.advance()

    def on_privnotice(self, c, e):
        if not self.identify_msg_cap:
            self.log.debug("Ignoring message because identify-msg "
                           "cap not enabled")
            return
        nick = e.source.split('!')[0]
        auth = e.arguments[0][0]
        msg = e.arguments[0][1:]
        if auth != '+' or nick != 'ChanServ':
            self.log.debug("Ignoring message from unauthenticated "
                           "user %s" % nick)
            return
        self.failed = False
        self.advance(msg)

    def advance(self, msg=None):
        if not self.current_channel:
            if not self.channels:
                self.connection.quit()
                return
            self.current_channel = self.channels.pop()
            self.current_list = []
            self.connection.privmsg('chanserv', 'access list %s' %
                                    self.current_channel)
            return
        if msg.startswith('End of'):
            found = False
            for nick, flags, msg in self.current_list:
                if nick == self.nick and flags == self.flags:
                    self.log.info('%s access ok on %s' %
                                  (self.nick, self.current_channel))
                    found = True
                    break
            if not found:
                self.failed = True
                print ("%s does not have permissions on %s:" %
                       (self.nick, self.current_channel))
                for nick, flags, msg in self.current_list:
                    print msg
                print
            self.current_channel = None
            self.advance()
            return
        parts = msg.split()
        self.current_list.append((parts[1], parts[2], msg))


def main():
    parser = argparse.ArgumentParser(description='IRC channel access check')
    parser.add_argument('-l', dest='config',
                        default='/etc/irc/channels.yaml',
                        help='path to the config file')
    parser.add_argument('-s', dest='server',
                        default='chat.freenode.net',
                        help='IRC server')
    parser.add_argument('-p', dest='port',
                        default=6667,
                        help='IRC port')
    parser.add_argument('nick',
                        help='the nick for which access should be validated')
    args = parser.parse_args()

    config = yaml.load(open(args.config))
    channels = []
    for channel in config['channels']:
        channels.append('#' + channel['name'])

    access_level = None
    for level, names in config['global'].items():
        if args.nick in names:
            access_level = level
    if access_level is None:
        raise Exception("Unable to determine global access level for %s" %
                        args.nick)
    flags = config['access'][access_level]

    a = CheckAccess(channels, args.nick, flags)
    mynick = ''.join(random.choice(string.ascii_uppercase)
                     for x in range(16))
    a.connect(args.server, int(args.port), mynick)
    a.start()

if __name__ == "__main__":
    main()
