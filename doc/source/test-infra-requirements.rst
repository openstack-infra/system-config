Test infrastructure Requirements
################################

Overview
========

There are multiple different ways that tests can be run. Each has different
trade-offs between cost, reliability and test coverage.

The primary goal for OpenStack test infrastructure is to deliver highly
reliable testing: with 500 patches successfully getting through the OpenStack
gate on a peak day, even short service interruptions have a significant impact
on project velocity.

The same velocity makes it extremely risky to disable tests: once disabled a
test is likely to bitrot quickly, making re-enabling such tests hard.

This gives the following principle:

* Test runs that can stop a patch landing must be highly available - there must
  be at least two distinct places the test can be run, with no shared failure
  domains other than things that the infra team itself is responsible for.

Test run styles
===============

Experimental
------------

Experimental jobs have low reliability requirements: they are run by hand on
developer request, typically as part of bringing up a new job definition.
Failures in experimental jobs are not the responsibility of openstack-infra,
though they will offer best-effort assistance to developers.

Silent
------

Silent jobs are jobs that are not yet ready to vote on code changes. They might
not be ready because of known failures, a lack of redundancy in the
infrastructure or some other reason. In all other regards they are the same
as Check jobs, which means we find out about the test reliability and can
accurately assess whether the job is ready to promote to Check status.

Third party
-----------

Third party test jobs are able to vote on code changes (+/- 1 only). These jobs
are run by third parties on code pushes, but are not able to prevent code
landing. (Developers of projects usually take negative votes from third party
systems seriously however). Third party test jobs cannot be gates, and cannot
set the '+2 verified' flag on review.

Check
-----

Check jobs are used to verify each patch pushed to Gerrit. Like a third party
test job they run against a single pushed patch, rather than the proposed
merged state of the repository. A failure reported by a check job will prevent
the patch being approved. As such check jobs have to run in a highly available
environment with only infra controlled components permitted to have shared
failure domains.

Gate
----

Gate jobs are used to detect failures in patches after they are approved. They
run against the state the OpenStack projects will have if the code is merged
(rather than the state of the pushed code). This allows detection of semantic
conflicts cross-patch (and the usual state for OpenStack is that multiple
patches are going through the gate at once, so this is crucial). Failures in
the gate both prevent the patch landing and cause all the pending patches after
it to be retested. Gate jobs, like check jobs, have to run in a highly
available environment with only infra controlled components permitted to have
shared failure domains.
