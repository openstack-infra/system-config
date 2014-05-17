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
# run gerrit gsql commands from yaml

import argparse
import os.path
import sys
import yaml
import logging
LOGGER_NAME = 'gerrit_runsql'


from gerrit_common import setup_logging
from gerrit_common import throws
from gerrit_common import which
from gerrit_common import get_ux_home
from gerrit_common import exec_cmd


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
#           example
#           /usr/bin/java -jar /home/gerrit2/review_site/bin/gerrit.war gsql -d /home/gerrit2/review_site -c 'show tables'
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
    logger.info("  gerrit_runsql                                        ....   ")
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
    parser = argparse.ArgumentParser(description='run gerrit gsql commands from yaml.')
    parser.add_argument('--loglevel', help='Specify the default logging level (optional).', choices=['debug', 'info', 'warning', 'error', 'DEBUG', 'INFO', 'WARNING', 'ERROR'], default='info')
    parser.add_argument('--logfile', help='Specify logfile name.', default='/tmp/gerrit_runsql.log')
    parser.add_argument('--loggername', help='Specify a name for the logger.', default=LOGGER_NAME)
    parser.add_argument('--debug', help='turn on debug output', action='store_true', default=False)
    parser.add_argument('--working_dir', help='working directory.', default='/tmp')
    parser.add_argument('--onlyif_not_hasrows', help='only run if the sql does not have rows.', default='')
    parser.add_argument('--check', help='only echo sql we will execute, do not run it', action='store_true', default=False)
    parser.add_argument('--sql_config_file', help='change default user name to create as first account.', default='/tmp/gerrit_init.sql.yaml')
    args = parser.parse_args()
    if args.debug:
        args.loglevel = 'debug'
    LOGGER_NAME = args.loggername
    logger = setup_logging(args.logfile, args.loglevel, LOGGER_NAME)
    banner_start()
    logger.debug("parsed arguments")

    # check to see that we can connect
    if not gsql_exec('select @@version')[0] == 0:
        banner_end_fail()
        return 1

    retval = [0, '0 rows']
    if args.onlyif_not_hasrows != "":
        retval = gsql_exec(args.onlyif_not_hasrows)
        if not retval[0] == 0:
            logger.error("onlyif_not_hasrows check failed: " + retval[1])
            logger.error("attempted to run sql: " + args.onlyif_not_hasrows)
            banner_end_fail()
            return 1
    else:
        logger.debug("not performing pre-execution check.")

    if not retval[1].upper().rstrip('\n').find('0 ROWS') >= 0:
        logger.info("onlyif_not_hasrows found rows, do nothing.")
        banner_end()
        return 0

    f = open(args.sql_config_file)
    dataMap = yaml.safe_load(f)
    f.close()

    for sql in dataMap['gsql']:
        logger.info("gsql executing : " + sql)
        if not args.check:
            retval = gsql_exec(sql)
            if not retval[0] == 0:
                logger.error("Failed to process gsql: " + retval[1])
                banner_end_fail()
                return 1
        else:
            logger.warn("skipping exec, check is on")
    banner_end()
    return 0

if __name__ == '__main__':
    sys.exit(main())
