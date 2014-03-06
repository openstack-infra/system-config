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
import ssl
import sys
import time
import yaml

logging.basicConfig(level=logging.DEBUG)


class SetAccess(irc.client.SimpleIRCClient):
    log = logging.getLogger("setaccess")

    def __init__(self, config, noop, nick, password, server, port):
        irc.client.SimpleIRCClient.__init__(self)
        self.identify_msg_cap = False
        self.config = config
        self.nick = nick
        self.password = password
        self.server = server
        self.port = int(port)
        self.noop = noop
        self.channels = [x['name'] for x in self.config['channels']]
        self.current_channel = None
        self.current_list = []
        self.changes = []
        self.identified = False
        if self.port == 6697:
            factory = irc.connection.Factory(wrapper=ssl.wrap_socket)
            self.connect(self.server, self.port, self.nick,
                         connect_factory=factory)
        else:
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
        mask = ''
        for access, nicks in (self.config['global'].items() +
                              channel.items()):
            if access == 'mask':
                mask = self.config['access'].get(nicks)
                continue
            flags = self.config['access'].get(access)
            if flags is None:
                continue
            for nick in nicks:
                ret[nick] = flags
        return mask, ret

    def _get_access_change(self, current, target, mask):
        remove = ''
        add = ''
        change = ''
        for x in current:
            if x in '+-':
                continue
            if target:
                if x not in target:
                    remove += x
            else:
                if x not in mask:
                    remove += x
        for x in target:
            if x in '+-':
                continue
            if x not in current:
                add += x
        if remove:
            change += '-' + remove
        if add:
            change += '+' + add
        return change

    def _get_access_changes(self):
        mask, target = self._get_access_list(self.current_channel)
        self.log.debug("Mask for %s: %s" % (self.current_channel, mask))
        self.log.debug("Target for %s: %s" % (self.current_channel, target))
        all_nicks = set()
        current = {}
        changes = []
        for nick, flags, msg in self.current_list:
            all_nicks.add(nick)
            current[nick] = flags
        for nick in target.keys():
            all_nicks.add(nick)
        for nick in all_nicks:
            change = self._get_access_change(current.get(nick, ''),
                                             target.get(nick, ''), mask)
            if change:
                changes.append('access #%s add %s %s' % (self.current_channel,
                                                         nick, change))
        return changes

    def advance(self, msg=None):
        if self.changes:
            if self.noop:
                for change in self.changes:
                    self.log.info('NOOP: ' + change)
                self.changes = []
            else:
                change = self.changes.pop()
                self.log.info(change)
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
            self.changes = self._get_access_changes()
            self.current_channel = None
            self.advance()
            return
        parts = msg.split()
        if parts[2].startswith('+'):
            self.current_list.append((parts[1], parts[2], msg))


def main():
    parser = argparse.ArgumentParser(description='IRC channel access check')
    parser.add_argument('-c', dest='config', nargs=1,
                        help='specify the config file')
    parser.add_argument('-l', dest='channels',
                        default='/etc/irc/channels.yaml',
                        help='path to the channel config')
    parser.add_argument('--noop', dest='noop',
                        action='store_true',
                        help="Don't make any changes")
    args = parser.parse_args()

    config = ConfigParser.ConfigParser()
    config.read(args.config)

    channels = yaml.load(open(args.channels))

    a = SetAccess(channels, args.noop,
                  config.get('ircbot', 'nick'),
                  config.get('ircbot', 'pass'),
                  config.get('ircbot', 'server'),
                  config.get('ircbot', 'port'))
    a.start()


if __name__ == "__main__":
    main()
