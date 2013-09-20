#!/usr/bin/env python
# Copyright 2012 Hewlett-Packard Development Company, L.P.
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
# Must happen before django imports
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "graphite.settings")

import sys
import ConfigParser

from django.core import management
from django.contrib.auth import models as auth_models

config = ConfigParser.ConfigParser()
config.read(os.path.expanduser(sys.argv[1]))

USER = config.get('admin', 'user')
EMAIL = config.get('admin', 'email')
PASS = config.get('admin', 'password')

management.call_command('syncdb', interactive=False)

try:
    auth_models.User.objects.get(username=USER)
    print 'Admin user already exists.'
except auth_models.User.DoesNotExist:
    print 'Creating admin user'
    auth_models.User.objects.create_superuser(USER, EMAIL, PASS)
