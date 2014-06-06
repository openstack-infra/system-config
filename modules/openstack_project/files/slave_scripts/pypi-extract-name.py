#!/usr/bin/python
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
#
# Extract Python package name from setup.cfg

import ConfigParser
import sys

import wheel.bdist_wheel

setup_cfg = ConfigParser.SafeConfigParser()
setup_cfg.read("setup.cfg")
distname = setup_cfg.get("metadata", "name")
assert distname
if not len(sys.argv) or sys.argv[1] == "--tarball":
    print(distname)
elif sys.argv[1] == "--wheel":
    print(wheel.bdist_wheel.safer_name(distname))
else:
    sys.stderr.write("ERROR: Valid options are --tarball and --wheel")
    sys.exit(1)
