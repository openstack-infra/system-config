# Copyright (c) 2018 Red Hat, Inc.
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
# See the License for the specific language governing permissions and
# limitations under the License.

import subprocess


class FilterModule(object):

    def dns(self, value, family):
        ret = set()
        if family == '4':
            match = 'has address'
        elif family == '6':
            match = 'has IPv6 address'
        try:
            # Note we use 'host' rather than something like
            # getaddrinfo so we actually query DNS and don't get any
            # local-only results from /etc/hosts
            output = subprocess.check_output(
                ['/usr/bin/host', value], universal_newlines=True)
            for line in output.split('\n'):
                if match in line:
                    address = line.split()[-1]
                    ret.add(address)
        except Exception as e:
            return ret
        return sorted(ret)

    def dns_a(self, value):
        return self.dns(value, '4')

    def dns_aaaa(self, value):
        return self.dns(value, '6')

    def filters(self):
        return {
            'dns_a': self.dns_a,
            'dns_aaaa': self.dns_aaaa,
        }
