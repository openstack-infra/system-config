1) Generate repos to clone
--------------------------

 $ python3 ./all-repos.py > repos.txt

This currently filters to repos with devstack-plugins in the
openstack/ namespace.


2) Clone repos
--------------

 $ bash ./clone.sh

All repos will be cloned into "repos" subdir and have commit hooks
ready to generate Change-Id


3) Generate changes
-------------------

 $ bash ./replace.sh

This will iterate all repos in "./repos".  For each repo it will
modify git:// -> https:// on the master and any stable branches and
commit a change.

It will create a branch "opendev-gerrit-$branch" (using the last part
of stable/*, e.g. rocky) for each change.

It will output a text file "to-push.txt" in the format

 repodir branch remote

To track what should be pushed


4) Push changes
---------------

 $ bash ./pushit.sh

Reads the "to-push.txt" and creates a gerrit review


X) Revert all changes
---------------------

 $ bash ./reset.sh

Deletes all "opendev-gerrit-*" branches and resets to master.  Not
necessary but useful for debugging.

