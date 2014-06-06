# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: storyboard::rabbit
#
# The StoryBoard Rabbit manifest installs a standalone rabbitmq instance
# which is used to handle deferred processing and reporting tasks for
# StoryBoard.
#
class storyboard::rabbit (
  $rabbitmq_user          = 'storyboard',
  $rabbitmq_user_password = 'changeme'
) {

  class { 'rabbitmq':
    service_manage    => true,
    delete_guest_user => true
  }

  rabbitmq_user { $rabbitmq_user:
    admin    => true,
    password => $rabbitmq_user_password
  }

  rabbitmq_user_permissions { "${rabbitmq_user}@/":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => Rabbitmq_user[$rabbitmq_user]
  }
}
