#!/usr/bin/env python
#
# Test all of the Jenkins API features used by the
# OpenStack Infrastructure project
#
# Copyright (C) 2013 OpenStack Foundation
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
#
# See the License for the specific language governing permissions and
# limitations under the License.

import urllib2
import urlparse
from pprint import pprint
import time
from uuid import uuid4
import ConfigParser
import os
import re

import sys
sys.path.insert(0, '../../zuul/zuul')
from launcher.jenkins import ExtendedJenkins

sys.path.insert(0, '../../devstack-gate/')
from myjenkins import Jenkins as DGJenkins

JOB_NAME = 'test-job'
NODE_NAME = 'test-node'


class JenkinsTest(object):
    def __init__(self):
        self.config = ConfigParser.ConfigParser()
        if len(sys.argv) < 2:
            print "Usage: %s zuul.conf" % sys.argv[0]
            sys.exit(1)
        fp = sys.argv[1]
        if os.path.exists(os.path.expanduser(fp)):
            self.config.read(os.path.expanduser(fp))

        server = self.config.get('jenkins', 'server')
        user = self.config.get('jenkins', 'user')
        apikey = self.config.get('jenkins', 'apikey')

        self.jenkins = ExtendedJenkins(server, user, apikey)
        self.dgjenkins = DGJenkins(server, user, apikey)

    def nodeExists(self):
        return self.dgjenkins.node_exists(NODE_NAME)

    def createNode(self):
        assert not self.nodeExists()
        priv_key = '/var/lib/jenkins/.ssh/id_rsa'
        self.dgjenkins.create_node(
            NODE_NAME, numExecutors=1,
            nodeDescription='Test node',
            remoteFS='/home/jenkins',
            labels='testnode',
            exclusive=True,
            launcher='hudson.plugins.sshslaves.SSHLauncher',
            launcher_params={'port': 22,
                             'username': 'jenkins',
                             'privatekey': priv_key,
                             'host': 'nowhere.example.com'})
        assert self.nodeExists()

    def reconfigNode(self):
        LABEL_RE = re.compile(r'<label>.*</label>')
        config = self.dgjenkins.get_node_config(NODE_NAME)
        assert '<label>testnode</label>' in config
        config = LABEL_RE.sub('<label>devstack-used</label>', config)
        self.dgjenkins.reconfig_node(NODE_NAME, config)
        config = self.dgjenkins.get_node_config(NODE_NAME)
        assert '<label>devstack-used</label>' in config

    def deleteNode(self):
        assert self.nodeExists()
        self.dgjenkins.delete_node(NODE_NAME)
        assert not self.nodeExists()

    def findBuildInQueue(self, build):
        for item in self.jenkins.get_queue_info():
            if 'actions' not in item:
                continue
            for action in item['actions']:
                if 'parameters' not in action:
                    continue
                parameters = action['parameters']
                for param in parameters:
                    # UUID is deprecated in favor of ZUUL_UUID
                    if ((param['name'] in ['ZUUL_UUID', 'UUID'])
                        and build == param['value']):
                        return item
        return False

    def addJob(self, quiet_period):
        assert not self.jobExists()
        xml = open('jenkins-job.xml').read()
        xml = xml % quiet_period

        self.jenkins.create_job(JOB_NAME, xml)
        assert self.jobExists()

    def reconfigJob(self, quiet_period):
        assert self.jobExists()
        xml = open('jenkins-job.xml').read()
        xml = xml % quiet_period

        self.jenkins.reconfig_job(JOB_NAME, xml)
        xml2 = self.jenkins.get_job_config(JOB_NAME)
        s = '<quietPeriod>%s</quietPeriod>' % quiet_period
        assert s in xml2

    def jobExists(self):
        return self.jenkins.job_exists(JOB_NAME)

    def deleteJob(self):
        assert self.jobExists()
        self.jenkins.delete_job(JOB_NAME)
        assert not self.jobExists()

    def getJobs(self):
        pprint(self.jenkins.get_jobs())

    def testCancelQueue(self):
        uuid = str(uuid4().hex)
        self.jenkins.build_job(JOB_NAME, parameters=dict(UUID=uuid))

        item = self.findBuildInQueue(uuid)
        assert item
        self.jenkins.cancel_queue(item['id'])
        assert not self.findBuildInQueue(uuid)

    def testCancelBuild(self):
        uuid = str(uuid4().hex)
        self.jenkins.build_job(JOB_NAME, parameters=dict(UUID=uuid))

        assert self.findBuildInQueue(uuid)
        for x in range(60):
            if not self.findBuildInQueue(uuid):
                break
        assert not self.findBuildInQueue(uuid)
        time.sleep(1)

        buildno = self.jenkins.get_job_info(JOB_NAME)['lastBuild']['number']
        info = self.jenkins.get_build_info(JOB_NAME, buildno)
        assert info['building']
        self.jenkins.stop_build(JOB_NAME, buildno)
        time.sleep(1)
        info = self.jenkins.get_build_info(JOB_NAME, buildno)
        assert not info['building']

        console_url = urlparse.urljoin(info['url'], 'consoleFull')
        self.jenkins.jenkins_open(urllib2.Request(console_url))

        self.jenkins.set_build_description(JOB_NAME, buildno,
                                           "test description")

        info = self.jenkins.get_build_info(JOB_NAME, buildno)
        assert info['description'] == 'test description'

j = JenkinsTest()
if j.nodeExists():
    j.deleteNode()
j.createNode()
j.reconfigNode()
j.deleteNode()
if j.jobExists():
    j.deleteJob()
j.addJob(5)
j.reconfigJob(10)
j.testCancelQueue()
j.testCancelBuild()
j.deleteJob()
