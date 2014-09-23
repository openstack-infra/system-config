Using diskimage-builder to build devstack-gate nodes
====================================================

In addition to being able to just download and consume images that are the
same as what run devstack-gate, it's easy to make your own for local dev or
testing - or just for fun.

Install diskimage-builder
-------------------------

Install the dependencies:

::

  sudo apt-get install kpartx qemu-utils curl python-yaml

Install diskimage-builder:

::

  sudo pip install diskimage-builder


Build an image
--------------

Building an image is simple, we have a script!

::

  DISTRO="ubuntu" bash tools/build-image.sh

See the script for environment variables to set distribution, etc.
You should be left with a .qcow2 image file of your selected
distribution.

It is a good idea to set ``TMP_DIR`` to somewhere with plenty of space
to avoid the disappointment of a full-disk mid-way through the script
run.

Mounting the image
------------------

If you would like to examine the contents of the image, you can mount it on
a loopback device using qemu-nbd.

::

  sudo apt-get install qemu-utils
  sudo modprobe nbd max_part=16
  sudo mkdir -p /tmp/newimage
  sudo qemu-nbd -c /dev/nbd1 devstack-gate-precise.qcow2
  sudo mount /dev/nbd1 /tmp/newimage

Other things
------------

It's a qcow2 image, so you can do tons of things with it. You can upload it
to glance, you can boot it using kvm, and you can even copy it to a cloud
server, replace the contents of the server with it and kexec the new kernel.
