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
#
# Class: project_config
#

class project_config(
  $url = '',
  $base = '',
) {

  if (!defined(Vcsrepo['/etc/project-config'])) {
    vcsrepo { '/etc/project-config':
      ensure   => latest,
      provider => git,
      revision => 'master',
      source   => $url,
    }
  }

  $accessbot_channels_yaml        = "/etc/project-config/${base}accessbot/channels.yaml"
  $gerrit_acls_dir                = "/etc/project-config/${base}gerrit/acls"
  $gerrit_notify_impact_file      = "/etc/project-config/${base}gerrit/notify_impact.yaml"
  $jeepyb_project_file            = "/etc/project-config/${base}gerrit/projects.yaml"
  $jenkins_job_builder_config_dir = "/etc/project-config/${base}jenkins/jobs"
  $jenkins_scripts_dir            = "/etc/project-config/${base}jenkins/scripts"
  $nodepool_scripts_dir           = "/etc/project-config/${base}nodepool/scripts"
  $nodepool_elements_dir          = "/etc/project-config/${base}nodepool/elements"
  $zuul_layout_dir                = "/etc/project-config/${base}zuul"
}
