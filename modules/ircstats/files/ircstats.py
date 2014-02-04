#!/bin/env python
#
# Copyright (C) 2013 OpenStack Foundation
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
#
"""
Script to install and generate log analyzer for irc logs, using
SuperSeriousStats opensource log analyzer, http://sss.dutnie.nl.

The tool download SuperSeriousStats, install and configure it for each channel.
The channels can be specified in command line. If none is specified, the irc
log directory is traversed to find all channels.

Subsequently the script generate stats for newer log entries.
"""
import argparse
import hashlib
import logging
import os
import shutil
import subprocess
import sys
import urllib2

__version__ = '1.0'

SSS_CLONE_DIR = '/opt/ircstats/superseriousstats'
LOG = logging.getLogger(sys.argv[0])


def getopts():
    """ parse arguments """
    parser = argparse.ArgumentParser(prog=__file__)
    parser.add_argument('-V', '--version', action='version',
                        version=__version__, help='version')
    parser.add_argument('-c', '--channel', action='store',
                        dest='channel',
                        nargs='+',
                        help='collect stats for these irc channels')
    parser.add_argument('-v', '--verbose', action='store_true',
                        dest='verbose',
                        help='print debug information')
    parser.add_argument('-l', '--irclog-base', action='store',
                        dest='irclog_base',
                        required=True,
                        help='irclog base directory')
    parser.add_argument('-t', '--conf-template', action='store',
                        dest='conf_template',
                        required=True,
                        help='template to use for generating conf')
    parser.add_argument('-i', '--install-base', action='store',
                        dest='install_base',
                        required=True,
                        help='stats install base directory')

    opts = parser.parse_args()
    if not os.path.exists(opts.irclog_base):
        parser.print_help()
        LOG.error('--irclog-base %s not exists. Typo?' %
                  opts.irclog_base)
        sys.exit(1)
    elif not os.path.exists(opts.conf_template):
        parser.print_help()
        LOG.error('--conf-template %s not exists. Typo?' % opts.conf_template)
        sys.exit(1)
    return opts


def download_from_url(url, remote_path):
    resp = urllib2.urlopen(url)

    if not os.path.exists(remote_path):
        with open(remote_path, 'w') as wp:
            wp.write(resp.read())
    return remote_path


def exec_command(command, cwd=None):
    if not cwd:
        cwd = os.getcwd()
    try:
        LOG.debug('Executing command %s' % command)
        p = subprocess.Popen(command.split(' '),
                             cwd=cwd,
                             stdout=subprocess.PIPE)
        s_out, s_err = p.communicate()
    except OSError as err:
        LOG.error("command '%s' failed %s" % (command, err))
        raise

    return s_out, s_err


