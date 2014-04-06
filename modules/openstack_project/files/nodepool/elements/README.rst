Using diskimage-builder to build devstack-gate nodes
====================================================

In addition to being able to just download and consume images that are the
same as what run devstack-gate, it's easy to make your own for local dev or
testing - or just for fun.

Install diskimage-builder
-------------------------

Install the dependencies:

::

  sudo apt-get install kpartx qemu-utils

Install diskimage-builder:

::

  sudo pip install diskimage-builder


Build an image
--------------

Building an image is simple, we have a script!

::

  bash scripts/build-image.sh

You should be left with a file called devstack-gate-precise.qcow2.

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
