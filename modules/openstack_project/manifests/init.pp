class openstack_project {

  $jenkins_ssh_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson'

  $sysadmin = [
    'corvus@inaugust.com',
    'mordred@inaugust.com',
    'andrew@linuxjedi.co.uk',
    'devananda.vdv@gmail.com',
    'clark.boylan@gmail.com'
    ]

  $project_list = [
    'heat-api/heat',
    'openstack-ci/git-review',
    'openstack-ci/lodgeit',
    'openstack-ci/meetbot',
    'openstack-ci/pypi-mirror',
    'openstack-ci/zuul',
    'openstack-dev/devstack',
    'openstack-dev/openstack-nose',
    'openstack-dev/openstack-qa',
    'openstack-dev/pbr',
    'openstack/cinder',
    'openstack/compute-api',
    'openstack/glance',
    'openstack/horizon',
    'openstack/identity-api',
    'openstack/image-api',
    'openstack/keystone',
    'openstack/melange',
    'openstack/netconn-api',
    'openstack/nova',
    'openstack/object-api',
    'openstack/openstack-chef',
    'openstack/openstack-ci',
    'openstack/openstack-ci-puppet',
    'openstack/openstack-common',
    'openstack/openstack-manuals',
    'openstack/openstack-puppet',
    'openstack/python-cinderclient',
    'openstack/python-glanceclient',
    'openstack/python-novaclient',
    'openstack/python-openstackclient',
    'openstack/python-swiftclient',
    'openstack/quantum',
    'openstack/swift',
    'openstack/tempest',
    'stackforge/MRaaS',
    'stackforge/ceilometer',
    'stackforge/reddwarf',
    ]
}
