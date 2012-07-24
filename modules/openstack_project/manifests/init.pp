class openstack_project {

  $jenkins_ssh_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtioTW2wh3mBRuj+R0Jyb/mLt5sjJ8dEvYyA8zfur1dnqEt5uQNLacW4fHBDFWJoLHfhdfbvray5wWMAcIuGEiAA2WEH23YzgIbyArCSI+z7gB3SET8zgff25ukXlN+1mBSrKWxIza+tB3NU62WbtO6hmelwvSkZ3d7SDfHxrc4zEpmHDuMhxALl8e1idqYzNA+1EhZpbcaf720mX+KD3oszmY2lqD1OkKMquRSD0USXPGlH3HK11MTeCArKRHMgTdIlVeqvYH0v0Wd1w/8mbXgHxfGzMYS1Ej0fzzJ0PC5z5rOqsMqY1X2aC1KlHIFLAeSf4Cx0JNlSpYSrlZ/RoiQ== hudson@hudson'

  $sysadmins = [
    'corvus@inaugust.com',
    'mordred@inaugust.com',
    'andrew@linuxjedi.co.uk',
    'devananda.vdv@gmail.com',
    'clark.boylan@gmail.com'
    ]

  $project_list = [ {
     name => 'openstack/keystone',
     close_pull => 'true'
     }, {
     name => 'openstack/glance',
     close_pull => 'true'
     }, {
     name => 'openstack/swift',
     close_pull => 'true'
     }, {
     name => 'openstack/nova',
     close_pull => 'true'
     }, {
     name => 'openstack/horizon',
     close_pull => 'true'
     }, {
     name => 'openstack/quantum',
     close_pull => 'true'
     }, {
     name => 'openstack/melange',
     close_pull => 'true'
     }, {
     name => 'openstack/tempest',
     close_pull => 'true'
     }, {
     name => 'openstack/openstack-ci',
     close_pull => 'true'
     }, {
     name => 'openstack/openstack-ci-puppet',
     close_pull => 'true'
     }, {
     name => 'openstack/openstack-puppet',
     close_pull => 'true'
     }, {
     name => 'openstack/openstack-chef',
     close_pull => 'true'
     }, {
     name => 'openstack/openstack-manuals',
     close_pull => 'true'
     }, {
     name => 'openstack/compute-api',
     close_pull => 'true'
     }, {
     name => 'openstack/image-api',
     close_pull => 'true'
     }, {
     name => 'openstack/identity-api',
     close_pull => 'true'
     }, {
     name => 'openstack/object-api',
     close_pull => 'true'
     }, {
     name => 'openstack/netconn-api',
     close_pull => 'true'
     }, {
     name => 'openstack-dev/devstack',
     close_pull => 'true'
     }, {
     name => 'openstack-dev/openstack-qa',
     close_pull => 'true'
     }, {
     name => 'openstack-dev/pbr',
     close_pull => 'true'
     }, {
     name => 'openstack/python-novaclient',
     close_pull => 'true'
     }, {
     name => 'openstack/python-glanceclient',
     close_pull => 'true'
     }, {
     name => 'openstack-ci/git-review',
     close_pull => 'true'
     }, {
     name => 'openstack-ci/lodgeit',
     close_pull => 'true'
     }, {
     name => 'openstack-ci/meetbot',
     close_pull => 'true'
     }, {
     name => 'openstack-ci/zuul',
     close_pull => 'true'
     }, {
     name => 'openstack-ci/pypi-mirror',
     close_pull => 'true'
     }, {
     name => 'openstack/openstack-common',
     close_pull => 'true'
     }, {
     name => 'openstack/cinder',
     close_pull => 'true'
     }, {
     name => 'openstack/python-openstackclient',
     close_pull => 'true'
     }, {
     name => 'openstack-dev/openstack-nose',
     close_pull => 'true'
     }, {
     name => 'openstack/python-cinderclient',
     close_pull => 'true'
     }, {
     name => 'openstack/python-swiftclient',
     close_pull => 'true'
     }, {
     name => 'stackforge/MRaaS',
     close_pull => 'true'
     }, {
     name => 'stackforge/reddwarf',
     close_pull => 'true'
     }, {
     name => 'stackforge/ceilometer',
     close_pull => 'true'
     }, {
     name => 'heat-api/heat',
     close_pull => 'true'
     }
  ]
}
