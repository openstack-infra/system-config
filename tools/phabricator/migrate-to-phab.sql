-- (c) 2015 Hewlett-Packard Development Company, L.P.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
-- implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Migrate data from a storyboard schema to a phabricator schema
-- Assumes standard phabricator schema and that storyboard schema is loaded
-- in storyboard adjacent to the phabricator schema

use storyboard;

delimiter //

-- phabricator uses an artificial id for everything to facilitate vertical
-- sharding without needing cross-repo joins. You can tell they started life
-- at Facebook
drop function if exists make_phid //
create function make_phid(slug varbinary(9))
    returns varbinary(30)
BEGIN
  return concat(
    'PHID-',
    concat(slug, concat('-', left(
        concat(
            lower(conv(floor(rand() * 99999999999999), 20, 36)),
            lower(conv(floor(rand() * 99999999999999), 20, 36))
        ),
        24-length(slug)
    ))));
END //

-- There are several places where columns need a random string of a length
-- This is kinda lame way to make it (make a 256 character random string, then
-- return the first len characters, but it gets the job done
drop function if exists make_cert //
create function make_cert(len integer)
    returns varbinary(255)
BEGIN
  return left(
    concat(
        md5(rand()),
        md5(rand()),
        md5(rand()),
        md5(rand()),
        md5(rand()),
        md5(rand()),
        md5(rand()),
        md5(rand())
    ), len);
END //

-- This is used to populate projectPathKey and creates an apache style
-- 1000 md5s in a row password hash that we can use to seed the database
-- with a bunch of passwords
drop function if exists make_hash //
create function make_hash(input varbinary(255))
    returns varbinary(255)
BEGIN
  DECLARE x int;
  DECLARE str VARBINARY(255);
  SET x = 0;
  SET str = input;
  while x < 1000 DO
    SET str = md5(str);
    SET x = x + 1;
  END WHILE;
  return str;
END //
delimiter ;

-- $hash = sha1(PHID, $raw_output = true);

-- We're going to generate PHID values in each of the original tables
-- so that we can inject via joins
alter table users add column phid varbinary(64);
alter table stories add column phid varbinary(64);
alter table tasks add column phid varbinary(64);
alter table tasks add column storyPHID varbinary(64);
alter table projects add column phid varbinary(64);
alter table project_groups add column phid varbinary(64);
alter table comments add column phid varbinary(64);
alter table comments add column transPHID varbinary(64);

-- Add PHIDs to everything
update users set phid = make_phid('USER');
update stories set phid = make_phid('TASK');
update tasks set phid = make_phid('TASK');
update projects set phid = make_phid('PROJ');
update project_groups set phid = make_phid('PROJ');
update comments set phid = make_phid('XCMT');
update comments set transPHID = make_phid('XACT-TASK');

-- We want to track what story the task was related to without needing a
-- backreference join
update stories, tasks
  set tasks.storyPHID=stories.phid
  where stories.id=tasks.story_id;

-- There are a bunch of duplicate users in the storyboard db that are listed
-- with @example.com email addresses. username is unique in phabricator
update users
  set id=concat(id, '_')
  where email like '%example.com' and id not like '%_';


-- Create temporary table that helps us sort stories with a single task
-- from stories with multiple tasks
drop table if exists task_count;
create table task_count
  select story_id, storyPHID, count(storyPHID) as count
  from tasks group by storyPHID;

-- Scrub the data into something a bit more usable before we import
alter table tasks
  modify column `priority` enum('low', 'medium', 'high', 'wishlist');
update tasks set priority='wishlist' where priority is null;
update tasks set status='todo' where status is NULL;

-- We're straight re-using the ids, so we need to make sure story and task ids
-- don't conflict.
-- Also, id's start with a T now, so we don't need to do as much to avoid
-- overlap with launchpad ids
alter table tasks drop foreign key tasks_ibfk_4;
update stories set id = id+3000 where id < 3000;
update tasks set story_id = story_id + 3000 where story_id < 3000;
update events set story_id = story_id + 3000 where story_id < 3000;
update stories set id = id - 2000000 + 4000 where id >= 2000000;
update tasks set story_id = story_id - 2000000 + 4000 where story_id >= 2000000;
update events set story_id = story_id - 2000000 + 4000 where story_id < 2000000;

use phabricator_user

delete from user;
delete from user_email;

insert into user
   select
     id as id,
     phid as phid,
     storyboard.make_phid('') as userName,
     if(full_name is NULL, email, full_name) as realName,
     NULL as sex,
     NULL as translation,
     storyboard.make_cert(32) as passwordSalt,
     '' as passwordHash,
     unix_timestamp(created_at) as dateCreated,
     if(updated_at is NULL, unix_timestamp(now()), unix_timestamp(updated_at)) as dateModified,
     NULL as profileImagePHID,
     0 as consoleEnabled,
     0 as consoleVisible,
     '' as consoleTab,
     storyboard.make_cert(255) as conduitCertificate,
     0 as isSystemAgent,
     0 as isDisabled,
     is_superuser as isAdmin,
     'UTC' as timezoneIdentifier,
     0 as isEmailVerified,
     1 as isApproved,
     1 as accountSecret,
     1 as isEnrolledInMultiFactor,
     NULL as profileImageCache,
     NULL as availabilityCache,
     NULL as availabilityCacheTTL,
     0 as isMailingList
   from storyboard.users;

update user
  set passwordHash = concat(
    'md5:', storyboard.make_hash(
        concat(username, 'password', phid, passwordSalt)));

update user
  set userName = replace(
      userName, 'PHID--', '');

insert into user_email
  select
    id, phid, email, 1, 1,
    storyboard.make_cert(24),
    unix_timestamp(created_at),
    if(updated_at is NULL, unix_timestamp(now()), unix_timestamp(updated_at))
  from storyboard.users;


use phabricator_maniphest

-- priorities
--  100 = Unbreak Now!
--  90 = Needs Triage
--  80 = High
--  50 = Normal
--  25 = Low
--  0 = Wishlist

delete from maniphest_task;
delete from edge;
delete from maniphest_transaction;
delete from maniphest_transaction_comment;

-- stories with one task get collapsed in a single new task
insert into maniphest_task
  select
    s.id as id,
    s.phid as phid,
    if(s.creator_id is NULL, '', s.creator_id) as authorPHID,
    if(t.assignee_id is NULL, NULL, t.assignee_id) as ownerPHID,
    case t.status -- status
        when 'todo' then 'open'
        when 'inprogress' then 'inprogress'
        when 'invalid' then 'invalid'
        when 'review' then 'review'
        when 'merged' then 'merged'
        when 'invalid' then 'invalid'
    end as status,
    case t.priority -- priority
        when 'high' then 80
        when 'medium' then 50
        when 'low' then 25
        when 'wishlist' then 0
    end as priority,
    s.title as title,
    s.title as originalTitle,
    s.description as description,
    unix_timestamp(s.created_at) as dateCreated,
    if(t.updated_at is NULL, unix_timestamp(t.created_at), unix_timestamp(t.updated_at)) as dateModified,
    storyboard.make_cert(20) as mailKey,
    NULL as ownerOrdering,
    NULL as originalEmailSource,
    0 as subpriority,
    'users' as viewPolicy,
    'users' as editPolicy,
    NULL as spacePHID,
    ' ' as properties,
    NULL as points
  from storyboard.stories s, storyboard.tasks t, storyboard.task_count c
  where s.id = t.story_id and c.story_id=s.id and c.count = 1;

-- For stories with more than one task, each task becomes a new task
insert into maniphest_task
  select
    t.id,
    t.phid,
    if(t.creator_id is NULL, '', t.creator_id), -- u.phid,
    if(t.assignee_id is NULL, NULL, t.assignee_id),  -- second pass
    '',
    case t.status
        when 'todo' then 'open'
        when 'inprogress' then 'inprogress'
        when 'invalid' then 'invalid'
        when 'review' then 'review'
        when 'merged' then 'merged'
        when 'invalid' then 'invalid'
    end,
    case t.priority
        when 'high' then 80
        when 'medium' then 50
        when 'low' then 25
        when 'wishlist' then 0
    end,
    t.title,
    t.title,
    '',
    unix_timestamp(t.created_at),
    if(t.updated_at is NULL, unix_timestamp(t.created_at), unix_timestamp(t.updated_at)),
    '[]', -- update in second pass
    storyboard.make_cert(20),
    NULL,
    NULL,
    0,
    'users',
    'users',
    NULL -- spacePHID
  from storyboard.stories s, storyboard.tasks t, storyboard.task_count c
  where s.id = t.story_id and c.story_id=s.id and c.count > 1;

-- For stories with more than one task, each story also becomes a task, but
-- it doesn't have a project associated with it
insert into maniphest_task
  select
    s.id,
    s.phid,
    if(s.creator_id is NULL, '', s.creator_id), -- u.phid,
    NULL,
    '',
    'open',
    50,
    s.title,
    s.title,
    s.description,
    unix_timestamp(s.created_at),
    if(s.updated_at is NULL, unix_timestamp(s.created_at), unix_timestamp(s.updated_at)),
    '[]',
    storyboard.make_cert(20),
    NULL,
    NULL,
    0,
    'users',
    'users',
    NULL -- spacePHID
  from storyboard.stories s, storyboard.task_count c, storyboard.users u
  where c.story_id=s.id and c.count > 1
   and u.id = s.creator_id;

-- Set the author and owner PHIDs as a second pass to avoid really crazy
-- join semantics above. It could be done ... but why?
update maniphest_task, storyboard.users
  set maniphest_task.authorPHID=storyboard.users.phid
  where maniphest_task.authorPHID=storyboard.users.id;

update maniphest_task, storyboard.users
  set maniphest_task.ownerPHID=storyboard.users.phid
  where maniphest_task.ownerPHID=storyboard.users.id;

-- Releationships are edges in a DAG, so set up relationships between
-- tasks with their owners and authors in both directions
insert into edge
  select authorPHID, 22, phid, 0, 0, NULL from maniphest_task;
insert into edge
  select phid, 21, authorPHID, 0, 0, NULL from maniphest_task;
replace into edge
  select ownerPHID, 22, phid, 0, 0, NULL from maniphest_task where ownerPHID is not null;
replace into edge
  select phid, 21, ownerPHID, 0, 0, NULL from maniphest_task where ownerPHID is not null;

-- Comments have two parts - the first is an entry in the transaction table
-- indicating that a comment happened and associating the comment with the task
insert into maniphest_transaction
  select
    c.id, -- id
    c.transPHID, --  phid
    u.phid, -- authorPHID
    s.phid, -- objectPHID
    'public', -- viewPolicy
    u.phid, -- editPolicy
    c.phid, -- commentPHID
    1, -- commentVersion
    'core:comment', -- transactionType
    'null', -- oldValue
    'null', -- newValue
    '{"source":"web"}', -- contentSource
    '[]', -- metadata
    unix_timestamp(c.created_at), -- dateCreated
    if(c.updated_at is null, unix_timestamp(c.created_at), unix_timestamp(c.updated_at)) -- dateUpdated
  from storyboard.comments c, storyboard.events e, storyboard.stories s, storyboard.users u
  where c.id = e.comment_id and s.id = e.story_id
     and e.event_type='user_comment' and s.creator_id = u.id;

-- The second part is the comment payload itself
insert into maniphest_transaction_comment
  select
    c.id, -- id
    c.phid, -- phid
    c.transPHID, -- transactionPHID
    u.phid, -- author
    'public', -- viewPolicy
    u.phid, -- editPolicy
    1, --
    if(c.content is NULL, '', c.content),
    '{"source":"web"}',
    if(c.is_active, false, true),
    unix_timestamp(c.created_at),
    if(c.updated_at is null, unix_timestamp(c.created_at), unix_timestamp(c.updated_at))
  from storyboard.comments c, storyboard.events e, storyboard.stories s, storyboard.users u
  where c.id = e.comment_id and s.id = e.story_id
     and e.event_type='user_comment' and s.creator_id = u.id;


-- We go back over to storyboard repo to create some calculated tables to
-- help us do project mapping. We needed to run in the tasks first so that
-- we can easily tell which tasks we need projects for.
use storyboard

drop table if exists task_project;
drop table if exists task_project_list;
drop table if exists task_project_grouping;

-- This is a table mapping tasks to every project it's associated with in a
-- clean and easy fashion for later
create table task_project
  select t.phid as task_phid, p.phid as project_phid, t.project_id as project_id
    from tasks t, phabricator_maniphest.maniphest_task m, projects p
    where m.phid=t.phid and t.project_id is not null and t.project_id = p.id;
-- We also add project groups to this table
insert into task_project
  select t.task_phid, g.phid, t.project_id
    from task_project t, project_groups g, project_group_mapping m
    where t.project_id = m.project_id and g.id = m.project_group_id;

-- based on that table, we make a new table so that we can modify and create
-- the comma-separated json list
create table task_project_list
  select task_phid, project_phid from task_project;
update task_project_list set project_phid = concat('"', project_phid, '"');
-- use group_concat to get a row for each task and then a comma-sep list of
-- projects. Since we wrapped them all in " above, this will be comma-sep and
-- quoted
create table task_project_grouping
  select task_phid, group_concat(project_phid) as phids
    from task_project_list
    group by task_phid;
-- Finally, wrap the results in [ and ]
update task_project_grouping set phids = concat('[', phids, ']');

-- We need to map tasks to dependent tasks. Lucky for us, Storyboard only
-- groks one level of this. Make a table for easy of importing later
drop table if exists task_subtask;
create table task_subtask
  select tasks.phid, tasks.storyPHID
  from tasks, phabricator_maniphest.maniphest_task
   where tasks.phid = phabricator_maniphest.maniphest_task.phid;

-- Grab a PHID to use as an author for the projects.
-- TODO: Make a system/bot account that we can use as the "owner" of these
-- projects. But I'll do for now.
select phid into @author_phid from users where email='craige@mcwhirter.com.au';

use phabricator_project

delete from project;
insert into project
  select
    (id + 1000) as id,
    name as name,
    phid as phid,
    @author_phid as authorPHID,
    created_at as dateCreated,
    updated_at as dateModified,
    0 as status,
    'users' as viewPolicy,
    'users' as editPolicy,
    'users' as joinPolicy,
    0 as isMembershipLocked,
    NULL as profileImagePHID,
    'fa-briefcase' as icon,
    'blue' as color,
    '12345678901234567890' as mailKey,
    concat(replace(lower(name), '/', '_'), '/') as primarySlug,
    NULL as parentProjectPHID,
    0 as hasWorkboard,
    0 as hasMilestones,
    0 as hasSubprojects,
    NULL as milestoneNumber,
    NULL as projectPath,
    NULL as projectDepth,
    storyboard.make_cert(4) as projectPathKey,
    NULL as properties
  from storyboard.projects;

  -- $hash = sha1(PHID, $raw_output = true);

delete from project_slug;
insert into project_slug
  select
    id,
    phid,
    replace(lower(name), '/', '_'),
    dateCreated,
    dateModified
  from project;

-- insert into project_datasourcetoken (need to split name on - and do a row for each value) for typeahead search in boxes
insert into project_datasourcetoken (projectID, token)
  select
    id as projectID,
    replace(lower(name), '/', '_') as token
  from project;

-- More DAG magic - this will map a project to a task in the projects DB
insert into edge
  select
    project_phid as src,
    42 as type,
    task_phid as dst,
    0 as dateCreated,
    0 as seq,
    NULL as dataID
  from storyboard.task_project;

use phabricator_maniphest

-- We have projects now, so inject them into the name mapping table in the
-- bug system
insert into maniphest_nameindex
  select
    id as id,
    phid as indexedObjectPHID,
    name as indexedObjectName
  from phabricator_project.project;
-- projectPHID appears to have been removed
-- update maniphest_task t, storyboard.task_project_grouping g
--   set t.projectPHIDs = g.phids
--  where t.phid = g.task_phid;

-- Associate tasks with projects from the task side
insert into edge
  select
    task_phid as src,
    41 as type,
    project_phid as dst,
    0 as dateCreated,
    0 seq,
    NULL as dataID
  from storyboard.task_project;

-- Relationship
--  If the task phid matches a storyboard task.phid, then it's a
--      subtask, and we should take the storyPHID from that storyboard.task
--      and use it to create the parent/child edges
--        Create Parent Edge:
--          src = story.phid, type = 3, dst = task.phid
--        Create Child Backref:
--          src = task.phid, type = 4, dst = story.phid
insert into edge
  select
    storyPHID, 3, phid, 0, 0, NULL
  from storyboard.task_subtask;
insert into edge
  select
    phid, 4, storyPHID, 0, 0, NULL
  from storyboard.task_subtask;

-- Enable RemoteUser
--  We need to populate phabricator_auth.auth_providerconfig with the following:

use phabricator_auth

insert into auth_providerconfig
   select
     1 as id,
     storyboard.make_phid('AUTH') as phid,
     'PhabricatorAuthProviderRemoteUser' as providerClass,
     'RemoteUser' as providerType,
     'self' as providerDomain,
     1 as isEnabled,
     1 as shouldAllowLogin,
     1 as shouldAllowRegistration,
     1 as shouldAllowLink,
     1 as shouldAllowUnlink,
     1 as shouldTrustEmails,
     '[]' as properties,
     unix_timestamp(now()) as dateCreated,
     unix_timestamp(now()) as dateModified,
     0 as shouldAutoLogin;

-- Link external account
-- We need to populate phabricator_user.user_externalaccount with the following:

use phabricator_user

insert into user_externalaccount (
  phid, userPHID, accountType, accountDomain, accountID)
  select
    storyboard.make_phid('AUTH') as phid,
    phid as userPHID,
    'RemoteUser' as accountType,
    'self' as accountDomain,
    openid as accountID
  from storyboard.users;
