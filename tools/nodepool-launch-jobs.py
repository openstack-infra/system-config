# Copyright (c) 2016 IBM Corp.
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

import sys
import os
import time
import multiprocessing
import logging
from nodepool import nodedb

import paramiko

dburi = 'mysql+pymysql://nodepool@localhost/nodepool'

#label, job
job_labels = {
    'devstack-trusty': [
#        'gate-grenade-dsvm',
        'gate-tempest-dsvm-full',
#        'gate-tempest-dsvm-multinode-full',
#        'gate-tempest-dsvm-neutron-full',
    ],
#    'devstack-trusty-2-node': [
#        'gate-tempest-dsvm-multinode-full',
#        'gate-tempest-dsvm-neutron-multinode-full',
#    ],
}

class SSHClient(object):
    def __init__(self, ip, username, password=None, pkey=None,
                 key_filename=None, out=None, err=None):
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.WarningPolicy())
        client.connect(ip, username=username, password=password, pkey=pkey,
                       key_filename=key_filename)
        self.client = client
        self.out = out
        self.err = err

    def ssh(self, command, get_pty=True):
        stdin, stdout, stderr = self.client.exec_command(
            command, get_pty=get_pty)
        channel = stdout.channel
        while not channel.exit_status_ready():
            while channel.recv_ready():
                self.out.write(channel.recv(1))
            while channel.recv_stderr_ready():
                self.err.write(channel.recv_stderr(1))
            self.out.flush()
            self.err.flush()
            time.sleep(1)
        while channel.recv_ready():
            self.out.write(channel.recv(1))
        while channel.recv_stderr_ready():
            self.err.write(channel.recv_stderr(1))
        self.out.flush()
        self.err.flush()
        ret = channel.recv_exit_status()
        if ret:
            raise Exception("Unable to run command: %s" % command)

    def scp(self, source, dest):
        ftp = self.client.open_sftp()
        ftp.put(source, dest)
        ftp.close()

class Job(object):
    def __init__(self, node_id, ip, job):
        self.node_id = node_id
        self.ip = ip
        self.job = job
        self.queue = multiprocessing.Queue()

    def run(self):
        print "run %s on node %s" % (self.job, self.node_id)

        outf = open(os.path.join('out', self.job, str(self.node_id)), 'w')
        client = SSHClient(self.ip, 'jenkins', key_filename='PATH TO id_rsa', out=outf, err=outf)
        client.scp(os.path.join('payloads', self.job),
                   '/tmp/run.sh')
        client.ssh('chmod a+x /tmp/run.sh')

        start = time.time()
        client.ssh("/tmp/run.sh")
        end = time.time()
        result = 1
        self.queue.put((start, end, result))

def run():
    allocation = []
    db = nodedb.NodeDatabase(dburi)
    with db.getSession() as session:
        for label, jobs in job_labels.items():
            nodes = session.getNodes(state=nodedb.READY, label_name=label)
            #nodes = nodes[:1] # HERE: uncomment to run only on one node
            while nodes:
                for job in jobs:
                    if not nodes: continue
                    node = nodes.pop()
                    node.state = nodedb.USED # HERE: comment to avoid marking nodes as used
                    allocation.append((node.id, node.ip, job))

    processes = []
    jobs = []
    for a in allocation:
        job = Job(*a)
        jobs.append(job)
        p = multiprocessing.Process(target=job.run)
        processes.append(p)
        p.start()

    while processes:
        print "waiting on %s processes" % len(processes)
        for p in processes[:]:
            if not p.is_alive():
                r = p.join()
                processes.remove(p)
        time.sleep(1)

    durations = {}
    success = {}
    failure = {}
    for job in jobs:
        if job.queue.empty():
            continue
        (start, end, result) = job.queue.get()
        name = job.job
        durations.setdefault(name, []).append(end-start)
        if result == 0:
            success.setdefault(name, []).append(1)
        else:
            failure.setdefault(name, []).append(1)

    for label, jobs in job_labels.items():
        for job in jobs:
            if job not in durations:
                continue
            print job,
            print sum(durations[job])/len(durations[job]),
            print len(success.get(job, [])),
            print len(failure.get(job, []))

#logging.basicConfig(level=logging.DEBUG)
run()

# here is a sample payload file:
"""

#!/bin/bash -xe

exec 0</dev/null

cat /etc/nodepool/provider
date

sudo apt-get update
sudo apt-get -y install python-yaml screen openvswitch-switch
#while /bin/true; do echo "hi"; sleep 1; done
#exit 0

mkdir workspace
cd workspace
export WORKSPACE=/home/jenkins/workspace

#https://jenkins04.openstack.org/job/gate-tempest-dsvm-full/7317/parameters/
#http://logs.openstack.org/42/234542/2/gate/gate-tempest-dsvm-full/0de544e//
export ZUUL_REF=refs/zuul/master/Z75089d19010b404c9fa5f09d04bbad23
export ZUUL_COMMIT=2ff6ef471ca469228afcfe171b2dd663a6c3ecb6
export ZUUL_URL=http://zm06.openstack.org/p
export ZUUL_PROJECT=openstack-dev/devstack
export ZUUL_BRANCH=master

cat > clonemap.yaml << EOF
clonemap:
  - name: openstack-infra/devstack-gate
    dest: devstack-gate
EOF

/usr/zuul-env/bin/zuul-cloner -m clonemap.yaml --cache-dir /opt/git git://git.openstack.org openstack-infra/devstack-gate

export PYTHONUNBUFFERED=true
export DEVSTACK_GATE_TIMEOUT=120
export DEVSTACK_GATE_TEMPEST=1
export DEVSTACK_GATE_TEMPEST_FULL=1
export BRANCH_OVERRIDE=default
export DEVSTACK_LOCAL_CONFIG="LIBVIRT_TYPE=qemu"
cp devstack-gate/devstack-vm-gate-wrap.sh ./safe-devstack-vm-gate-wrap.sh
./safe-devstack-vm-gate-wrap.sh
df -h

"""
