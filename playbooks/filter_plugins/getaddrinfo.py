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

import socket


class FilterModule(object):

    def dns(self, value, family):
        ret = set()
        try:
            addr_info = socket.getaddrinfo(value, None, family)
        except socket.gaierror:
            return ret
        for addr in addr_info:
            ret.add(addr[4][0])
        return sorted(ret)

    def dns_a(self, value):
        return self.dns(value, socket.AF_INET)

    def dns_aaaa(self, value):
        return self.dns(value, socket.AF_INET6)

    def filters(self):
        return {
            'dns_a': self.dns_a,
            'dns_aaaa': self.dns_aaaa,
        }
