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
# under the License.P
# lets start a common library for repeated functions we are using

import os.path
import stat
import subprocess
import re
import socket
import logging
LOGGER_NAME = 'common'


#
# setup_logging : create a logfile and setup loglevels
#
def setup_logging(logfile, loglevel, name='common'):
    global LOGGER_NAME
    LOGGER_NAME = name
    logger = logging.getLogger(LOGGER_NAME)
    doFileLogging = True
    logint = getattr(logging, loglevel.upper())
    # file handler
    logfile_dir = os.path.dirname(os.path.abspath(logfile))
    if not os.path.exists(logfile_dir):
        doFileLogging = False
    if doFileLogging:
        if os.path.isfile(logfile):
            try:
                os.remove(logfile)
            except:
                pass
        fch = logging.FileHandler(logfile)
        fch.setLevel(logint)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        fch.setFormatter(formatter)
        logger.addHandler(fch)
    # console handler
    ch = logging.StreamHandler()
    ch.setLevel(logint)
    formatter = logging.Formatter('[%(name)s] %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    logger.setLevel(ch.level)
    if doFileLogging:
        logger.info("writing logfile to : " + logfile)
    if os.path.isfile(logfile):
            try:
                os.chmod(logfile, stat.S_IREAD | stat.S_IWRITE | stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IWGRP | stat.S_IROTH | stat.S_IWOTH)
            except:
                pass

    return logger


# execute command
#
def exec_cmd(binary, arguments='', current_pwd='/tmp', ignore_err=False):
    logger = logging.getLogger(LOGGER_NAME)
    try:
        if arguments == '':
            arguments = ['']
        if not isinstance(arguments, list):
            arguments = arguments.split(' ')
        logger.debug("calling exec_cmd : " + ' '.join([binary] + arguments))
        logger.debug("calling it from folder: " + current_pwd)

        p = subprocess.Popen([binary] + arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        if not ignore_err:
            if len(err) > 0:
                logger.error("Command " + ' '.join([binary] + arguments) + " failed!! ")
                logger.error(err)
            else:
                logger.debug("Command " + ' '.join([binary] + arguments) + " passed ")
                logger.debug(out)
        else:
            logger.debug('command completed.')
        return(out)
    except OSError as e:
        logger.error("Execution failed: " + str(e))


#
# exec ret code
def exec_return_exit(binary, arguments='', current_pwd='/tmp'):
    logger = logging.getLogger(LOGGER_NAME)
    try:
        if arguments == '':
            arguments = ['']
        if not isinstance(arguments, list):
            arguments = arguments.split(' ')
        logger.debug("calling exec_cmd : " + ' '.join([binary] + arguments))
        retcode = subprocess.call(' '.join([binary] + arguments), shell=True, cwd=current_pwd)
        return retcode
    except OSError as e:
        logger.error("Execution failed: " + str(e))
        return -1


def throws(errmsg):
    raise RuntimeError(errmsg)


def which(command):
    return exec_cmd('which', command).rstrip('\n')


# find_java: find the location for java binary
# TODO: implement a more resiliant find java, maybe a find binary that itterates the Path
def find_java():
    return which('java')


# get the current user
def get_currentuser():
    return exec_cmd(which('bash'), '-c ' + which('whoami')).rstrip('\n')


# get the user home directory
def get_ux_home(user=''):
    if user == '':
        user = get_currentuser()
    return exec_cmd(which('getent'), 'passwd ' + user).rstrip('\n').split(':')[5]


# get the ipaddress from the hostname
def get_ip_from_host(hostname):
    return socket.gethostbyname(hostname)


# write some text to a file
# this is text, so don't use b option, if append is False, we truncate w+
def write_text_tofile(fspec, contents, append=True):
    if append:
        write_mode = "a"
    else:
        write_mode = "w+"
    with open(fspec, write_mode) as thefile:
        thefile.write(contents)


# read the text form a file
def read_text_fromfile(fspec):
    try:
        with open(fspec, 'r') as f:
            read_data = f.read()
        f.closed
        return read_data
    except IOError, err:
        throws("Problem reading file : " + str(err))


# search the file for text
def file_contains_text(fspec, regstr):
    with open(fspec, "r") as thefile:
        for line in thefile:
            if re.search(regstr, line):
                return True
    return False
