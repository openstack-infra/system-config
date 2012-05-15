:title: Infrastructure Systems

Infrastructure Systems
######################

The OpenStack CI team maintains a number of systems that are critical
to the operation of the OpenStack project.  At the time of writing,
these include:

 * Gerrit (review.openstack.org)
 * Jenkins (jenkins.openstack.org)
 * community.openstack.org

Additionally the team maintains the project sites on Launchpad and
GitHub.  The following policies have been adopted to ensure the
continued and secure operation of the project.

SSH Access
**********

For any of the systems managed by the CI team, the following practices
must be observed for SSH access:

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
 * OpenStack CI machines must use puppet to centrally manage and
   configure user accounts, and the SSH authorized_keys files from the
   openstack-ci-puppet repository.
 * SSH keys should be periodically rotated (at least once per year).
   During rotation, a new key can be added to puppet for a time, and
   then the old one removed.

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

Launchpad Teams
***************

Each OpenStack project should have the following teams on Launchpad:

 * foo -- contributors to project 'foo'
 * foo-core -- core developers
 * foo-bugs -- people interested in receieving bug reports
 * foo-drivers -- people who may approve and target blueprints

The openstack-admins team should be a member of each of those teams.
