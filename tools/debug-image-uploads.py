import os
import sys

import shade

shade.simple_logging(http_debug=True)

filename = sys.argv[0]
image_name = 'manual-%s' % os.path.basename(filename)
if len(sys.argv) >= 2:
    cloud_name = sys.argv[1]
else:
    cloud_name = 'envvars'
if len(sys.argv) == 3:
    region_name = sys.argv[2]
else:
    region_name = None

cloud = shade.openstack_cloud(cloud=cloud_name)
cloud.create_image(image_name, filename=filename, wait=True)
cloud.delete_image(image_name)
