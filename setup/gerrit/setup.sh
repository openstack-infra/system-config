#!/usr/bin/env bash

cmd=<<EOF
insert into approval_categories values ('Approved', 'A', 2, 'MaxNoBlock', 'N', 'APRV');
insert into approval_category_values values ('No score', 'APRV', 0);
insert into approval_category_values values ('Approved', 'APRV', 1);
update approval_category_values set name = "Looks good to me (core reviewer)" where name="Looks good to me, approved";
EOF
echo $cmd | mysql -pc0ntrail123 reviewdb

cmd=<<EOF
update approval_category_values set value=2
    where value=1 and category_id='VRIF';
  update approval_category_values set value=-2
    where value=-1 and category_id='VRIF';
  insert into approval_category_values values
    ("Doesn't seem to work","VRIF",-1),
    ("Works for me","VRIF","1");
EOF
echo $cmd | mysql -pc0ntrail123 reviewdb

cmd=<<EOF
update approval_category_values set name="Do not merge"
    where category_id='CRVW' and value=-2;
  update approval_category_values
    set name="I would prefer that you didn't merge this"
    where category_id='CRVW' and value=-1;
EOF
echo $cmd | mysql -pc0ntrail123 reviewdb

cmd=<<EOF
insert into contributor_agreements values (
  'Y', 'Y', 'Y', 'ICLA',
  'OpenStack Individual Contributor License Agreement',
  'static/cla.html', 2);
EOF
echo $cmd | mysql -pc0ntrail123 reviewdb

# Setup ssh based auto-authentication
GERRIT_HOST=localhost # 10.84.13.93 review.opencontrail.org
s=<<EOF
Host $GERRIT_HOST
# Hostname review.opencontrail.org
User opencontrail-admin
PubKeyAuthentication yes
IdentityFile $HOME/.ssh/id_rsa
EOF

echo $s > $HOME/.ssh/config
SSH_OPTIONS="-qp 29418 -F $HOME/.ssh/config $GERRIT_HOST gerrit"

# Create necessary gerrit groups
ssh $SSH_OPTIONS create-group "'Project Bootstrappers'"
ssh $SSH_OPTIONS create-group "'Third-Party CI'"
ssh $SSH_OPTIONS create-group "'Voting Third-Party CI'"
ssh $SSH_OPTIONS create-group "'Continuous Integration Tools'"
ssh $SSH_OPTIONS create-group "'Release Managers'"
ssh $SSH_OPTIONS create-group "'Stable Maintainers'"

ssh -qp 29418 $GERRIT_HOST ls-groups

# Create opencontrail-project-creator account
cat $HOME/.ssh/id_rsa.pub | ssh $SSH_OPTIONS create-account --group "'Project Bootstrappers'" --group Administrators --full-name "'Project Creator'" --email openstack-infra@lists.opencontrail.org --ssh-key - opencontrail-project-creator

# https://10.84.13.93/#/admin/projects/All-Projects,access
# add 'PUSH' to Administrators
# save settings

mkdir $HOME/All-Projects-ACLs
cd $HOME/All-Projects-ACLs
git init
git remote add gerrit ssh://opencontrail-admin@10.84.13.93:29418/All-Projects.git
git fetch gerrit '+refs/meta/*:refs/remotes/gerrit-meta/*'
git checkout -b config remotes/gerrit-meta/config

diff=<<EOF
diff --git a/groups b/groups
index 5388afa..615c6bf 100644
--- a/groups
+++ b/groups
@@ -4,3 +4,11 @@ d57ee2694b91f2adb020dd193adfe6eace4fdabf	Administrators
 global:Anonymous-Users                  	Anonymous Users
 global:Project-Owners                  	Project Owners
 global:Registered-Users                	Registered Users
