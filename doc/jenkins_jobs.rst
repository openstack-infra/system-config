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
     review_site: 'review.stackforge.org'
     github_org: 'stackforge'
     project: 'project'
     authenticatedBuild: 'false'
     disabled: 'false'

or for a templated project:

.. code-block:: yaml
   :linenos:

   project:
     template: 'python_jobs'

   values:
     name: 'cinder'
     disabled: 'false'
     github_org: 'openstack'
     review_site: 'review.openstack.org'
     publisher_site: 'nova.openstack.org'


The first example starts with ``---``, this signifies the start of a job, there
can be multiple jobs per project file.  The file does not need to start with the
``---`` but jobs do need to be separated by it.  Each YAML file can contain any
combination of templated or normal jobs.

In the first example the ``modules`` entry is an array of modules that should be
loaded for this job.  Modules are located in the
``modules/jenkins_jobs/files/modules/`` directory and are python scripts to
generate the required XML.  Each module has a comment near the top showing the
required YAML to support that module.  The follow modules are required to
generate a correct XML that Jenkins will support:

* properties (supplies the <properties> XML data)
* scm (supplies the <scm> XML data, required even is scm is not used
* trigger_* (a trigger module is required)
* builders
* publisher_* (a publisher module is required)

Each module also requires a ``main`` section which has the main data for the
modules, inside this there is:

* name - the name of the job
* review_site - review.openstack.org or review.stackforge.org
* github_org - the parent of the github branch for the project (typically `openstack` or `stackforge`
* project - the name of the project
* authenticatedBuild - whether or not you need to be authenticated to hit the
  build button
* disabled - whether or not this job should be disabled

In the templated example there is the ``project`` tag to specify that this is
a templated project.  The ``template`` value specified a template file found in
the ``modules/jenkins_jobs/files/templates`` directory.  The template will look
like a regular set of jobs but contain values in caps surrounded by '@' symbols.
The template process takes the parameters specified in the ``values`` section
and replaces the values surrounded by the '@' symbol.

As an example in the template:

.. code-block:: yaml

   main:
     name: 'gate-@NAME@-pep8'

Using the above example of a templated job the ``@NAME@`` would be replaced with
``cinder``.

Testing a Job
-------------

Once a new YAML file has been created its output can be tested by using the
``jenkins_jobs.py`` script directly.  For example:

.. code-block:: bash

   $ python jenkins_jobs.py test projects/openstack/cinder.yml

This will spit out the XML that would normally be sent directly to Jenkins.

Job Caching
-----------

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
