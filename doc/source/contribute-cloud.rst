:title: Contributing Cloud Test Resources

.. _contributing_cloud:

Contributing Cloud Test Resources
#################################

OpenStack utilizes a "project gating" system based on `Zuul
<http://docs.openstack.org/infra/zuul/>`_ to ensure that every change
proposed to any OpenStack project passes tests before being added to
its source code repository.  Each change may run several jobs which
test the change in various configurations, and each job may run
thousands of individual tests.  To ensure the overall security of the
system as well as isolation between unrelated changes, each job is run
on an OpenStack compute instance that is created specifically to run
that job and is destroyed and replaced immediately after completing
that task.

This system operates across multiple OpenStack clouds, making the
OpenStack project infrastructure itself a substantial and very public
cross-cloud OpenStack application.

The compute instances used by this system are generously donated by
organizations that are contributing to OpenStack, and the project is
very appreciative of this.

By visiting this page, you can see the system in action at any time:

  http://status.openstack.org/zuul/

You'll see every job that's running currently, as well as some graphs
that show activity over time.  Each of those jobs is running on its
own compute instance.  We create and destroy quite a number of those
each day (most compute instances last for about 1 hour).

Having resources from more providers will help us continue to grow the
project and deliver test results to developers quickly.  OpenStack has
long-since become too complicated for developers to effectively test in
even the most common configurations on their own, so this process is
very important for developers.

If you have some capacity on an OpenStack cloud that you are able to
contribute to the project, it would be a big help.  This is what we
need:

 * Nova and Glance APIs
 * 8GB RAM, 8vCPU per test node (CPUs vary, the important thing is to
   be able to run devstack and tempest in about 1 hour)
 * Public IP addresses
 * A single instance with 300GB of disk (via Cinder is okay) per cloud
   region for our region-local mirror

Our current providers are each donating around 600 instances of the
above types.  Since there's a bit of setup and maintenance involved in
adding a new provider, a minimum of 100 instances would be helpful.

Since we continuously use the OpenStack APIs and are familiar with how
they should operate, we occasionally discover potential problems with
contributing clouds before many of their other users (or occasionally
even ops teams).  In these cases, we work with contacts on their
operations teams to let them know and try to help fix problems before
they become an issue for their customers.

If this sounds interesting, and you have some capacity to spare, it
would be very much appreciated.  You are welcome to contact the
Infrastructure team on our public mailing list at
<openstack-infra@lists.openstack.org>, or in our IRC channel,
`#openstack-infra` on Freenode.  You are also welcome to contact the
Infrastructure Project Team lead privately at <fungi@yuggoth.org> or
`fungi` on Freenode.
