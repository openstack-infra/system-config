#!/usr/bin/python3
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
import fcntl
import gzip
import json
import logging
import os
import queue
import re
import resource
import socket
import sys
import threading
import time
import urllib.error
import urllib.request
import yaml
import zmq


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


class EventCatcher(threading.Thread):
    def __init__(self, eventqs, zmq_address):
        threading.Thread.__init__(self)
        self.eventqs = eventqs
        self.zmq_address = zmq_address
        self._connect_zmq()

    def run(self):
        while True:
            try:
                self._read_event()
            except:
                # Assume that an error reading data from zmq or deserializing
                # data received from zmq indicates a zmq error and reconnect.
                logging.exception("ZMQ exception.")
                self._connect_zmq()

    def _connect_zmq(self):
        logging.debug("Connecting to zmq endpoint.")
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.SUB)
        event_filter = b"onFinalized"
        self.socket.setsockopt(zmq.SUBSCRIBE, event_filter)
        self.socket.connect(self.zmq_address)

    def _read_event(self):
        string = self.socket.recv().decode('utf-8')
        event = json.loads(string.split(None, 1)[1])
        logging.debug("Jenkins event received: " + json.dumps(event))
        for eventq in self.eventqs:
            eventq.put(event)


class LogRetriever(threading.Thread):
    log_dirs = {
        'check': "/{build_change}/{build_patchset}/{build_queue}/"
                 "{build_name}/{build_number}/",
        'gate': "/{build_change}/{build_patchset}/{build_queue}/"
                "{build_name}/{build_number}/",
        'post': "/{build_shortref}/{build_queue}/{build_name}/"
                "{build_number}/",
        'pre-release': "/{build_shortref}/{build_queue}/{build_name}/"
                       "{build_number}/",
        'release': "/{build_shortref}/{build_queue}/{build_name}/"
                   "{build_number}/",
        'UNKNOWN': "/periodic/{build_name}/{build_number}/",
    }

    def __init__(self, eventq, logq, log_address,
                 filename, retry=False, job_filter='', tags=None):
        threading.Thread.__init__(self)
        self.eventq = eventq
        self.logq = logq
        self.retry = retry
        self.log_address = log_address
        self.filename = filename
        self.job_filter = job_filter
        self.tags = [self.filename]
        if tags:
            self.tags.extend(tags)

    def run(self):
        while True:
            try:
                self._handle_event()
            except:
                logging.exception("Exception retrieving log event.")

    def _handle_event(self):
        event = self.eventq.get()
        logging.debug("Handling event: " + json.dumps(event))
        fields = self._parse_fields(event)
        matches = re.search(self.job_filter, fields['build_name'])
        if fields['build_status'] != 'ABORTED' and matches:
            # Handle events ignoring aborted builds. These builds are
            # discarded by zuul.
            log_lines = self._retrieve_log(fields)

            logging.debug("Pushing " + str(len(log_lines)) + " log lines.")
            for line in log_lines:
                out_event = {}
                out_event["@fields"] = fields
                out_event["@tags"] = self.tags
                out_event["event_message"] = line
                self.logq.put(out_event)

    def _parse_fields(self, event):
        fields = {}
        fields["build_name"] = event.get("name", "UNKNOWN")
        fields["build_status"] = event["build"].get("status", "UNKNOWN")
        fields["build_number"] = event["build"].get("number", "UNKNOWN")
        parameters = event["build"].get("parameters", {})
        fields["build_queue"] = parameters.get("ZUUL_PIPELINE", "UNKNOWN")
        if fields["build_queue"] in ["check", "gate"]:
            fields["build_change"] = parameters.get("ZUUL_CHANGE", "UNKNOWN")
            fields["build_patchset"] = parameters.get("ZUUL_PATCHSET",
                                                      "UNKNOWN")
        elif fields["build_queue"] in ["post", "pre-release", "release"]:
            fields["build_shortref"] = parameters.get("ZUUL_SHORT_NEWREV",
                                                      "UNKNOWN")
        return fields

    def _retrieve_log(self, fields):
        # TODO (clarkb): This should check the content type instead of file
        # extension for determining if gzip was used.
        log_dir = self.log_dirs.get(fields["build_queue"], "").format(**fields)
        gzipped = False
        raw_buf = b''
        try:
            gzipped, raw_buf = self._get_log_data(self.log_address, log_dir,
                                                  self.filename)
        except:
            # Silently drop fatal errors when retrieving logs.
            # TODO (clarkb): Handle these errors.
            # Perhaps simply add a log message to raw_buf?
            logging.exception("Unable to get log data.")
        if gzipped:
            logging.debug("Decompressing gzipped source file.")
            buf = gzip.decompress(raw_buf).decode('utf-8')
        else:
            logging.debug("Decoding source file.")
            buf = raw_buf.decode('utf-8')
        return buf.splitlines()

    def _get_log_data(self, log_address, log_dir, filename):
        gzipped = False
        source_url = log_address + log_dir + filename
        try:
            logging.debug("Retrieving: " + source_url)
            r = urllib.request.urlopen(source_url)
        except urllib.error.URLError:
            try:
                logging.debug("Retrieving: " + source_url + ".gz")
                r = urllib.request.urlopen(source_url + ".gz")
                gzipped = True
            except:
                logging.exception("Unable to retrieve source file.")
                raise
        except:
            logging.exception("Unable to retrieve source file.")
            raise

        raw_buf = r.read()
        # Hack to read all of Jenkins console logs as they upload
        # asynchronously. Make one attempt per second for up to 60 seconds to
        # retrieve the entire file. Short circuit when the end of file string
        # for console logs, '\n</pre>\n', is read.
        if (self.retry and not gzipped and
            raw_buf[-8:].decode('utf-8') != '\n</pre>\n'):
            content_len = len(raw_buf)
            for i in range(60):
                # Try for up to 60 seconds to retrieve the complete log file.
                try:
                    logging.debug(str(i) + " Retrying fetch of: " + source_url)
                    logging.debug("Fetching bytes="  + str(content_len) + '-')
                    req = urllib.request.Request(source_url)
                    req.add_header('Range', 'bytes=' + str(content_len) + '-')
                    r = urllib.request.urlopen(req)
                    raw_buf += r.read()
                    content_len = len(raw_buf)
                except urllib.error.HTTPError as e:
                    if e.code == 416:
                        logging.exception("Index out of range.")
                    else:
                        raise
                finally:
                    if raw_buf[-8:].decode('utf-8') == '\n</pre>\n':
                        break
                    semi_busy_wait(1)

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
        self.defaults = self.config['source-defaults']
        self.default_source_url = self.defaults['source-url']
        self.default_output_host = self.defaults['output-host']
        self.default_output_port = self.defaults['output-port']
        self.default_output_mode = self.defaults['output-mode']
        self.default_retry = self.defaults['retry-get']
        # Pythong logging output file.
        self.debuglog = debuglog
        # Input, retriever, output details
        self.catchers = []
        self.event_queues = []
        self.retrievers = []
        # TODO(clarkb) support multiple outputs
        self.logqueue = queue.Queue()
        self.processor = None

    def setup_logging(self):
        if self.debuglog:
            logging.basicConfig(format='%(asctime)s %(message)s',
                                filename=self.debuglog, level=logging.DEBUG)
        else:
            # Prevent leakage into the logstash log stream.
            logging.basicConfig(level=logging.CRITICAL)
        logging.debug("Log pusher starting.")

    def setup_retrievers(self):
        for source_file in self.config['source-files']:
            eventqueue = queue.Queue()
            self.event_queues.append(eventqueue)
            retriever = LogRetriever(eventqueue, self.logqueue,
                                     source_file.get('source-url',
                                                     self.default_source_url),
                                     source_file['name'],
                                     retry=source_file.get('retry-get',
                                                           self.default_retry),
                                     job_filter=source_file.get('filter', ''),
                                     tags=source_file.get('tags', []))
            self.retrievers.append(retriever)

    def setup_catchers(self):
        for zmq_publisher in self.config['zmq-publishers']:
            catcher = EventCatcher(self.event_queues, zmq_publisher)
            self.catchers.append(catcher)

    def setup_processor(self):
        if self.default_output_mode == "tcp":
            self.processor = TCPLogProcessor(self.logqueue,
                                             self.default_output_host,
                                             self.default_output_port)
        elif self.default_output_mode == "udp":
            self.processor = UDPLogProcessor(self.logqueue,
                                             self.default_output_host,
                                             self.default_output_port)
        else:
            # Note this processor will not work if the process is run as a
            # daemon. You must use the --foreground option.
            self.processor = StdOutLogProcessor(self.logqueue)

    def main(self):
        self.setup_retrievers()
        self.setup_catchers()
        self.setup_processor()

        for catcher in self.catchers:
            catcher.daemon = True
            catcher.start()
        for retriever in self.retrievers:
            retriever.daemon = True
            retriever.start()

        while True:
            try:
                self.processor.handle_log_event()
            except:
                logging.exception("Exception processing log event.")
                raise


