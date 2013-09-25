#!/bin/sh

# Integrated projects
python email-stats.py -p openstack/nova -o out/nova.csv
python email-stats.py -p openstack/swift -o out/swift.csv
python email-stats.py -p openstack/glance -o out/glance.csv
python email-stats.py -p openstack/keystone -o out/keystone.csv
python email-stats.py -p openstack/horizon -o out/horizon.csv
python email-stats.py -p openstack/neutron -o out/neutron.csv
python email-stats.py -p openstack/cinder -o out/cinder.csv
python email-stats.py -p openstack/ceilometer -o out/ceilometer.csv
python email-stats.py -p openstack/heat -o out/heat.csv

# Library projects
python email-stats.py -p openstack/oslo-incubator -o out/olso-incubator.csv
python email-stats.py -p openstack/oslo.config -o out/olso.config.csv
python email-stats.py -p openstack/python-novaclient -o out/python-novaclient.csv
python email-stats.py -p openstack/python-swiftclient -o out/python-swiftclient.csv
python email-stats.py -p openstack/python-glanceclient -o out/python-glanceclient.csv
python email-stats.py -p openstack/python-keystoneclient -o out/python-keystoneclient.csv
python email-stats.py -p openstack/python-neutronclient -o out/python-neutronclient.csv
python email-stats.py -p openstack/python-cinderclient -o out/python-cinderclient.csv
python email-stats.py -p openstack/python-ceilometerclient -o out/python-ceilometerclient.csv
python email-stats.py -p openstack/python-heatclient -o out/python-heatclient.csv
python email-stats.py -p openstack/heat-cfntools -o out/heat-cfntools.csv
python email-stats.py -p openstack/heat-templates -o out/heat-templates.csv

# Incubated projects
python email-stats.py -p openstack/trove -o out/trove.csv
python email-stats.py -p openstack/trove-integration -o out/trove-integration.csv
python email-stats.py -p openstack/python-troveclient -o out/python-troveclient.csv
python email-stats.py -p openstack/ironic -o out/ironic.csv
python email-stats.py -p openstack/python-ironicclient -o out/python-ironicclient.csv

# Gating projects
python email-stats.py -p openstack-dev/devstack -o out/devstack.csv
python email-stats.py -p openstack-dev/grenade -o out/grenade.csv
python email-stats.py -p openstack-dev/hacking -o out/hacking.csv
python email-stats.py -p openstack-dev/pbr -o out/pbr.csv
python email-stats.py -p openstack/tempest -o out/tempest.csv
python email-stats.py -p openstack-dev/openstack-nose -o out/openstack-nose.csv
python email-stats.py -p openstack/requirements -o out/requirements.csv

# Supporting projects
python email-stats.py -p openstack/compute-api -o out/compute-api.csv
python email-stats.py -p openstack/identity-api -o out/identity-api.csv
python email-stats.py -p openstack/image-api -o out/image-api.csv
python email-stats.py -p openstack/netconn-api -o out/netconn-api.csv
python email-stats.py -p openstack/object-api -o out/object-api.csv
python email-stats.py -p openstack/volume-api -o out/volume-api.csv
python email-stats.py -p openstack/openstack-manuals -o out/openstack-manuals.csv
python email-stats.py -p openstack/api-site -o out/api-site.csv
python email-stats.py -p openstack/operations-guide -o out/operations-guide.csv

# Infrastructure projects
python email-stats.py -p openstack-infra/askbot-theme -o out/askbot-theme.csv
python email-stats.py -p openstack-infra/config -o out/config.csv
python email-stats.py -p openstack-infra/devstack-gate -o out/devstack-gate.csv
python email-stats.py -p openstack-infra/gear -o out/gear.csv
python email-stats.py -p openstack-infra/gearman-plugin -o out/gearman-plugin.csv
python email-stats.py -p openstack-infra/gerrit -o out/gerrit.csv
python email-stats.py -p openstack-infra/gerritbot -o out/gerritbot.csv
python email-stats.py -p openstack-infra/gerritlib -o out/gerritlib.csv
python email-stats.py -p openstack-infra/git-review -o out/git-review.csv
python email-stats.py -p openstack-infra/gitdm -o out/gitdm.csv
python email-stats.py -p openstack-infra/jeepyb -o out/jeepyb.csv
python email-stats.py -p openstack-infra/jenkins-job-builder -o out/jenkins-job-builder.csv
python email-stats.py -p openstack-infra/lodgeit -o out/lodgeit.csv
python email-stats.py -p openstack-infra/meetbot -o out/meetbot.csv
python email-stats.py -p openstack-infra/nose-html-output -o out/nose-html-output.csv
python email-stats.py -p openstack-infra/odsreg -o out/odsreg.csv
python email-stats.py -p openstack-infra/publications -o out/publications.csv
python email-stats.py -p openstack-infra/puppet-apparmor -o out/puppet-apparmor.csv
python email-stats.py -p openstack-infra/puppet-dashboard -o out/puppet-dashboard.csv
python email-stats.py -p openstack-infra/puppet-vcsrepo -o out/puppet-vcsrepo.csv
python email-stats.py -p openstack-infra/pypi-mirror -o out/pypi-mirror.csv
python email-stats.py -p openstack-infra/releasestatus -o out/releasestatus.csv
python email-stats.py -p openstack-infra/reviewday -o out/reviewday.csv
python email-stats.py -p openstack-infra/statusbot -o out/statusbot.csv
python email-stats.py -p openstack-infra/zmq-event-publisher -o out/zmq-event-publisher.csv
python email-stats.py -p openstack-infra/zuul -o out/zuul.csv
