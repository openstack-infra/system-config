#!/usr/bin/env python

# Update the base image that is used for devstack VMs.

# Copyright (C) 2011-2012 OpenStack LLC.
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

import contextlib
import sys

import paramiko


class SSHException(Exception):
    def __init__(self, message, rc):
        super(SSHException, self).__init__(message)
        self.rc = rc


class SSHClient(object):
    def __init__(self, ip, username, password=None, pkey=None):
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.WarningPolicy())
        client.connect(ip, username=username, password=password, pkey=pkey)
        self.client = client

    def ssh(self, command, error_ok=False):
        stdin, stdout, stderr = self.client.exec_command(command)
        print('--- ssh: "%s" ---' % command)
        print(' -- stdout --')
        output = ''
        for x in stdout:
            output += x
            sys.stdout.write(" | " + x)
        ret = stdout.channel.recv_exit_status()
        print(" -- stderr --")
        for x in stderr:
            sys.stdout.write(" | " + x)
        if (not error_ok) and ret:
            raise SSHException("Unable to %s" % command, ret)
        print("--- done ---\n")
        return ret, output

    def scp(self, source, dest):
        print('--- scp copy:  %s -> %s' % (source, dest))
        ftp = self.client.open_sftp()
        ftp.put(source, dest)
        ftp.close()

    @contextlib.contextmanager
    def open(self, path, mode):
        ftp = self.client.open_sftp()
        f = ftp.open(path, mode)
        yield f
        ftp.close()
