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
import Queue
import socket
import sys
import threading
import time
import urllib2
import yaml


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


class LogRetriever(threading.Thread):
    def __init__(self, gearman_worker, logq):
        threading.Thread.__init__(self)
        self.gearman_worker = gearman_worker
        self.logq = logq

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
            tags = event.get('tags') or event.get('@tags')
            if fields['build_status'] != 'ABORTED':
                # Handle events ignoring aborted builds. These builds are
                # discarded by zuul.
                log_lines = self._retrieve_log(source_url, retry)

                logging.debug("Pushing " + str(len(log_lines)) + " log lines.")
                base_event = {}
                base_event.update(fields)
                base_event["tags"] = tags
                for line in log_lines:
                    out_event = base_event.copy()
                    out_event["message"] = line
                    self.logq.put(out_event)
            job.sendWorkComplete()
        except Exception as e:
            logging.exception("Exception handling log event.")
            job.sendWorkException(str(e).encode('utf-8'))

    def _retrieve_log(self, source_url, retry):
        # TODO (clarkb): This should check the content type instead of file
        # extension for determining if gzip was used.
        gzipped = False
        raw_buf = b''
        try:
            gzipped, raw_buf = self._get_log_data(source_url, retry)
        except urllib2.HTTPError, e:
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
            buf = f.read().decode('utf-8')
            raw_strIO.close()
            f.close()
        else:
            logging.debug("Decoding source file.")
            buf = raw_buf.decode('utf-8')
        return buf.splitlines()

    def _get_log_data(self, source_url, retry):
        gzipped = False
        try:
            # TODO(clarkb): We really should be using requests instead
            # of urllib2. urllib2 will automatically perform a POST
            # instead of a GET if we provide urlencoded data to urlopen
            # but we need to do a GET. The parameters are currently
            # hardcoded so this should be ok for now.
            logging.debug("Retrieving: " + source_url + ".gz?level=INFO")
            req = urllib2.Request(source_url + ".gz?level=INFO")
            req.add_header('Accept-encoding', 'gzip')
            r = urllib2.urlopen(req)
        except urllib2.URLError:
            try:
                # Fallback on GETting unzipped data.
                logging.debug("Retrieving: " + source_url + "?level=INFO")
                r = urllib2.urlopen(source_url + "?level=INFO")
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
        # asynchronously. After each attempt do an exponential backup before
        # the next request for up to 255 seconds total, if we do not
        # retrieve the entire file. Short circuit when the end of file string
        # for console logs, '\n</pre>\n', is read.
        if (retry and not gzipped and
            raw_buf[-8:].decode('utf-8') != '\n</pre>\n'):
            content_len = len(raw_buf)
            backoff = 1
            while backoff < 129:
                # Try for up to 255 seconds to retrieve the complete log file.
                try:
                    logging.debug(str(backoff) + " Retrying fetch of: " +
                                  source_url + "?level=INFO")
                    logging.debug("Fetching bytes="  + str(content_len) + '-')
                    req = urllib2.Request(source_url + "?level=INFO")
                    req.add_header('Range', 'bytes=' + str(content_len) + '-')
                    r = urllib2.urlopen(req)
                    raw_buf += r.read()
                    content_len = len(raw_buf)
                except urllib2.HTTPError as e:
                    if e.code == 416:
                        logging.exception("Index out of range.")
                    else:
                        raise
                finally:
                    if raw_buf[-8:].decode('utf-8') == '\n</pre>\n':
                        break
                    semi_busy_wait(backoff)
                    backoff += backoff

        return gzipped, raw_buf


class StdOutLogProcessor(object):
    def __init__(self, logq, pretty_print=False):
        self.logq = logq
        self.pretty_print = pretty_print

    def handle_log_event(self):
        log = self.logq.get()
        if self.pretty_print:
            print(json.dumps(log, sort_keys=True,
                  indent=4, separators=(',', ': ')))
        else:
            print(json.dumps(log))
        # Push each log event through to keep logstash up to date.
        sys.stdout.flush()


class INETLogProcessor(object):
    socket_type = None

    def __init__(self, logq, host, port):
        self.logq = logq
        self.host = host
        self.port = port
        self._connect_socket()

    def _connect_socket(self):
        logging.debug("Creating socket.")
        self.socket = socket.socket(socket.AF_INET, self.socket_type)
        self.socket.connect((self.host, self.port))

    def handle_log_event(self):
        log = self.logq.get()
        try:
            self.socket.sendall((json.dumps(log) + '\n').encode('utf-8'))
        except:
            logging.exception("Exception sending INET event.")
            # Logstash seems to take about a minute to start again. Wait 90
            # seconds before attempting to reconnect. If logstash is not
            # available after 90 seconds we will throw another exception and
            # die.
            semi_busy_wait(90)
            self._connect_socket()
            self.socket.sendall((json.dumps(log) + '\n').encode('utf-8'))


class UDPLogProcessor(INETLogProcessor):
    socket_type = socket.SOCK_DGRAM


class TCPLogProcessor(INETLogProcessor):
    socket_type = socket.SOCK_STREAM


class Server(object):
    def __init__(self, config, debuglog):
        # Config init.
        self.config = config
        self.gearman_host = self.config['gearman-host']
        self.gearman_port = self.config['gearman-port']
        self.output_host = self.config['output-host']
        self.output_port = self.config['output-port']
        self.output_mode = self.config['output-mode']
        # Pythong logging output file.
        self.debuglog = debuglog
        self.retriever = None
        self.logqueue = Queue.Queue(131072)
        self.processor = None

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
        gearman_worker.registerFunction(b'push-log')
        self.retriever = LogRetriever(gearman_worker, self.logqueue)

    def setup_processor(self):
        if self.output_mode == "tcp":
            self.processor = TCPLogProcessor(self.logqueue,
                                             self.output_host,
                                             self.output_port)
        elif self.output_mode == "udp":
            self.processor = UDPLogProcessor(self.logqueue,
                                             self.output_host,
                                             self.output_port)
        else:
            # Note this processor will not work if the process is run as a
            # daemon. You must use the --foreground option.
            self.processor = StdOutLogProcessor(self.logqueue)

    def main(self):
        self.setup_retriever()
        self.setup_processor()

        self.retriever.daemon = True
        self.retriever.start()

        while True:
            try:
                self.processor.handle_log_event()
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
                        default="/var/run/jenkins-log-pusher/"
                                "jenkins-log-gearman-worker.pid",
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
