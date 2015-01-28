#!/usr/bin/python2
#
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

import argparse
import cStringIO
import daemon
import gear
import gzip
import json
import logging
import os
import Queue
import socket
import subprocess
import threading
import time
import urllib2
import yaml

from subunit2sql import read_subunit
from subunit2sql import shell


try:
    import daemon.pidlockfile as pidfile_mod
except ImportError:
    import daemon.pidfile as pidfile_mod


def semi_busy_wait(seconds):
    # time.sleep() may return early. If it does sleep() again and repeat
    # until at least the number of seconds specified has elapsed.
    start_time = time.time()
    while True:
        time.sleep(seconds)
        cur_time = time.time()
        seconds = seconds - (cur_time - start_time)
        if seconds <= 0.0:
            return


class FilterException(Exception):
    pass


class SubunitRetriever(threading.Thread):
    def __init__(self, gearman_worker, filters, subunitq):
        threading.Thread.__init__(self)
        self.gearman_worker = gearman_worker
        self.filters = filters
        self.subunitq = subunitq

    def run(self):
        while True:
            try:
                self._handle_event()
            except:
                logging.exception("Exception retrieving log event.")

    def _handle_event(self):
        job = self.gearman_worker.getJob()
        try:
            arguments = json.loads(job.arguments.decode('utf-8'))
            source_url = arguments['source_url']
            retry = arguments['retry']
            event = arguments['event']
            logging.debug("Handling event: " + json.dumps(event))
            fields = event.get('fields') or event.get('@fields')
            if fields.pop('build_status') != 'ABORTED':
                # Handle events ignoring aborted builds. These builds are
                # discarded by zuul.
                subunit_io = self._retrieve_subunit_v2(source_url, retry)
                logging.debug("Pushing subunit files.")
                out_event = fields.copy()
                out_event["subunit"] = subunit_io
                self.subunitq.put(out_event)
            job.sendWorkComplete()
        except Exception as e:
            logging.exception("Exception handling log event.")
            job.sendWorkException(str(e).encode('utf-8'))

    def _subunit_1_to_2(self, raw_file):
        call = subprocess.Popen('subunit-1to2', stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE)
        output, err = call.communicate(raw_file.read())
        if err:
            raise Exception(err)
        buf = cStringIO.StringIO(output)
        return buf

    def _retrieve_subunit_v2(self, source_url, retry):
        # TODO (clarkb): This should check the content type instead of file
        # extension for determining if gzip was used.
        gzipped = False
        raw_buf = b''
        try:
            gzipped, raw_buf = self._get_subunit_data(source_url, retry)
        except urllib2.HTTPError as e:
            if e.code == 404:
                logging.info("Unable to retrieve %s: HTTP error 404" %
                             source_url)
            else:
                logging.exception("Unable to get log data.")
        except Exception:
            # Silently drop fatal errors when retrieving logs.
            # TODO (clarkb): Handle these errors.
            # Perhaps simply add a log message to raw_buf?
            logging.exception("Unable to get log data.")
        if gzipped:
            logging.debug("Decompressing gzipped source file.")
            raw_strIO = cStringIO.StringIO(raw_buf)
            f = gzip.GzipFile(fileobj=raw_strIO)
            buf = self._subunit_1_to_2(f)
            raw_strIO.close()
            f.close()
        else:
            logging.debug("Decoding source file.")
            raw_strIO = cStringIO.StringIO(raw_buf)
            buf = self._subunit_1_to_2(raw_strIO)
        return buf

    def _get_subunit_data(self, source_url, retry):
        gzipped = False
        try:
            # TODO(clarkb): We really should be using requests instead
            # of urllib2. urllib2 will automatically perform a POST
            # instead of a GET if we provide urlencoded data to urlopen
            # but we need to do a GET. The parameters are currently
            # hardcoded so this should be ok for now.
            logging.debug("Retrieving: " + source_url + ".gz")
            req = urllib2.Request(source_url + ".gz")
            req.add_header('Accept-encoding', 'gzip')
            r = urllib2.urlopen(req)
        except urllib2.URLError:
            try:
                # Fallback on GETting unzipped data.
                logging.debug("Retrieving: " + source_url)
                r = urllib2.urlopen(source_url)
            except:
                logging.exception("Unable to retrieve source file.")
                raise
        except:
            logging.exception("Unable to retrieve source file.")
            raise
        if ('gzip' in r.info().get('Content-Type', '') or
            'gzip' in r.info().get('Content-Encoding', '')):
            gzipped = True

        raw_buf = r.read()
        # Hack to read all of Jenkins console logs as they upload
        return gzipped, raw_buf


