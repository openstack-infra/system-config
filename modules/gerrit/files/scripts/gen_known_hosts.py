#!/usr/bin/env python
# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
# create a known_hosts file for a given git server and port number
# we default to localhost and 29418 if no options are provided.

import argparse
import os.path
import sys
import tempfile
import logging
LOGGER_NAME = 'gen_known_hosts'
# TODO: find a way to do this as a class....probably should organize this better
from gerrit_common import setup_logging
from gerrit_common import get_ux_home
from gerrit_common import exec_cmd
from gerrit_common import which
from gerrit_common import get_ip_from_host
from gerrit_common import write_text_tofile
from gerrit_common import file_contains_text


def banner_start():
    logger = logging.getLogger(LOGGER_NAME)
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.info("  get_known_hosts                                    ....   ")
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def banner_end_fail():
    logger = logging.getLogger(LOGGER_NAME)
    logger.error("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.error("  script failed, check logs                                ")
    logger.error("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def banner_end():
    logger = logging.getLogger(LOGGER_NAME)
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.info("  script completed                                          ")
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def create_ssh_folder(home_dir):
    if not os.path.isdir(os.path.join(home_dir, '.ssh')):
        os.makedirs(os.path.join(home_dir, '.ssh'), int('700', 8))


def scan_host_key(hostname, port):
    logger = logging.getLogger(LOGGER_NAME)
    ip_address = get_ip_from_host(hostname)
    logger.debug(ip_address)
    f = tempfile.NamedTemporaryFile()
    logger.debug('working with file ' + str(f.name))
    if ip_address != hostname:
        logger.debug("writing " + hostname)
        f.write(hostname + '\n')
    f.write(ip_address + '\n')
    f.flush()
    f.close
    #    ssh-keyscan -4 -t ecdsa -f ./keyhost.txt -p \$_port
    logger.debug(exec_cmd(which('bash'), ['-c', 'cat ' + f.name]))
    res = exec_cmd(which('ssh-keyscan'),
          ['-4', '-t', 'rsa', '-f', f.name, '-p', str(port)], '/tmp', True)
    logger.debug(res)
#    os.unlink(f.name)
    return res


def main():
    global LOGGER_NAME
    parser = argparse.ArgumentParser(description='Create a server' +
             ' certificate using the cacerts db.')
    parser.add_argument('--loglevel',
     help='Specify the default logging level (optional).',
     choices=['debug',
              'info',
              'warning',
              'error',
              'DEBUG',
              'INFO',
              'WARNING',
              'ERROR'], default='info')
    parser.add_argument('--debug',
     help='turn on debug output', action='store_true', default=False)
    parser.add_argument('--logfile',
     help='Specify logfile name.', default='/tmp/gen_known_hosts.log')
    parser.add_argument('--server_host',
     help='specify the server hostname we are adding' +
          ' a known_hosts entry for.', default='localhost')
    parser.add_argument('--server_port',
     help='specify the server port number we are adding' +
          ' a known_hosts entry for.', default=29418, type=int)
    parser.add_argument('--check_exists',
     help='just check if the first account exist, if it does not,' +
          ' then return 1, if it does return 0',
          action='store_true', default=False)
    args = parser.parse_args()
    if args.debug:
        args.loglevel = 'debug'
    logger = setup_logging(args.logfile, args.loglevel, LOGGER_NAME)
    banner_start()
    logger.debug("parsed arguments")
    logger.debug("adding known_hosts entry for " +
     args.server_host + ":" + str(args.server_port))
    user_home = get_ux_home()
    logger.debug("current user home = " + user_home)
    create_ssh_folder(user_home)
    if not os.path.isfile(os.path.join(user_home, '.ssh', 'known_hosts')):
        logger.debug("create known_hosts file with key scan results")
        key_scan_res = scan_host_key(args.server_host, args.server_port)
        write_text_tofile(os.path.join(user_home,
         '.ssh', 'known_hosts'), key_scan_res)
        logger.info(os.path.join(user_home,
         '.ssh', 'known_hosts') + " created.")
    else:
        if not file_contains_text(os.path.join(user_home,
                  '.ssh', 'known_hosts'), '^' +
                  str(get_ip_from_host(args.server_host))):
            logger.debug("file already exist, adding key to file")
            key_scan_res = scan_host_key(args.server_host, args.server_port)
            write_text_tofile(os.path.join(user_home,
             '.ssh', 'known_hosts'), key_scan_res)
            logger.info(os.path.join(user_home,
             '.ssh', 'known_hosts') + " appended.")
        else:
            logger.info(os.path.join(user_home,
             '.ssh', 'known_hosts') + " already setup.")
    banner_end()
    return 0


if __name__ == '__main__':
    sys.exit(main())
