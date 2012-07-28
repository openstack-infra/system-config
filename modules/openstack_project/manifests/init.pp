class openstack_project {

  $jenkins_ssh_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson'

  $sysadmins = [
    'corvus@inaugust.com',
    'mordred@inaugust.com',
    'andrew@linuxjedi.co.uk',
    'devananda.vdv@gmail.com',
    'clark.boylan@gmail.com'
    ]

  $project_list = [
     'openstack/keystone',
     'openstack/glance',
     'openstack/swift',
     'openstack/nova',
     'openstack/horizon',
     'openstack/quantum',
     'openstack/melange',
     'openstack/tempest',
     'openstack/openstack-ci',
     'openstack/openstack-ci-puppet',
     'openstack/openstack-puppet',
     'openstack/openstack-chef',
     'openstack/openstack-manuals',
     'openstack/compute-api',
     'openstack/image-api',
     'openstack/identity-api',
     'openstack/object-api',
     'openstack/netconn-api',
     'openstack-dev/devstack',
     'openstack-dev/openstack-qa',
     'openstack-dev/pbr',
     'openstack/python-novaclient',
     'openstack/python-glanceclient',
     'openstack-ci/git-review',
     'openstack-ci/lodgeit',
     'openstack-ci/meetbot',
     'openstack-ci/zuul',
     'openstack-ci/pypi-mirror',
     'openstack/openstack-common',
     'openstack/cinder',
     'openstack/python-openstackclient',
     'openstack-dev/openstack-nose',
     'openstack/python-cinderclient',
     'openstack/python-swiftclient',
     'stackforge/MRaaS',
     'stackforge/reddwarf',
     'stackforge/ceilometer',
     'heat-api/heat',
  ]
}
