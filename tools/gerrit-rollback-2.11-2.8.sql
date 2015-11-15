## mysqldiff 0.43
## 
## Run on Sun Nov 15 15:24:06 2015
## Options: user=root, host=localhost, debug=0
##
## ---   db: review107 (host=localhost user=root)
## +++   db: review86 (host=localhost user=root)

## No need to drop the tables
-- DROP TABLE account_agreements;
-- DROP TABLE account_group_agreements;
-- DROP TABLE account_group_includes;
-- DROP TABLE account_group_includes_audit;
-- DROP TABLE approval_categories;
-- DROP TABLE approval_category_values;
-- DROP TABLE contributor_agreements;

ALTER TABLE account_diff_preferences DROP COLUMN hide_top_menu; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE account_diff_preferences DROP COLUMN render_entire_file; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE account_diff_preferences DROP COLUMN theme; # was varchar(20) COLLATE utf8_bin DEFAULT NULL
ALTER TABLE account_diff_preferences DROP COLUMN hide_empty_pane; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE account_diff_preferences DROP COLUMN hide_line_numbers; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'

ALTER TABLE account_group_by_id_aud DROP PRIMARY KEY; # was (group_id,include_uuid,added_on)
ALTER TABLE account_group_by_id_aud ADD PRIMARY KEY (added_on,group_id,include_uuid);

ALTER TABLE accounts DROP COLUMN size_bar_in_change_table; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE accounts DROP COLUMN review_category_strategy; # was varchar(20) COLLATE utf8_bin DEFAULT NULL
ALTER TABLE accounts DROP COLUMN legacycid_in_change_table; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'

ALTER TABLE patch_set_approvals ADD INDEX patch_set_approvals_closedByU (change_open,account_id);
ALTER TABLE patch_set_approvals ADD INDEX patch_set_approvals_openByUser (change_open,account_id);

ALTER TABLE patch_sets DROP INDEX patch_sets_byRevision; # was INDEX (revision)

-- 2.11 below

ALTER TABLE account_diff_preferences DROP COLUMN auto_hide_diff_table_header; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'

ALTER TABLE account_groups DROP COLUMN owner_group_id; # was int(11) NOT NULL DEFAULT '0'
ALTER TABLE account_groups DROP COLUMN email_only_authors; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE account_groups CHANGE COLUMN group_uuid group_uuid varchar(40) COLLATE utf8_bin DEFAULT NULL; # was varchar(40) COLLATE utf8_bin NOT NULL DEFAULT ''
ALTER TABLE account_groups DROP COLUMN external_name; # was varchar(255) COLLATE utf8_bin DEFAULT NULL
ALTER TABLE account_groups DROP INDEX account_groups_ownedByGroup; # was INDEX (owner_group_id)

ALTER TABLE accounts DROP COLUMN mute_common_path_prefixes; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE accounts DROP COLUMN display_person_name_in_review_category; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'
ALTER TABLE accounts DROP COLUMN display_patch_sets_in_reverse_order; # was char(1) COLLATE utf8_bin NOT NULL DEFAULT 'N'

ALTER TABLE changes DROP COLUMN original_subject; # was varchar(255) COLLATE utf8_bin DEFAULT NULL
ALTER TABLE changes DROP COLUMN nbr_patch_sets; # was int(11) NOT NULL DEFAULT '0'
ALTER TABLE changes ADD INDEX changes_submitted (status,dest_project_name,dest_branch_name,last_updated_on);
ALTER TABLE changes ADD INDEX changes_byBranchClosed (status,dest_project_name,dest_branch_name,sort_key);
ALTER TABLE changes ADD INDEX changes_allClosed (open,status,sort_key);
ALTER TABLE changes ADD INDEX changes_key (change_key);
ALTER TABLE changes ADD INDEX changes_byOwnerClosed (open,owner_account_id,last_updated_on);
ALTER TABLE changes ADD INDEX changes_byOwnerOpen (open,owner_account_id,created_on,change_id);
ALTER TABLE changes ADD INDEX changes_byProject (dest_project_name);
ALTER TABLE changes ADD INDEX changes_byProjectOpen (open,dest_project_name,sort_key);
ALTER TABLE changes ADD INDEX changes_allOpen (open,sort_key);

ALTER TABLE system_config CHANGE COLUMN admin_group_uuid admin_group_uuid varchar(40) COLLATE utf8_bin DEFAULT NULL; # was varchar(40) COLLATE utf8_bin NOT NULL DEFAULT ''
ALTER TABLE system_config CHANGE COLUMN batch_users_group_uuid batch_users_group_uuid varchar(40) COLLATE utf8_bin DEFAULT NULL; # was varchar(40) COLLATE utf8_bin NOT NULL DEFAULT ''
ALTER TABLE tracking_ids DROP COLUMN tracking_id; # was varchar(20) COLLATE utf8_bin NOT NULL DEFAULT ''
ALTER TABLE tracking_ids DROP INDEX tracking_ids_byTrkId; # was INDEX (tracking_id)

insert into account_groups values
  ('Anonymous Users', 'Any user, signed-in or not', 'SYSTEM', 'N', 'global:Anonymous-Users', 2, '2c6802522201d0091571720a39b3851e0cc805d5'),
  ('Registered Users', 'Any signed-in user', 'SYSTEM', 'N', 'global:Registered-Users', 3, '2c6802522201d0091571720a39b3851e0cc805d5'),
  ('Project Owners', 'Any owner of the project', 'SYSTEM', 'N', 'global:Project-Owners', 5, '2c6802522201d0091571720a39b3851e0cc805d5'),
  ('Change Owner', 'The owner of a change', 'SYSTEM', 'N', 'global:Change-Owner', 325, '2c6802522201d0091571720a39b3851e0cc805d5');

-- Generate sort keys for new changes from 2.11
update changes
  set sort_key=lower(concat(
    lpad(hex((unix_timestamp(last_updated_on)-1222819200)/60), 8, '00000000'),
    lpad(hex(change_id), 8, '00000000')))
  where sort_key='';

update schema_version set version_nbr = '86';
## Not accounted for
## - Create the All-Users git repo
