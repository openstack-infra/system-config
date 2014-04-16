#!/usr/bin/python
#
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

import ansible.runner
import yaml


def has_failure(results):
    if len(results['dark'].keys()) > 0:
        return True
    for (hostname, result) in results['contacted']:
        if result['rc'] == 124:
            return True
        elif result['rc'] != 0:
            return True
    return False


def run_puppet(where, what):
    return ansible.runner.Runner(
        pattern=where, forks=10,
        module_name='command',
        module_args=what,
    ).run()


def main():
    config = yaml.load(open('/etc/puppet/remote_puppet.yaml', 'r'))
    remote_command = config['remote_command']
    targets = config['targets']
    all_results = []
    for target in targets:
        results = run_puppet(target, remote_command)
        all_results.append(results)
        if has_failure(results):
            break

    the_rest = ':!'.join(['*'] + targets)
    all_results.append(run_puppet(the_rest, remote_command))

if __name__ == '__main__':
    main()
