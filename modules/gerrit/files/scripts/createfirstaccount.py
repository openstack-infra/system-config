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
# create the first account, we need this to automate setup of our batch accounts

import argparse
import os.path
import sys
import logging
LOGGER_NAME = 'createfirstaccount'
from gerrit_common import setup_logging
from gerrit_common import throws
from gerrit_common import which
from gerrit_common import get_ux_home
from gerrit_common import exec_cmd
from gerrit_common import read_text_fromfile


# find_java: find the location for java binary
# TODO: implement a more resiliant find java, maybe a find binary that itterates the Path
def find_java():
    return which('java')


def find_gerritwar():
    return os.path.join(get_ux_home('gerrit2'), 'review_site', 'bin', 'gerrit.war')


def find_gerritsite():
    return os.path.join(get_ux_home('gerrit2'), 'review_site')


#
# gsql_exec : run some gerrit sql
#
def gsql_exec(sqlcmd):
    logger = logging.getLogger(LOGGER_NAME)
    try:
        try:
            if not len(sqlcmd) > 0:
                throws("Missing sqlcmd in gsql_exec")
            logger.debug("running gerrit sql : " + str(sqlcmd))
            java_bin = find_java()
            logger.debug('using java_bin : %s' % java_bin)
            gerrit_war = find_gerritwar()
            logger.debug('using gerrit_war : %s' % gerrit_war)
            gerrit_site = find_gerritsite()
            logger.debug('using gerrit_site : %s' % gerrit_site)
            # example
            # /usr/bin/java -jar /home/gerrit2/review_site/bin/gerrit.war gsql -d /home/gerrit2/review_site -c 'show tables'
            results = exec_cmd(java_bin, ["-jar", gerrit_war, "gsql", "-d", gerrit_site, "-c", "" + sqlcmd + ""])
            if results.upper().rstrip('\n').find('ERROR') >= 0:
                    throws("gerrit sql command found errors in results : " + results)
            return (0, results)
        except Exception, err:
            logger.error('failed to run gsql_exec : ' + str(sqlcmd))
            logger.error(str(err))
            return (1, str(err))
    finally:
        logger.debug("finished gsql_exec : " + str(sqlcmd))


def banner_start():
    logger = logging.getLogger(LOGGER_NAME)
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.info("  createfirstaccount                                   ....   ")
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def banner_end_fail():
    logger = logging.getLogger(LOGGER_NAME)
    logger.error("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.error("  script failed, check logs                                   ")
    logger.error("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def banner_end():
    logger = logging.getLogger(LOGGER_NAME)
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    logger.info("  script completed                                            ")
    logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


def main():
    global LOGGER_NAME
    # http://docs.python.org/2/library/argparse.html
    parser = argparse.ArgumentParser(description='Create a server certificate using the cacerts db.')
    parser.add_argument('--loglevel', help='Specify the default logging level (optional).', choices=['debug', 'info', 'warning', 'error', 'DEBUG', 'INFO', 'WARNING', 'ERROR'], default='info')
    parser.add_argument('--logfile', help='Specify logfile name.', default='/tmp/createfirstaccount.log')
    parser.add_argument('--debug', help='turn on debug output', action='store_true', default=False)
    parser.add_argument('--working_dir', help='working directory.', default='/tmp')
    parser.add_argument('--username', help='change default user name to create as first account.', default='gerrit2')
    parser.add_argument('--email', help='specify the email address for the user.', default='gerrit2@localhost.com')
    parser.add_argument('--ssh_pubkey', help='pupblic key to use. Example, generate with :\n ssh-keygen -t rsa  -f ~/.ssh/gerrit2 -P ""', default='/home/gerrit2/.ssh/gerrit2.pub')
    parser.add_argument('--check_exists', help='just check if the first account exist, if it does not, then return 1, if it does return 0', action='store_true', default=False)
    args = parser.parse_args()
    if args.debug:
        args.loglevel = 'debug'
    logger = setup_logging(args.logfile, args.loglevel, LOGGER_NAME)
    banner_start()
    logger.debug("parsed arguments")
    # check that we have an ssh key
    try:
        if not os.path.isfile(args.ssh_pubkey):
            throws('No ssh public key found : ' + args.ssh_pubkey)
    except Exception, err:
        logger.error("Problem in file check : " + str(err))
        return 300
    # check to see that we can connect
    if not gsql_exec('select @@version')[0] == 0:
        banner_end_fail()
        return 1
    try:
        ssh_pub_key_content = read_text_fromfile(args.ssh_pubkey)
    except Exception:
        return 500
    retval = gsql_exec("SELECT * FROM accounts WHERE ACCOUNT_ID=0")
    if not retval[0] == 0:
        logger.error("check for account existence failed: " + retval[1])
        banner_end_fail()
        return 1
    if args.check_exists:
        logger.debug("only performing check.")
        if retval[1].upper().rstrip('\n').find('0 ROWS') >= 0:
            logger.info("check found that the account does not exist, return 0.")
            banner_end()
            return 0
        else:
            logger.info("check found that the account exist, return 1.")
            banner_end()
            return 1
    if retval[1].upper().rstrip('\n').find('0 ROWS') >= 0:
        sql_commands = [
            "INSERT INTO accounts (REGISTERED_ON, FULL_NAME) VALUES (NOW(), '" + args.username + "')",
            "INSERT INTO account_group_members (ACCOUNT_ID, GROUP_ID) VALUES (0, 1)",
            "INSERT INTO account_external_ids (ACCOUNT_ID, EXTERNAL_ID) VALUES (0, 'gerrit:" + args.username + "')",
            "INSERT INTO account_external_ids (ACCOUNT_ID, EXTERNAL_ID) VALUES (0, 'username:" + args.username + "')",
            "INSERT INTO account_ssh_keys (SSH_PUBLIC_KEY, VALID) VALUES ('" + ssh_pub_key_content + "', 'Y')",
            "update account_external_ids set email_address='" + args.email + "' where external_id like '%:" + args.username + "'"]
        for sql in sql_commands:
            retval = gsql_exec(sql)
            if not retval[0] == 0:
                logger.error("Failed to process gsql: " + retval[1])
                banner_end_fail()
                return 1
    else:
        logger.info("ACCOUNT_ID 0 already exist, skipping create.")
    banner_end()
    return 0


if __name__ == '__main__':
    sys.exit(main())
