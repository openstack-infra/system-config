#!/usr/bin/env python3

# Copyright 2018 Red Hat.
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

#
# Cleanup RAX uploads
#
# This cleans up any leaked (non-current) images, along with a variety
# of object-storage files that are required for upload into RAX
#
# Run this from a python3 virtualenv with shade installed
#

import argparse
import concurrent.futures
import sys
import shade
import munch
import requests
import time

CLOUD='openstackjenkins-rax'
OWNER='637776' # is there a better api call for this?

#shade.simple_logging(debug=True)

parser = argparse.ArgumentParser()
parser.add_argument("region", choices=['dfw','iad','ord'])
args = parser.parse_args()

#
# Cleanup any leaked, non-current images
#

dib_region = "rax-%s" % args.region

r = requests.get("http://nl01.openstack.org/image-list")

current_images = []
current_names = []
for image in r.json():
    if image['state'] == 'ready' and image['provider'] == dib_region:
        print("Ignoring current image: %s" % image['external_name'])
        current_images.append(image['external_id'])
        current_names.append(image['external_name'])

cloud = shade.openstack_cloud(cloud='openstackjenkins-rax',
                              region_name=args.region.upper())

cloud_images = cloud.list_images()

to_delete = []
for image in cloud_images:
    if (image.id not in current_images) and (image.owner == OWNER):
        print("Scheduling %s -- %s -- (%s) for deletion" %
              (image.name, image.id, image.created_at))
        to_delete.append(image)

print("Deleting %s images" % len(to_delete))


#
# Cleanup extra object storage stuff
#


count = 1
for image in to_delete:
    print("Deleting %s (%d/%d)" % (image.id, count, len(to_delete)))
    # Specify this as a Munch to avoid listing constantly; see
    # https://review.openstack.org/#/c/561078/
    cloud.delete_image(munch.Munch(id=image.id), wait=False)
    # This is supposed to be linked into metadata and removed
    # automatically, but doesn't seem to be happening ATM.  Remove
    # manually.
    if cloud.delete_object('images', image.name):
        print(" ... deleted image objects")
    else:
        print(" ... did not delete image objects")
    if cloud.delete_object('images_segments', image.name):
        print(" ... deleted image segment objects")
    else:
        print(" ... did not delete images_segments " \
              "objects (%s/%s)" % ('images_segments', image.name))
    count = count + 1
    time.sleep(0.25)

# extra cleanup of images/segments
for extra_objects in ['images', 'images_segments']:
    finished = False
    while not finished:
        count = 1
        objects = cloud.list_objects(extra_objects)
        # There's a hard limit of 10,000 objects returned here.  loop
        # until we get less than that.  Pro tip: don't leak more than
        # 10,000 objects
        if len(objects) < 10000:
            finished = True

        def del_object(container, name):
            return cloud.delete_object(container, name)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = {}
            for obj in objects:
                # Avoid current images
                #  eg: opensuse-423-1507315914/000003
                # We probably don't need to do this, as once images are in
                # glance we can remove them
                for keep in current_names:
                    if obj['name'].startswith(keep):
                        print("Skipping current obj %s" % obj)
                        count = count + 1
                        continue
                # Work on the assumption we're going to remove the parent
                # which removes everything, to speed things up.
                #
                # -- We seem to have leaked a lot here?;
                #    don't skip this for now --
                #
                #if '/' in obj['name']:
                #    print("Skipping child %s" % obj['name'])
                #    count = count + 1
                #    continue

                key = executor.submit(del_object, extra_objects, obj['name'])
                futures.update({key: '%s/%s' % (extra_objects, obj['name'])})

            for future in concurrent.futures.as_completed(futures):
                name = futures[future]
                print("Removing: %s (%d / %d%s) %s" %
                      (name, count, len(objects),
                       '' if finished else '...',
                      "ok" if future.result() else "failed"))
                count = count + 1
