Jenkins Job Builder
===================

Overview
--------

In order to make the process of managing hundreds of Jenkins Jobs easier a
Python based utility was designed to take YAML based configurations and convert
those into jobs that are injected into Jenkins.

Adding a project
----------------

The YAML scripts to make this work are stored in the ``openstack-ci-puppet``
repository in the ``modules/jenkins_jobs/files/projects/site/project.yaml``
directory.  Where ``site`` is either `openstack` or `stackforge` and ``project``
is the name of the project the YAML file is for.

Once the YAML file is added the puppet module needs to be told that the project
is there.  For example:

.. code-block:: ruby
   :linenos:

   class { "jenkins_jobs":
     site => "stackforge",
     projects => ['reddwarf', 'ceilometer']
   }

In this example the YAML files for `reddwarf` and `ceilometer` in the
`stackforge` projects directory will be executed.

YAML Format
-----------

The bare minimum YAML needs to look like this:

.. code-block:: yaml
   :linenos:

   ---
   modules:
     - properties
     - scm
     - assignednode
     - trigger_none
     - builders
     - publisher_none

   main:
     name: 'job-name'
     site: 'stackforge'
     project: 'project'
     authenticatedBuild: 'false'
     disabled: 'false'

This example starts with ``---``, this signifies the start of a job, there can
be multiple jobs per project file.
The ``modules`` entry is an array of modules that should be loaded for this job.
Modules are located in the ``modules/jenkins_jobs/files/modules/`` directory
and are python scripts to generate the required XML.  Each module has a comment
near the top showing the required YAML to support that module.  The follow
modules are required to generate a correct XML that Jenkins will support:

* properties (supplies the <properties> XML data)
* scm (supplies the <scm> XML data, required even is scm is not used
* trigger_* (a trigger module is required)
* builders
* publisher_* (a publisher module is required)

Each module also requires a ``main`` section which has the main data for the
modules, inside this there is:

* name - the name of the job
* site - openstack or stackforge
* project - the name of the project
* authenticatedBuild - whether or not you need to be authenticated to hit the
  build button
* disabled - whether or not this job should be disabled

Testing for Job Changes
-----------------------

The Jenkins Jobs builder maintains a special YAML file in
``~/.jenkins_jobs_cache.yml``.  This contains an MD5 of every generated XML that
it builds.  If it finds the XML is different then it will proceed to send this
to Jenkins, otherwise it is skipped.  If a job is accidentally deleted then this
file should be modified or removed.

Sending a Job to Jenkins
------------------------

The Jenkins Jobs builder talks to Jenkins using the Jenkins API.  This means
that it can create and modify jobs directly without the need to restart or
reload the Jenkins server.  It also means that Jenkins will verify the XML and
cause the Jenkins Jobs builder to fail if there is a problem.

For this to work a configuration file is needed.  This needs to be stored in
``/root/secret-files/jenkins_jobs.ini`` and puppet will automatically put it in
the right place.  The format for this file is as follows:

.. code-block:: ini

   [jenkins]
   user=username
   password=password
   url=jenkins_url

The password can be obtained by logging into the Jenkins user, clicking on your
username in the top-right, clicking on `Configure` and then `Show API Token`.
This API Token is your password for the API.

Adding a Module
---------------

Modules need to contain a class with the same name as the filename.  The basic
layout is:

.. code-block:: python

   import xml.etree.ElementTree as XML

   class my_module(object):
       def __init__(self, data):
           self.data = data

       def gen_xml(self, xml_parent):

The ``__init__`` function will be provided with ``data`` which is a Python
dictionary representing the YAML data for the job.

The ``gen_xml`` function will be provided with ``xml_parent`` which is an
XML ElementTree object to be modified.
