:title: Infrastructure Systems

Infrastructure Systems
######################

The OpenStack Infrastructure team maintains a number of systems that are
critical to the operation of the OpenStack project, such as gerrit, jenkins,
mailman, meetbot, etherpad, paste, and others.

Additionally the team maintains the project sites on Launchpad and
GitHub.  The following policies have been adopted to ensure the
continued and secure operation of the project.

SSH Access
**********

For any of the systems managed by the OpenStack Infrastructure team, the
following practices must be observed for SSH access:

 * SSH access is only permitted with SSH public/private key
   authentication.
 * Users must use a strong passphrase to protect their private key.  A
   passphrase of several words, at least one of which is not in a
   dictionary is advised, or a random string of at least 16
   characters.
 * To mitigate the inconvenience of using a long passphrase, users may
   want to use an SSH agent so that the passphrase is only requested
   once per desktop session.
 * Users private keys must never be stored anywhere except their own
   workstation(s).  In particular, they must never be stored on any
   remote server.
 * If users need to 'hop' from a server or bastion host to another
   machine, they must not copy a private key to the intermediate
   machine (see above).  Instead SSH agent forwarding may be used.
   However due to the potential for a compromised intermediate machine
   to ask the agent to sign requests without the users knowledge, in
   this case only an SSH agent that interactively prompts the user
   each time a signing request (ie, ssh-agent, but not gnome-keyring)
   is received should be used, and the SSH keys should be added with
   the confirmation constraint ('ssh-add -c').
 * The number of SSH keys that are configured to permit access to
   OpenStack machines should be kept to a minimum.
 * OpenStack Infrastructure machines must use puppet to centrally manage and
   configure user accounts, and the SSH authorized_keys files from the
   openstack-infra/config repository.
 * SSH keys should be periodically rotated (at least once per year).
   During rotation, a new key can be added to puppet for a time, and
   then the old one removed.  Be sure to run puppet on the backup
   servers to make sure they are updated.

Servers
*******

Because the configuration of servers is managed in puppet, anyone may
propose changes to existing servers, or propose that new servers be
created by editing the puppet configuration and uploading a change for
review in Gerrit.  The installation and maintenance of software on
project infrastructure servers should be carried out entirely through
puppet so that anyone can contribute.

The Git repository with the puppet configuration may be cloned from
https://github.com/openstack-infra/config and changes submitted
with `git-review`.

In order to ensure that it is easy for both the OpenStack project as
well as others to re-use the configuration in that repository, server
definitions are split into two levels of abstraction: first, a class
is created that defines the configuration of the server, but without
specifics such as hostnames and passwords.  Then a node definition is
created that uses that class, passing in any specific information
needed for that node.

For instance, `modules/openstack_project/manifests/gerrit.pp` defines a
class which specifies how the OpenStack project configures a gerrit
server, and then `manifests/site.pp` defines a node that uses that
class, passing in passwords and other information specific to that
node obtained from puppet's hiera.

To create a new server, do the following:

 * Add a file in `modules/openstack_project/manifests/` that defines a
   class which specifies the configuration of the server.

 * Add a node entry in `manifests/site.pp` for the server that uses that
   class.

 * If your server needs private information such as password,s use
   hiera calls in the site manifest, and ask an infra-core team member
   to manually add the private information to hiera.

 * You should be able to install and configure most software only with
   puppet.  Nonetheless, if you need SSH access to the host, add your
   public key to `modules/openstack_project/manifests/users.pp` and
   include a stanza like this in your server class::

     realize (
        User::Virtual::Localuser['USERNAME'],
     )

 * Add an RST file with documentation about the server in `doc/source`
   and add it to the index in that directory.

Backups
*******

Off-site backups are made to two servers:

 * ci-backup-rs-ord.openstack.org
 * ci-backup-hp-az1.openstack.org

Puppet is used to perform the initial configuration of those machines,
but to protect them from unauthorized access in case access to the
puppet git repo is compromised, it is not run in agent or in cron mode
on them.  Instead, it should be manually run when changes are made
that should be applied to the backup servers.

To start backing up a server, some commands need to be run manually on
both the backup server, and the server to be backed up.  On the server
to be backed up::

  ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""

And then ''cat /root/.ssh/id_rsa.pub'' for use later.

On the backup servers::

  sudo su -
  BUPUSER=bup-<short-servername>  # eg, bup-jenkins-dev
  useradd -r $BUPUSER -s /bin/bash -m
  cd /home/$BUPUSER
  mkdir .ssh
  cat >.ssh/authorized_keys

and add this to the authorized_keys file::

  command="BUP_DEBUG=0 BUP_FORCE_TTY=3 bup server",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty <ssh key from earlier>

Switching back to the server to be backed up, run::

  ssh $BUPUSER@ci-backup-rs-ord.openstack.org
  ssh $BUPUSER@ci-backup-hp-az1.openstack.org

And verify the host key.  Add the "backup" class in puppet to the server
to be backed up.

GitHub Access
*************

To ensure that code review and testing are not bypassed in the public
Git repositories, only Gerrit will be permitted to commit code to
OpenStack repositories.  Because GitHub always allows project
administrators to commit code, accounts that have access to manage the
GitHub projects necessarily will have commit access to the
repositories.  Therefore, to avoid inadvertent commits to the public
repositories, unique administrative-only accounts must be used to
manage the OpenStack GitHub organization and projects.  These accounts
will not be used to check out or commit code for any project.
