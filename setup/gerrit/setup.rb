#!/usr/bin/env ruby

# Copy id_rsa and id_rsa.pub to /root/.ssh/.

# Setup opencontrail-admin user by logging onto web interface
# Setup user as opencontrail-admin
# https://review.opencontrail.org/#/admin/projects/All-Projects,access
# add 'PUSH' to Administrators and save settings

# Run this as 
#   sudo su -
#   setup.rb

ADMIN_EMAIL="anantha@juniper.net"
ADMIN_NAME="Ananth Suryanarayana"

GERRIT_HOST="review.opencontrail.org"
HOME="/root" # HOME=ENV['HOME']
SSH_OPTIONS="-qp 29418 -F #{HOME}/.ssh/config #{GERRIT_HOST} gerrit"

cmd=<<EOF
insert into approval_categories values ('Approved', 'A', 2, 'MaxNoBlock', 'N', 'APRV');
insert into approval_category_values values ('No score', 'APRV', 0);
insert into approval_category_values values ('Approved', 'APRV', 1);
update approval_category_values set name = "Looks good to me (core reviewer)" where name ="Looks good to me, approved";
EOF

def run(cmd)
    File.open("/tmp/cmd", "w") { |fp| fp.puts cmd }
    `cat /tmp/cmd | mysql -pc0ntrail123 reviewdb`
end

run(cmd)

cmd=<<EOF
update approval_category_values set value=2
    where value=1 and category_id='VRIF';
update approval_category_values set value=-2
    where value=-1 and category_id='VRIF';
insert into approval_category_values values
    ("Doesn't seem to work","VRIF",-1),
    ("Works for me","VRIF","1");
EOF

run(cmd)

cmd=<<EOF
update approval_category_values set name="Do not merge"
    where category_id='CRVW' and value=-2;
update approval_category_values
    set name="I would prefer that you didn't merge this"
    where category_id='CRVW' and value=-1;
EOF
run(cmd)

cmd=<<EOF
insert into contributor_agreements values (
  'Y', 'Y', 'Y', 'ICLA',
  'OpenStack Individual Contributor License Agreement',
  'static/cla.html', 2);
EOF
run(cmd)

cmd=<<EOF
Host #{GERRIT_HOST}
# Hostname review.opencontrail.org
User opencontrail-admin
PubKeyAuthentication yes
IdentityFile #{HOME}/.ssh/id_rsa
EOF

File.open("/tmp/cmd", "w") { |fp| fp.puts cmd }
`cat /tmp/cmd > #{HOME}/.ssh/config`

# Create necessary gerrit groups
`#{%{ssh #{SSH_OPTIONS} create-group "'Project Bootstrappers'"}}`
`#{%{ssh #{SSH_OPTIONS} create-group "'Third-Party CI'"}}`
`#{%{ssh #{SSH_OPTIONS} create-group "'Voting Third-Party CI'"}}`
`#{%{ssh #{SSH_OPTIONS} create-group "'Continuous Integration Tools'"}}`
`#{%{ssh #{SSH_OPTIONS} create-group "'Release Managers'"}}`
`#{%{ssh #{SSH_OPTIONS} create-group "'Stable Maintainers'"}}`

`cat #{HOME}/.ssh/id_rsa.pub | ssh #{SSH_OPTIONS} create-account --group "'Project Bootstrappers'" --group Administrators --full-name "'Project Creator'" --email openstack-infra@lists.opencontrail.org --ssh-key - opencontrail-project-creator`

# Get the UUIDs of the groups.
group_id1 =`#{%{echo "select group_uuid from account_groups where name = 'Project Bootstrappers'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id2 =`#{%{echo "select group_uuid from account_groups where name = 'Third-Party CI'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id3 =`#{%{echo "select group_uuid from account_groups where name = 'Voting Third-Party CI'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id4 =`#{%{echo "select group_uuid from account_groups where name = 'Continuous Integration Tools'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id5 =`#{%{echo "select group_uuid from account_groups where name = 'Release Managers'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id6 =`#{%{echo "select group_uuid from account_groups where name = 'Stable Maintainers'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id7 =`#{%{echo "select group_uuid from account_groups where name = 'Stable Non-Interactive Users'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp
group_id8 =`#{%{echo "select group_uuid from account_groups where name = 'Administrators'" | mysql -pc0ntrail123 --skip-column-names reviewdb}}`.chomp

