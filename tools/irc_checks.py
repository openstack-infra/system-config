#! /usr/bin/env python

# Copyright 2016 SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import yaml

def check_meetbot():

    errors = False

    config = yaml.load(open('hiera/common.yaml', 'r'))
    meetbot_channels = config['meetbot_channels']
    # IRC has a limit of 120 channels that we unfortunately hit with
    # gerritbot. If we try connect to more, it will not connect to
    # all. Avoid this situation.
    if len(meetbot_channels) > 120:
        print("ERROR: bots can only handle 120 channels but found %s."
              % len(gerrit_config))
        print("Sorry, we're at our limit and cannot add more for now.")
        print("If you want to help set up another instance contact the "
              "infra team in #openstack-infra.\n")
        errors = True

    return errors

def main():
    errors = check_meetbot()

    if errors:
        print("Found errors in channel configuration!")
    else:
        print("No errors found in channel configuration!")
    return errors

if __name__ == "__main__":
    sys.exit(main())
