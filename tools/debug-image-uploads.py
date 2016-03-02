#!/usr/bin/python

# Copyright 2016 IBM Corp.
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

import os
import sys

import shade

shade.simple_logging(http_debug=True)

filename = sys.argv[0]
image_name = 'manual-%s' % os.path.basename(filename)
if len(sys.argv) >= 2:
    cloud_name = sys.argv[1]
else:
    cloud_name = 'envvars'
if len(sys.argv) == 3:
    region_name = sys.argv[2]
else:
    region_name = None

cloud = shade.openstack_cloud(cloud=cloud_name, region_name=region_name)
cloud.create_image(image_name, filename=filename, wait=True)
cloud.delete_image(image_name)