+20c841a6cb2274da1f225e2bf75a535c705af948	Project Bootstrappers
+4ddd80bc48164f4595e3c541156371106121d313	Third-Party CI
+691beb563c3bc860e7979ac75ac6bd40d98d3ac3	Voting Third-Party CI
+519fc62ba78d027ba5779260eb23be501f8343fe	Continuous Integration Tools
+2b3da7175d1f1e804320970fcbb4d0ee4179993c	Release Managers
+a8208d8ac85e903c2d12e182e4e7312c82140028	Stable Maintainers
+4c0273d4070d42ee42f3f21998f825ab4bfc39d0	Non-Interactive Users
+
diff --git a/project.config b/project.config
index 4d301c9..0364a0d 100644
--- a/project.config
+++ b/project.config
@@ -1,15 +1,58 @@
 [project]
-       description = Rights inherited by all other projects
-       state = active
-[capability]
-       administrateServer = group Administrators
-[access "refs/*"]
-       read = group Administrators
-       read = group Anonymous Users
-       forgeAuthor = group Registered Users
-[access "refs/for/refs/*"]
-       push = group Registered Users
-[access "refs/heads/*"]
-       label-Code-Review = -1..+1 group Registered Users
-[access "refs/meta/config"]
-       read = group Project Owners
+     description = Rights inherited by all other projects
+     state = active
+ [access "refs/*"]
+     read = group Anonymous Users
+     pushTag = group Continuous Integration Tools
+     pushTag = group Project Bootstrappers
+     pushTag = group Release Managers
+     forgeAuthor = group Registered Users
+     forgeCommitter = group Project Bootstrappers
+     push = +force group Project Bootstrappers
+     create = group Project Bootstrappers
+     create = group Release Managers
+     pushMerge = group Project Bootstrappers
+ [access "refs/heads/*"]
+     label-Code-Review = -2..+2 group Project Bootstrappers
+     label-Code-Review = -1..+1 group Registered Users
+     label-Verified = -2..+2 group Continuous Integration Tools
+     label-Verified = -2..+2 group Project Bootstrappers
+     label-Verified = -1..+1 group Voting Third-Party CI
+     submit = group Continuous Integration Tools
+     submit = group Project Bootstrappers
+     label-Approved = +0..+1 group Project Bootstrappers
+ [access "refs/meta/config"]
+     read = group Project Owners
+ [access "refs/for/refs/*"]
+     push = group Registered Users
+ [access "refs/heads/milestone-proposed"]
+     exclusiveGroupPermissions = label-Approved label-Code-Review
+     label-Code-Review = -2..+2 group Project Bootstrappers
+     label-Code-Review = -2..+2 group Release Managers
+     label-Code-Review = -1..+1 group Registered Users
+     owner = group Release Managers
+     label-Approved = +0..+1 group Project Bootstrappers
+     label-Approved = +0..+1 group Release Managers
+ [access "refs/heads/stable/*"]
+     forgeAuthor = group Stable Maintainers
+     forgeCommitter = group Stable Maintainers
+     exclusiveGroupPermissions = label-Approved label-Code-Review
+     label-Code-Review = -2..+2 group Project Bootstrappers
+     label-Code-Review = -2..+2 group Stable Maintainers
+     label-Code-Review = -1..+1 group Registered Users
+     label-Approved = +0..+1 group Project Bootstrappers
+     label-Approved = +0..+1 group Stable Maintainers
+ [access "refs/meta/openstack/*"]
+     read = group Continuous Integration Tools
+     create = group Continuous Integration Tools
+     push = group Continuous Integration Tools
+ [capability]
+     administrateServer = group Administrators
+     priority = batch group Non-Interactive Users
+     createProject = group Project Bootstrappers
+ [access "refs/zuul/*"]
+     create = group Continuous Integration Tools
+     push = +force group Continuous Integration Tools
+     pushMerge = group Continuous Integration Tools
+ [access "refs/for/refs/zuul/*"]
+     pushMerge = group Continuous Integration Tools
EOF
echo $diff | patch -p1

git commit -am "All projects ACL" .
git push gerrit HEAD:refs/meta/config

service gerrit restart
manage-projects -dv

function delete_project {
	PROJECT=contrail-controller
    rm -rf ~gerrit2/review_site/git/stackforge/$PROJECT.git /var/lib/jeepyb/stackforge/$PROJECT
    service gerrit restart
    manage-projects -dv
}
