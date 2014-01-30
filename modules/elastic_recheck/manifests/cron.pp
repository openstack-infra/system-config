# Copyright 2013 Hewlett-Packard Development Company, L.P.
# Copyright 2014 Samsung Electronics
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
# Class to install and configure an instance of the elastic-recheck
# service.
#

class elastic_recheck::cron () {
  $er_state_path = $::elastic_recheck::recheck_state_dir
  $graph_all_cmd = $::elastic_recheck::graph_all_cmd
  $graph_gate_cmd = $::elastic_recheck::graph_gate_cmd
  $uncat_cmd = $::elastic_recheck::uncat_cmd

  cron { 'elastic-recheck-all':
    user        => 'recheck',
    minute      => '*/15',
    hour        => '*',
    command     => "cd ${er_state_path} && er_safe_run.sh ${graph_all_cmd}",
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin',
    require     => Class['elastic_recheck']
  }

  cron { 'elastic-recheck-gate':
    user        => 'recheck',
    minute      => '*/15',
    hour        => '*',
    command     => "sleep $((RANDOM\%60+90)) && cd ${er_state_path} && er_safe_run.sh ${graph_gate_cmd}",
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin',
    require     => Class['elastic_recheck']
  }


  cron { 'elastic-recheck-uncat':
    user        => 'recheck',
    minute      => '59',
    hour        => '*',
    command     => "cd ${er_state_path} && er_safe_run.sh ${uncat_cmd}",
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin',
    require     => Class['elastic_recheck']
  }
}
