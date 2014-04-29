:title: Paste

.. _paste:

Paste
#####

Paste servers are an easy way to share long-form content such as
configuration files or log data with others over short-form
communication protocols such as IRC.  OpenContrail runs the "lodgeit"
paste software.

At a Glance
===========

:Hosts:
  * http://paste.opencontrail.org
:Puppet:
  * :file:`modules/lodgeit`
  * :file:`modules/opencontrail_project/manifests/paste.pp`
:Projects:
  * https://git.opencontrail.org/cgit/opencontrail-infra/lodgeit
  * https://bitbucket.org/dcolish/lodgeit-main
  * http://www.pocoo.org/projects/lodgeit/
:Bugs:
  * http://bugs.launchpad.net/opencontrail-ci

Overview
========

For OpenContrail we use `a fork
<https://git.opencontrail.org/cgit/opencontrail-infra/lodgeit>`_ of lodgeit which is
based on one with bugfixes maintained by `dcolish
<https://bitbucket.org/dcolish/lodgeit-main>`_ but adds back missing
anti-spam features required by OpenContrail.

Puppet configures lodgeit to use drizzle as a database backend, apache
as a front-end proxy.

The lodgeit module will automatically create a git repository in
``/var/backups/lodgeit_db``.  Inside this every site will have its own
SQL file, for example "opencontrail" will have a file called
``opencontrail.sql``.  Every day a cron job will update the SQL file (one
job per file) and commit it to the git repository.

.. note::
   Ideally the SQL files would have a row on every line to keep the
   diffs stored in git small, but ``drizzledump`` does not yet support
   this.
