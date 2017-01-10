import shade
shade.simple_logging(debug=True)

c=shade.openstack_cloud(cloud='infracloud-vanilla')

for port in c.list_ports():
    if port['status'] == 'DOWN' and port['device_owner'] == 'compute:None':
        c.delete_port(port['id'])
