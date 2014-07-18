# Copyright 2013 OpenStack Foundation
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

import re


def set_log_url(item, job, params):
    if hasattr(item.change, 'refspec'):
        path = "%s/%s/%s/%s" % (
            params['ZUUL_CHANGE'][-2:], params['ZUUL_CHANGE'],
            params['ZUUL_PATCHSET'], params['ZUUL_PIPELINE'])
    elif hasattr(item.change, 'ref'):
        path = "%s/%s/%s" % (
            params['ZUUL_NEWREV'][:2], params['ZUUL_NEWREV'],
            params['ZUUL_PIPELINE'])
    else:
        path = params['ZUUL_PIPELINE']
    params['BASE_LOG_PATH'] = path
    params['LOG_PATH'] = path + '/%s/%s' % (job.name,
                                            params['ZUUL_UUID'][:7])


def reusable_node(item, job, params):
    if 'OFFLINE_NODE_WHEN_COMPLETE' in params:
        del params['OFFLINE_NODE_WHEN_COMPLETE']


def devstack_params(item, job, params):
    change = item.change
    # Note we can't fallback on the default labels because
    # jenkins uses 'devstack-precise || devstack-trusty'.
    # This is necessary to get the gearman plugin to register
    # gearman jobs with both node labels.
    if ((hasattr(change, 'branch') and
        (change.branch == 'stable/havana' or
        change.branch == 'stable/icehouse')) or
        ('havana' in job.name or
        'icehouse' in job.name or
        'precise' in job.name)):
        params['ZUUL_NODE'] = 'devstack-precise'
    elif 'aiopcpu' in job.name:
        params['ZUUL_NODE'] = 'devstack-trusty-2-node'
    else:
        params['ZUUL_NODE'] = 'devstack-trusty'


def default_params_precise(item, job, params):
    if 'trusty' in job.name:
        params['ZUUL_NODE'] = 'bare-trusty'
    else:
        params['ZUUL_NODE'] = 'bare-precise'


def default_params_trusty(item, job, params):
    change = item.change
    # Note we can't fallback on the default labels because
    # jenkins uses 'bare-precise || bare-trusty'.
    # This is necessary to get the gearman plugin to register
    # gearman jobs with both node labels.
    if ((hasattr(change, 'branch') and
        (change.branch == 'stable/havana' or
        change.branch == 'stable/icehouse')) or
        ('havana' in job.name or
        'icehouse' in job.name or
        'precise' in job.name)):
        params['ZUUL_NODE'] = 'bare-precise'
    else:
        params['ZUUL_NODE'] = 'bare-trusty'


def set_node_options(item, job, params, default):
    # Set up log url paramter for all jobs
    set_log_url(item, job, params)
    # Default to single use node. Potentially overriden below.
    # Select node to run job on.
    params['OFFLINE_NODE_WHEN_COMPLETE'] = '1'
    proposal_re = r'^.*(merge-release-tags|(propose|upstream)-(requirements|translation)-updates?)$'  # noqa
    pypi_re = r'^.*-(jenkinsci|mavencentral|pypi-(both|wheel))-upload$'
    python26_re = r'^.*-py(thon)?26.*$'
    centos6_re = r'^.*-centos6.*$'
    f20_re = r'^.*-f20.*$'
    python33_re = r'^.*-py(py|(thon)?33).*$'
    tripleo_re = r'^.*-tripleo.*$'
    devstack_re = r'^.*-dsvm.*$'
    # jobs run on the proposal worker
    if re.match(proposal_re, job.name) or re.match(pypi_re, job.name):
        reusable_node(item, job, params)
    # Jobs needing python26
    elif re.match(python26_re, job.name):
        # Pass because job specified label is always correct.
        pass
    # Jobs needing centos6
    elif re.match(centos6_re, job.name):
        # Pass because job specified label is always correct.
        pass
    # Jobs needing fedora 20
    elif re.match(f20_re, job.name):
        # Pass because job specified label is always correct.
        pass
    # Jobs needing py33/pypy slaves
    elif re.match(python33_re, job.name):
        # Pass because job specified label is always correct.
        pass
    # Jobs needing tripleo slaves
    elif re.match(tripleo_re, job.name):
        # Pass because job specified label is always correct.
        pass
    # Jobs needing devstack slaves
    elif re.match(devstack_re, job.name):
        devstack_params(item, job, params)
    elif default == 'trusty':
        default_params_trusty(item, job, params)
    else:
        default_params_precise(item, job, params)


def set_node_options_default_precise(item, job, params):
    set_node_options(item, job, params, 'precise')


def set_node_options_default_trusty(item, job, params):
    set_node_options(item, job, params, 'trusty')
