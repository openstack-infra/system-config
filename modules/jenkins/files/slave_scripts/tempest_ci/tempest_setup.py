from neutronclient.neutron import client
from neutronclient.client import HTTPClient

USER='demo'
TENANT='demo'
PASSWD='contrail123'
EP_URL='http://127.0.0.1:9696'
AUTH_URL='http://127.0.0.1:5000/v2.0'
NET_NAME='public_net'
TEMPEST_FILE='/opt/stack/tempest/etc/tempest.conf'


hc=HTTPClient(username=USER, tenant_name=TENANT, password=PASSWD, auth_url=AUTH_URL)
hc.authenticate()

cn=client.Client('2.0', endpoint_url=EP_URL, token=hc.auth_token)

cn.format = 'json'

network = {'name': NET_NAME}
networks = cn.list_networks(name=NET_NAME)
if not networks['networks']:
    cn.create_network({'network':network})
    networks = cn.list_networks(name=NET_NAME)
    network_id = networks['networks'][0]['id']
    subnet = {'cidr': '1.1.1.0/24', 'network_id': network_id, 'ip_version':4}
    cn.create_subnet({'subnet':subnet})

network_id = networks['networks'][0]['id']
network = {'router:external': True}
cn.update_network(network_id, {'network':network})

print network_id

import configparser
c = configparser.ConfigParser()
c.read(TEMPEST_FILE)
c['network']['public_network_id'] = network_id
with open(TEMPEST_FILE, 'w') as f:
    c.write(f)

