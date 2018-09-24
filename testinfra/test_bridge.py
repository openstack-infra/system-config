# Copyright 2018 Red Hat, Inc.
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


testinfra_hosts = ['bridge.openstack.org']


def test_clouds_yaml(host):
    clouds_yaml = host.file('/etc/openstack/clouds.yaml')
    assert clouds_yaml.exists

    assert b'password' in clouds_yaml.content

    all_clouds_yaml = host.file('/etc/openstack/all-clouds.yaml')
    assert all_clouds_yaml.exists

    assert b'password' in all_clouds_yaml.content


def test_openstacksdk_config(host):
    f = host.file('/etc/openstack')
    assert f.exists
    assert f.is_directory
    assert f.user == 'root'
    assert f.group == 'root'
    assert f.mode == 0o750
    del f

    f = host.file('/etc/openstack/limestone_cacert.pem')
    assert f.exists
    assert f.is_file
    assert f.user == 'root'
    assert f.group == 'root'
    assert f.mode == 0o640


def test_cloud_launcher_cron(host):
    with host.sudo():
        crontab = host.check_output('crontab -l')
        assert 'run_cloud_launcher.sh' in crontab


def test_root_authorized_keys(host):
    authorized_keys = host.file('/root/.ssh/authorized_keys')
    assert authorized_keys.exists

    content = authorized_keys.content.decode('utf8')
    lines = content.split('\n')
    assert len(lines) >= 2


def test_ara(host):
    ara = host.run('ara playbook list')
    assert ara.rc == 0
    database = host.file('/var/cache/ansible/ara.sqlite')
    assert database.exists


def test_kube_config(host):
    kubeconfig = host.file('/root/.kube/config')
    assert kubeconfig.exists

    assert b'Z2l0ZWFfazhzX2tleQ==' in kubeconfig.content


def test_kubectl(host):
    kube = host.run('kubectl help')
    assert kube.rc == 0


def test_zuulcd_authorized_keys(host):
    authorized_keys = host.file('/home/zuulcd/.ssh/authorized_keys')
    assert authorized_keys.exists

    content = authorized_keys.content.decode('utf8')
    lines = content.split('\n')
    # Remove empty lines
    keys = list(filter(None, lines))
    assert len(keys) >= 2
    for key in keys:
        assert 'ssh-rsa' in key
