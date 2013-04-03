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
import threading
import time
import queue
import urllib.error
import urllib.request
import zmq


class EventCatcher(threading.Thread):
    def __init__(self, eventq, zmq_address):
        threading.Thread.__init__(self)
        self.eventq = eventq
        self.zmq_address = zmq_address
        self._connect_zmq()

    def run(self):
        while True:
            try:
                self._read_event()
            except:
                # Assume that an error reading data from zmq or deserializing
                # data received from zmq indicates a zmq error and reconnect.
                self._connect_zmq()

    def _connect_zmq(self):
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.SUB)
        event_filter = b"onFinalized"
        self.socket.setsockopt(zmq.SUBSCRIBE, event_filter)
        self.socket.connect(self.zmq_address)

    def _read_event(self):
        string = self.socket.recv().decode('utf-8')
        event = json.loads(string.split(None, 1)[1])
        self.eventq.put(event)


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

    def __init__(self, eventq, logq, log_address, filename, retry=False):
        threading.Thread.__init__(self)
        self.eventq = eventq
        self.logq = logq
        self.retry = retry
        self.log_address = log_address
        self.filename = filename

    def run(self):
        while True:
            self._handle_event()

    def _handle_event(self):
        event = self.eventq.get()
        fields = self._parse_fields(event)
        if fields['build_status'] != 'ABORTED':
            # Handle events ignoring aborted builds. These builds are
            # discarded by zuul.
            log_lines = self._retrieve_log(fields)

            for line in log_lines:
                out_event = {}
                out_event["@fields"] = fields
                out_event["@message"] = line
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
            pass
        if gzipped:
            buf = gzip.decompress(raw_buf).decode('utf-8')
        else:
            buf = raw_buf.decode('utf-8')
        return buf.splitlines()

    def _get_log_data(self, log_address, log_dir, filename):
        gzipped = False
        source_url = log_address + log_dir + filename
        try:
            r = urllib.request.urlopen(source_url)
        except urllib.error.URLError:
            try:
                r = urllib.request.urlopen(source_url + ".gz")
                gzipped = True
            except:
                raise
        except:
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
                    req = urllib.request.Request(source_url)
                    req.add_header('bytes', str(content_len) + '-')
                    r = urllib.request.urlopen(req)
                    raw_buf += r.read()
                    content_len = len(raw_buf)
                finally:
                    if raw_buf[-8:].decode('utf-8') == '\n</pre>\n':
                        break
                    time.sleep(1)

        return gzipped, raw_buf


class LogProcessor(object):
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-z", "--zmqaddress", required=True,
                        help="Address to use as source for zmq events.")
    parser.add_argument("-l", "--logaddress", required=True,
                        help="Http(s) address to use as source for log files.")
    parser.add_argument("-f", "--filename", required=True,
                        help="Name of log file to retrieve from log server.")
    parser.add_argument("-p", "--pretty", action="store_true",
                        help="Print pretty json.")
    parser.add_argument("-r", "--retry", action="store_true",
                        help="Retry until full console log is retrieved.")
    args = parser.parse_args()

    eventqueue = queue.Queue()
    logqueue = queue.Queue()
    catcher = EventCatcher(eventqueue, args.zmqaddress)
    retriever = LogRetriever(eventqueue, logqueue, args.logaddress,
                             args.filename, retry=args.retry)
    processor = LogProcessor(logqueue, pretty_print=args.pretty)

    catcher.daemon = True
    catcher.start()
    retriever.daemon = True
    retriever.start()
    while True:
        processor.handle_log_event()


if __name__ == '__main__':
    main()
