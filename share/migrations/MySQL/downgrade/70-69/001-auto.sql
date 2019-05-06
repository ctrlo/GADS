-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/70/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/69/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sort DROP FOREIGN KEY sort_fk_layout_id,
                 DROP INDEX sort_idx_layout_id,
                 DROP COLUMN `order`;

;
ALTER TABLE view_group DROP FOREIGN KEY view_group_fk_layout_id,
                       DROP FOREIGN KEY view_group_fk_parent_id,
                       DROP FOREIGN KEY view_group_fk_view_id;

;
DROP TABLE view_group;

;

COMMIT;