class Subunit2SQLProcessor(object):
    def __init__(self, subunitq, subunit2sql_conf):
        self.subunitq = subunitq
        self.config = subunit2sql_conf
        # Initialize subunit2sql settings
        shell.cli_opts()
        shell.parse_args([], [self.config])

    def handle_subunit_event(self):
        # Pull subunit event from queue and separate stream from metadata
        subunit = self.subunitq.get()
        subunit_v2 = subunit.pop('subunit')
        # Set run metadata from gearman
        log_url = subunit.pop('log_url', None)
        if log_url:
            log_dir = os.path.dirname(os.path.dirname(log_url))
            shell.CONF.set_override('artifacts', log_dir)
        shell.CONF.set_override('run_meta', subunit)
        # Parse subunit stream and store in DB
        logging.debug('Converting Subunit V2 stream to SQL')
        stream = read_subunit.ReadSubunit(subunit_v2)
        shell.process_results(stream.get_results())


class Server(object):
    def __init__(self, config, debuglog):
        # Config init.
        self.config = config
        self.gearman_host = self.config['gearman-host']
        self.gearman_port = self.config['gearman-port']
        # Pythong logging output file.
        self.debuglog = debuglog
        self.retriever = None
        self.subunitqueue = Queue.Queue(131072)
        self.processor = None
        self.filter_factories = []

    def setup_logging(self):
        if self.debuglog:
            logging.basicConfig(format='%(asctime)s %(message)s',
                                filename=self.debuglog, level=logging.DEBUG)
        else:
            # Prevent leakage into the logstash log stream.
            logging.basicConfig(level=logging.CRITICAL)
        logging.debug("Log pusher starting.")

    def setup_retriever(self):
        hostname = socket.gethostname()
        gearman_worker = gear.Worker(hostname + b'-pusher')
        gearman_worker.addServer(self.gearman_host,
                                 self.gearman_port)
        gearman_worker.registerFunction(b'push-subunit')
        self.retriever = SubunitRetriever(gearman_worker,
                                          self.filter_factories,
                                          self.subunitqueue)

    def setup_processor(self):
        # Note this processor will not work if the process is run as a
        # daemon. You must use the --foreground option.
        subunit2sql_config = self.config['config']
        self.processor = Subunit2SQLProcessor(self.subunitqueue,
                                              subunit2sql_config)

    def main(self):
        self.setup_retriever()
        self.setup_processor()

        self.retriever.daemon = True
        self.retriever.start()

        while True:
            try:
                self.processor.handle_subunit_event()
            except:
                logging.exception("Exception processing log event.")
                raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config", required=True,
                        help="Path to yaml config file.")
    parser.add_argument("-d", "--debuglog",
                        help="Enable debug log. "
                             "Specifies file to write log to.")
    parser.add_argument("--foreground", action='store_true',
                        help="Run in the foreground.")
    parser.add_argument("-p", "--pidfile",
                        default="/var/run/jenkins-subunit-pusher/"
                                "jenkins-subunit-gearman-worker.pid",
                        help="PID file to lock during daemonization.")
    args = parser.parse_args()

    with open(args.config, 'r') as config_stream:
        config = yaml.load(config_stream)
    server = Server(config, args.debuglog)

    if args.foreground:
        server.setup_logging()
        server.main()
    else:
        pidfile = pidfile_mod.TimeoutPIDLockFile(args.pidfile, 10)
        with daemon.DaemonContext(pidfile=pidfile):
            server.setup_logging()
            server.main()


if __name__ == '__main__':
    main()