class DaemonContext(object):
    def __init__(self, pidfile_path):
        self.pidfile_path = pidfile_path
        self.pidfile = None
        self.pidlocked = False

    def __enter__(self):
        # Perform Sys V daemonization steps as defined by
        # http://www.freedesktop.org/software/systemd/man/daemon.html
        # Close all open file descriptors but std*
        _, max_fds = resource.getrlimit(resource.RLIMIT_NOFILE)
        if max_fds == resource.RLIM_INFINITY:
            max_fds = 4096
        for fd in range(3, max_fds):
            try:
                os.close(fd)
            except OSError:
                # TODO(clarkb) check e.errno.
                # fd not open.
                pass

        # TODO(clarkb) reset all signal handlers to their default
        # TODO(clarkb) reset signal mask
        # TODO(clarkb) sanitize environment block

        # Fork to create background process
        # TODO(clarkb) pass in read end of pipe and have parent wait for
        # bytes on the pipe before exiting.
        self._fork_exit_parent()
        # setsid() to detach from terminal and create independent session.
        os.setsid()
        # Fork again to prevent reaquisition of terminal
        self._fork_exit_parent()

        # Hook std* to /dev/null.
        devnull = os.open(os.devnull, os.O_RDWR)
        os.dup2(devnull, 0)
        os.dup2(devnull, 1)
        os.dup2(devnull, 2)

        # Set umask to 0
        os.umask(0)
        # chdir to root of filesystem.
        os.chdir(os.sep)

        # Lock pidfile.
        self.pidfile = open(self.pidfile_path, 'a')
        try:
            fcntl.lockf(self.pidfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.pidlocked = True
        except IOError:
            # another instance is running
            sys.exit(0)
        self.pidfile.truncate(0)
        self.pidfile.write(str(os.getpid()))
        self.pidfile.flush()

    def __exit__(self, exc_type, exc_value, traceback):
        # remove pidfile
        if self.pidlocked:
            os.unlink(self.pidfile_path)
        if self.pidfile:
            self.pidfile.close()
        # TODO(clarkb) write to then close parent signal pipe if not
        # already done.

    def _fork_exit_parent(self, read_pipe=None):
        if os.fork():
            # Parent
            if read_pipe:
                os.fdopen(read_pipe).read()
            sys.exit()
        else:
            # Child
            return


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
                                "jenkins-log-pusher.pid",
                        help="PID file to lock during daemonization.")
    args = parser.parse_args()

    with open(args.config, 'r') as config_stream:
        config = yaml.load(config_stream)
    server = Server(config, args.debuglog)

    if args.foreground:
        server.setup_logging()
        server.main()
    else:
        with DaemonContext(args.pidfile):
            server.setup_logging()
            server.main()


if __name__ == '__main__':
    main()
