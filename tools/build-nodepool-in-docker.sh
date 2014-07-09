docker.io run -v /home/mordred/.cache:/.cache -v $(pwd):/config -w /config/modules/openstack_project/files/nodepool/scripts -i -t diskimage-builder /bin/bash prepare_node_devstack.sh