class SuperSeriousStats:
    def __init__(self, channel, install_base, conf_template, irclog_base):
        """ init vars """
        self.channel = channel
        self.install_base = install_base
        self.conf_template = conf_template
        self.irclog_base = irclog_base

        self.install_dir = os.path.join(install_base, channel)
        self.channel_name = channel[1:]  # strip # in channel name
        self.conf_file = os.path.join(self.install_dir,
                                      '%s.conf' % self.channel_name)
        self.db_file = os.path.join(self.install_dir,
                                    '%s.db' % self.channel_name)
        self.sqlite_template = os.path.join(self.install_dir,
                                            'empty_database_v7.sqlite')

    def __create_dir(self, dir):
        """ create directory recursively and return the path """
        if not os.path.exists(dir):
            LOG.debug('Creating directory %s' % dir)
            shutil.os.makedirs(dir)
        return dir

    def find_replace(self, patt, replacement):
        """ find and replace the patt in stats configuration file """
        file = r'%s' % self.conf_file
        perl_regex = r's/%s/%s/g' % (patt, replacement)
        exec_command("perl -pi -e %s %s" % (perl_regex, file))

    def generate_configuration(self):
        """ generate configuration specific to this channel """
        LOG.debug('Configuring stats for channel %s' % self.channel)
        shutil.copyfile(self.conf_template, self.conf_file)

        self.find_replace('__CHANNEL__', self.channel)
        self.find_replace('__DATABASE__', '%s.db' % self.channel_name)
        if self.channel.find('-') > 0:
            self.find_replace('__LOGFILE_DATEFORMAT__', '*-*.Y-m-d.*')
        else:
            self.find_replace('__LOGFILE_DATEFORMAT__', '*.Y-m-d.*')

    def init_database(self):
        """ initialize sqlite3 database for this channel """
        LOG.debug('Initializing database for channel %s' % self.channel)
        try:
            template = subprocess.Popen(['cat', self.sqlite_template],
                                        stdout=subprocess.PIPE)
            subprocess.Popen(['sqlite3', self.db_file],
                             stdin=template.stdout,
                             stdout=subprocess.PIPE).communicate()
        except OSError as err:
            LOG.error('Database initialization failed %s ...' % err)
            raise

    def is_configured(self):
        """ return True if stats are installed for this channel, False
        otherwise """
        return os.path.exists(self.conf_file)

    def install(self):
        """ install all pieces to keep it up """
        # This method install superseriousstats for each channel. Only the
        # files changed are installed, using rsync. If no files changed (in
        # git), do nothing in this step.
        LOG.debug('Installing stats for channel %s' % self.channel)
        # superseriousstats source code is cloned from git using puppet. If
        # source code is not found, it is likely puppet has not run or it had
        # failed.
        if not os.path.exists(SSS_CLONE_DIR):
            LOG.critical('Superseriousstats code not cloned. Ensure '
                         'puppet agent has run and cloned the source code '
                         'in %s directory' % SSS_CLONE_DIR)
            sys.exit(1)

        exec_command('rsync -avh %s/ %s' % (SSS_CLONE_DIR, self.install_dir))
        if not self.is_configured():
            self.generate_configuration()
            self.init_database()
        self.install_supporting_files()

    def install_supporting_files(self):
        """ post install """
        # create vars.php file
        conf_file = r'%s' % self.conf_file
        cmd = 'php sss.php -c %s -s' % conf_file
        vars_code = exec_command(cmd, cwd=self.install_dir)[0]
        vars_file = os.path.join(self.install_dir, 'vars.php')
        vars_code = '<?php\n%s?>\n' % vars_code
        LOG.debug('Generating %s file ...\n%s' % (vars_file, vars_code))

        def _md5(filename):
            if os.path.exists(filename):
                return hashlib.md5(open(filename, 'rb').read()).hexdigest()
            return None

        with open(vars_file, 'w') as wp:
            wp.write(vars_code)

        # create other supporting files to render UI
        files = ['favicon.ico', 'history.php', 'sss.css', 'user.php']
        for _file in files:
            source = os.path.join(self.install_dir, 'www', _file)
            dest = os.path.join(self.install_dir, _file)
            # install supporting file only if it is not already installed, or
            # it's changed since last run.
            if _md5(source) != _md5(dest):
                LOG.debug('Copying %s -> %s' % (source, dest))
                shutil.copyfile(source, dest)
            else:
                LOG.debug('file %s unchanged since last run' % source)

    def generate(self):
        """ generate the incremental stats """
        LOG.info('Generating stats for channel %s' % self.channel)

        conf_file = r'%s' % self.conf_file
        channel_log_dir = os.path.join(self.irclog_base, self.channel)
        cmd = 'php sss.php -c %s -i %s -o index.html' % (conf_file,
                                                         channel_log_dir)
        out = exec_command(cmd, cwd=self.install_dir)[0]
        LOG.info(out)


def main():
    opts = getopts()
    if opts.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    if not opts.channel:
        channels = [d for d in os.listdir(opts.irclog_base)
                    if os.path.isdir(os.path.join(opts.irclog_base, d)) and
                    d.startswith('#')]
    else:
        channels = opts.channel

    LOG.debug('Processing IRC channels ... %s' % channels)
    for channel in channels:
        stats = SuperSeriousStats(channel,
                                  opts.install_base,
                                  opts.conf_template,
                                  opts.irclog_base)
        stats.install()
        stats.generate()


if __name__ == '__main__':
    main()
