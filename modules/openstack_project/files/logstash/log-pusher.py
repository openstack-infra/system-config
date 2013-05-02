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
import gzip
import json
import logging
import threading
import time
import queue
import re
import socket
import sys
import urllib.error
import urllib.request
import yaml
import zmq


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
                 filename, retry=False, job_filter=''):
        threading.Thread.__init__(self)
        self.eventq = eventq
        self.logq = logq
        self.retry = retry
        self.log_address = log_address
        self.filename = filename
        self.job_filter = job_filter
        self.tag = [self.filename]

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
                out_event["@tags"] = self.tag
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
                    self._semi_busy_wait(1)

        return gzipped, raw_buf

    def _semi_busy_wait(self, seconds):
        # time.sleep() may return early. If it does sleep() again and repeat
        # until at least the number of seconds specified has elapsed.
        start_time = time.time()
        while True:
            time.sleep(seconds)
            cur_time = time.time()
            seconds = seconds - (cur_time - start_time)
            if seconds <= 0.0:
                return


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
            self._connect_socket()


class UDPLogProcessor(INETLogProcessor):
    socket_type = socket.SOCK_DGRAM


class TCPLogProcessor(INETLogProcessor):
    socket_type = socket.SOCK_STREAM


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config", required=True,
                        help="Path to yaml config file.")
    parser.add_argument("-d", "--debuglog",
                        help="Enable debug log. "
                             "Specifies file to write log to.")
    args = parser.parse_args()

    if args.debuglog:
        logging.basicConfig(format='%(asctime)s %(message)s',
                            filename=args.debuglog, level=logging.DEBUG)
    else:
        # Prevent leakage into the logstash log stream.
        logging.basicConfig(level=logging.CRITICAL)
    logging.debug("Log pusher starting.")

    config_stream = open(args.config, 'r')
    config = yaml.load(config_stream)
    defaults = config['source-defaults']
    default_source_url = defaults['source-url']
    default_output_host = defaults['output-host']
    default_output_port = defaults['output-port']
    default_output_mode = defaults['output-mode']
    default_retry = defaults['retry-get']

    event_queues = []
    # TODO(clarkb) support multiple outputs
    logqueue = queue.Queue()
    retrievers = []
    for source_file in config['source-files']:
        eventqueue = queue.Queue()
        event_queues.append(eventqueue)
        retriever = LogRetriever(eventqueue, logqueue,
                                 source_file.get('source-url',
                                                 default_source_url),
                                 source_file['name'],
                                 retry=source_file.get('retry-get',
                                                       default_retry),
                                 job_filter=source_file.get('filter',
                                                            ''))
        retrievers.append(retriever)

    catchers = []
    for zmq_publisher in config['zmq-publishers']:
        catcher = EventCatcher(event_queues, zmq_publisher)
        catchers.append(catcher)

    if default_output_mode == "tcp":
        processor = TCPLogProcessor(logqueue,
                                    default_output_host, default_output_port)
    elif default_output_mode == "udp":
        processor = UDPLogProcessor(logqueue,
                                    default_output_host, default_output_port)
    else:
        processor = StdOutLogProcessor(logqueue)

    for catcher in catchers:
        catcher.daemon = True
        catcher.start()
    for retriever in retrievers:
        retriever.daemon = True
        retriever.start()

    while True:
        try:
            processor.handle_log_event()
        except:
            logging.exception("Exception processing log event.")
            raise


if __name__ == '__main__':
    main()
