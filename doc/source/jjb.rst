:title: Jenkins Job Builder

.. _jjb:

Jenkins Job Builder
###################

Jenkins Job Builder is a system for configuring Jenkins jobs using
simple YAML files stored in Git.

At a Glance
===========

:Hosts:
  * http://jenkins.openstack.org
  * http://jenkins-dev.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-jenkins/tree/manifests/job_builder.pp
:Configuration:
  * :config:`jenkins/jobs/`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/jenkins-job-builder
:Bugs:
  * https://storyboard.openstack.org/#!/project/723
:Resources:
  * `Reference Manual <http://ci.openstack.org/jenkins-job-builder>`_

Overview
========

In order to make the process of managing thousands of Jenkins jobs
easier, Jenkins Job Builder was designed to take YAML based
configurations and convert those into jobs that are injected into
Jenkins.

The documentation below describes how the OpenStack Infrastructure
team uses the Jenkins Job Builder in our environment.

Configuring Projects
====================

The YAML scripts to make this work are stored in the
:config:`jenkins/jobs/` directory of the project-config repository.
In this directory you can have four different types of yaml config
files:

* Jenkins Jobs Defaults in ``defaults.yaml``.
* Jenkins Jobs Macros to give larger config sections meaningful names in
  ``macros.yaml``.
* Project specific configurations in ``project_name.yaml``.
* Job template configurations. Need a ``projects.yaml`` file to
  specify how the templates should be filled out and templates go in
  ``template_name.yaml``.

YAML Format
===========

Defaults
--------

Example defaults config:

.. code-block:: yaml

   - defaults:
       name: global
       project-type: freestyle
       concurrent: true

       wrappers:
         - timeout:
             timeout: 30
             fail: true
         - timestamps

       logrotate:
         daysToKeep: 1
         numToKeep: -1
         artifactDaysToKeep: -1
         artifactNumToKeep: -1

This config starts with the ``- defaults::`` line. This specifies that this
section contains default values rather than job specifications. In this
section we specify a useful set of defaults including a default description
indicating Puppet manages these jobs, jobs are allowed to run concurrently,
and a thirty minute job timeout.

Macros
------

Macros exist to give meaningful names to blocks of configuration that can be
used in job configs in place of the blocks they name. For example:

.. code-block:: yaml

   - builder:
       name: git-prep
       builders:
         - shell: "/slave_scripts/git-prep.sh"

   - builder:
       name: docs
       builders:
         - shell: "/slave_scripts/run-docs.sh"

   - publisher:
       name: console-log
       publishers:
         - scp:
             site: 'scp-server'
             files:
               - target: 'logs/$JOB_NAME/$BUILD_NUMBER'
                 copy-console: true
                 copy-after-failure: true

In this block of code we define two builder macros and one publisher macro.
Each macro has a name and using that name in a job config is equivalent to
having the yaml below the name in place of the name in the job config. The next
section shows how you can use these macros.

Job Config
----------

Example job config:

.. code-block:: yaml

   - job:
       name: example-docs
       node: node-label

       triggers:
         - zuul

       builders:
         - git-prep
         - docs

       publishers:
         - scp:
             site: 'scp-server'
             files:
               - target: 'dir/ectory'
                 source: 'build/html/foo'
                 keep-hierarchy: true
         - console-log

Each job specification begins with ``-job:``. Under this section you can
specify the job details like name, node, etc. Any detail defined in the
defaults section that is not defined under this job will be included as well.
In addition to attribute details you can also specify how jenkins should
perform this job. What trigger methods should be used, the build steps,
jenkins publishing steps and so on. The macros defined earlier make this easy
and simple.

Job Templates
-------------

Job templates allow you to specify a job config once with arguments that are
replaced with the values specified in ``projects.yaml``. This allows you to
reuse job configs across many projects. First you need a templated job config:

.. code-block:: yaml

   - job-template:
       name: '{name}-docs'

       triggers:
         - zuul

       builders:
         - git-prep
         - docs

       publishers:
         - scp:
             site: 'scp-server'
             files:
               - target: 'dir/ectory'
                 source: 'build/html/foo'
                 keep-hierarchy: true
         - console-log

       node: '{node}'


   - job-group:
       name: python-jobs
       jobs:
         - '{name}-docs'

This takes the previous ``example-docs`` job and templatizes it. This will
allow us to easily create ``example1-docs`` and ``example2-docs`` jobs.
Each job template begins with ``- job-template:`` and the job specification is
identical to the previous one, but we have introduced variable arguments. In
this case ``{name}`` is a variable value that will be replaced. The values for
name will be defined in the ``projects.yaml`` file.

The ``- job-group:`` section is not strictly necessary but allows you to group
many job templates with the same variable arguments under one name.

The ``projects.yaml`` pulls all of the magic together. It specifies the
arguments to and instantiates the job templates as real jobs. For example:

.. code-block:: yaml

   - project:
       name: example1
       node: bare-trusty

       jobs:
         - python-jobs

   - project:
       name: example2
       node: bare-centos6

       jobs:
         - {name}-docs

Each project using templated jobs should have its own ``- project:`` section.
Under this sections there should be a ``jobs:`` section with a list of job
templates or job groups to be used by this project. Other values under the
``- project:`` section define the arguments to the templates lised under
``jobs:``. In this case we are giving the docs template ``name`` and ``node``
values.

Notice that example1 makes use of the job group and example2 makes use of the
job template.

Job Caching
-----------

The Jenkins Jobs builder maintains a special `cache`_ that
contains an MD5 of every generated XML that it builds.  If
it finds the XML is different then it will proceed to send this
to Jenkins, otherwise it is skipped. If a job is accidentally deleted
then this file should be modified or removed.

.. _cache: http://ci.openstack.org/jenkins-job-builder/installation.html#running

Sending a Job to Jenkins
------------------------

The Jenkins Jobs builder talks to Jenkins using the Jenkins API.  This
means that it can create and modify jobs directly without the need to
restart or reload the Jenkins server.  It also means that Jenkins will
verify the XML and cause the Jenkins Jobs builder to fail if there is
a problem.

For this to work a configuration file is needed.  There is an erb
template for this configuration file at
:file:`modules/jenkins/templates/jenkins_jobs.ini.erb`.  The contents
of this template are:

.. code-block:: ini

   [jenkins]
   user=<%= username %>
   password=<%= password %>
   url=<%= url %>

The values for user and url are hardcoded in the Puppet repo in
:file:`modules/openstack_project/manifests/jenkins.pp`, but the
password is stored in hiera. Make sure you have it defined as
``jenkins_jobs_password`` in the hiera DB.

The password can be obtained by logging into the Jenkins user,
clicking on your username in the top-right, clicking on `Configure`
and then `Show API Token`.  This API Token is your password for the
API.
