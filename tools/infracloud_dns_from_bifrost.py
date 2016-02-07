#!/usr/bin/python

import yaml

f = open('hiera/group/infracloud.yaml')

bf = yaml.load(f.read())

for node in bf['ironic_inventory_hpuswest']:
    name = node
    ip = bf['ironic_inventory_hpuswest'][node]['ipv4_public_address']
    print "rackdns record-create --name {0} --type A".format(name),
    print "--data {0} --ttl 3600 openstack.org".format(ip)
