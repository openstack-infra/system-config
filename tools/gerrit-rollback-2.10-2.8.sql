## mysqldiff 0.43
##
## Run on Mon May 11 14:55:31 2015
## Options: host=localhost, debug=0
##
## ---   db: new (host=localhost)
## +++   db: old (host=localhost)

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
ALTER TABLE patch_set_approvals ADD INDEX patch_set_approvals_openByUser (change_open,account_id);
ALTER TABLE patch_set_approvals ADD INDEX patch_set_approvals_closedByU (change_open,account_id);
ALTER TABLE patch_sets DROP INDEX patch_sets_byRevision; # was INDEX (revision)

insert into account_groups values
  ('Anonymous Users', 'Any user, signed-in or not', 'SYSTEM', 'N', 'global:Anonymous-Users', 2, '2c6802522201d0091571720a39b3851e0cc805d5'),
  ('Registered Users', 'Any signed-in user', 'SYSTEM', 'N', 'global:Registered-Users', 3, '2c6802522201d0091571720a39b3851e0cc805d5'),
  ('Project Owners', 'Any owner of the project', 'SYSTEM', 'N', 'global:Project-Owners', 5, '2c6802522201d0091571720a39b3851e0cc805d5'),
  ('Change Owner', 'The owner of a change', 'SYSTEM', 'N', 'global:Change-Owner', 325, '2c6802522201d0091571720a39b3851e0cc805d5');

## Not accounted for
## - Create the All-Users git repo
