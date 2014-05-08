#!/usr/bin/env python
# Copyright 2014 Hewlett-Packard Development Company, L.P.
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
import yaml


class SafeYaml(yaml.YAMLObject):
    yaml_loader = yaml.SafeLoader


class PuppetUtilMetric(SafeYaml):
    yaml_tag = u'!ruby/object:Puppet::Util::Metric'

    def __init__(self, *args, **kwargs):
        pass


class PuppetTransactionEvent(SafeYaml):
    yaml_tag = u'!ruby/object:Puppet::Transaction::Event'

    def __init__(self, *args, **kwargs):
        pass


class PuppetResourceStatus(object):

    def __init__(
            self, resource, filename, line, evaluation_time, change_count,
            out_of_sync_count, tags, time, events, out_of_sync, changed,
            title, skipped, failed, resource_type):
        self.resource = resource
        self.filename = filename
        self.line = line
        self.evaluation_time = evaluation_time
        self.change_count = change_count
        self.out_of_sync_count = out_of_sync_count
        self.tags = tags
        self.time = time
        self.events = events
        self.out_of_sync = out_of_sync
        self.changed = changed
        self.title = title
        self.skipped = skipped
        self.failed = failed
        self.resource_type = resource_type
        if failed:
            self.status = 'FAILED'
        else:
            self.status = 'SUCCEEDED'

    def __repr__(self):
        if self.failed:
            return 'FAILED: %s line %s' % (self.resource, self.line)
        return "SUCCEEDED: %s" % self.resource


class PuppetTransactionReport(SafeYaml):
    yaml_tag = u'!ruby/object:Puppet::Transaction::Report'

    def __init__(
            self, status, metrics, host, configuration_version,
            environment, puppet_version, time, report_format,
            logs, resource_statuses, kind):
        self.status = status
        self.metrics = metrics
        self.host = host
        self.configuration_version = configuration_version,
        self.environment = environment
        self.puppet_version = puppet_version
        self.time = time
        self.report_format = report_format
        self.logs = logs
        self.resource_statuses = resource_statuses,
        self.kind = kind

    def __repr__(self):
        head = "## %s: %s - %s" % (self.status.upper(), self.host, self.time)
        statuses = "\n".join([
            "%s: %s" % (resource, repr(status))
            for (resource, status) in self.resource_statuses.items()])
        logs = "\n".join([repr(log) for log in self.logs])
        return "%s\n%s\n%s" % (head, statuses, logs)

    def failed(self):
        if self.status == 'failed':
            return True
        return any([s.failed for (r, s) in self.resource_statuses.items()])


class PuppetUtilLog(SafeYaml):
    yaml_tag = u'!ruby/object:Puppet::Util::Log'

    def __init__(self, level, tags, time, message, source):
        self.level = level
        self.tags = tags
        self.time = time
        self.message = message
        self.source = source

    def __repr__(self):
        return "%s: %s, %s" % (self.level, self.time, self.message)


class RubySym(object):
    def __init__(self, value):
        self.value = value

    def __repr__(self):
        return self.value.upper()


def resource_constructor(loader, node):
    value = loader.construct_mapping(node)
    value['filename'] = value['file']
    del(value['file'])
    return PuppetResourceStatus(**value)


def sym_constructor(loader, node):
    value = loader.construct_scalar(node)
    return RubySym(value)


def main():
    yaml.add_constructor(
        u'!ruby/object:Puppet::Resource::Status', resource_constructor,
        Loader=yaml.SafeLoader)
    yaml.add_constructor(u'!ruby/sym', sym_constructor, Loader=yaml.SafeLoader)

    parser = argparse.ArgumentParser(description='Puppet Report Processor')
    parser.add_argument('logfile')
    parser.add_argument(
        '-v', dest='verbose', action='store_true', help='verbose')

    args = parser.parse_args()
    results = yaml.safe_load(open(args.logfile, 'r').read())
    if results.failed():
        print "FAILED", args.logfile
    else:
        print "SUCESS", args.logfile
    if args.verbose:
        print results

if __name__ == '__main__':
    main()