cmd=<<EOF
# UUID	Group Name
#
#{group_id8}	Administrators
global:Anonymous-Users	Anonymous Users
global:Project-Owners	Project Owners
global:Registered-Users	Registered Users
#{group_id1}	Project Bootstrappers
#{group_id2}	Third-Party CI
#{group_id3}	Voting Third-Party CI
#{group_id4}	Continuous Integration Tools
#{group_id5}	Release Managers
#{group_id6}	Stable Maintainers
#{group_id7}	Non-Interactive Users
EOF
File.open("/tmp/gerrit_groups", "w") { |fp| fp.puts cmd }

cmd=<<EOF
 [project]
     description = Rights inherited by all other projects
     state = active
 [access "refs/*"]
     read = group Anonymous Users
     pushTag = group Continuous Integration Tools
     pushTag = group Project Bootstrappers
     pushTag = group Release Managers
     forgeAuthor = group Registered Users
     forgeCommitter = group Project Bootstrappers
     push = +force group Project Bootstrappers
     create = group Project Bootstrappers
     create = group Release Managers
     pushMerge = group Project Bootstrappers
 [access "refs/heads/*"]
     label-Code-Review = -2..+2 group Project Bootstrappers
     label-Code-Review = -1..+1 group Registered Users
     label-Verified = -2..+2 group Continuous Integration Tools
     label-Verified = -2..+2 group Project Bootstrappers
     label-Verified = -1..+1 group Voting Third-Party CI
     submit = group Continuous Integration Tools
     submit = group Project Bootstrappers
     label-Approved = +0..+1 group Project Bootstrappers
 [access "refs/meta/config"]
     read = group Project Owners
 [access "refs/for/refs/*"]
     push = group Registered Users
 [access "refs/heads/milestone-proposed"]
     exclusiveGroupPermissions = label-Approved label-Code-Review
     label-Code-Review = -2..+2 group Project Bootstrappers
     label-Code-Review = -2..+2 group Release Managers
     label-Code-Review = -1..+1 group Registered Users
     owner = group Release Managers
     label-Approved = +0..+1 group Project Bootstrappers
     label-Approved = +0..+1 group Release Managers
 [access "refs/heads/stable/*"]
     forgeAuthor = group Stable Maintainers
     forgeCommitter = group Stable Maintainers
     exclusiveGroupPermissions = label-Approved label-Code-Review
     label-Code-Review = -2..+2 group Project Bootstrappers
     label-Code-Review = -2..+2 group Stable Maintainers
     label-Code-Review = -1..+1 group Registered Users
     label-Approved = +0..+1 group Project Bootstrappers
     label-Approved = +0..+1 group Stable Maintainers
 [access "refs/meta/openstack/*"]
     read = group Continuous Integration Tools
     create = group Continuous Integration Tools
     push = group Continuous Integration Tools
 [capability]
     administrateServer = group Administrators
     priority = batch group Non-Interactive Users
     createProject = group Project Bootstrappers
 [access "refs/zuul/*"]
     create = group Continuous Integration Tools
     push = +force group Continuous Integration Tools
     pushMerge = group Continuous Integration Tools
 [access "refs/for/refs/zuul/*"]
     pushMerge = group Continuous Integration Tools
EOF

File.open("/tmp/gerrit_project.config", "w") { |fp| fp.puts cmd }

# echo "#!/usr/bin/env sh" > #{HOME}/All-Projects-ACLs/git_ssh
# echo "exec ssh -F #{HOME}/.ssh/config \\$*" >> git_ssh
# chmod +x git_ssh
# export GIT_SSH=#{HOME}/All-Projects-ACLs/git_ssh

cmd = <<EOF
rm -rf #{HOME}/All-Projects-ACLs
mkdir #{HOME}/All-Projects-ACLs
cd #{HOME}/All-Projects-ACLs

git config --global user.name "#{ADMIN_NAME}"
git config --global user.email "#{ADMIN_EMAIL}"
git init
git remote add gerrit ssh://opencontrail-admin@#{GERRIT_HOST}:29418/All-Projects.git
git fetch gerrit '+refs/meta/*:refs/remotes/gerrit-meta/*'
git checkout -b config remotes/gerrit-meta/config
cat /tmp/gerrit_groups > groups
cat /tmp/gerrit_project.config > project.config
git commit --author=anantha@juniper.net -m "All projects ACL" .
git push gerrit HEAD:refs/meta/config
EOF

File.open("/tmp/cmd", "w") { |fp| fp.puts cmd }

# Finally run the commands and update gerrit meta config.
`cat /tmp/cmd | sh`

`cat #{HOME}/.ssh/id_rsa.pub | ssh #{SSH_OPTIONS} create-account --group "'Continuous Integration Tools'" --full-name "'Zuul'" --email zuul@lists.opencontrail.org --ssh-key - zuul`

