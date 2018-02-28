-- Convert schema '/home/abeverley/git/GADS/share/migrations/_source/deploy/36/001-auto.yml' to '/home/abeverley/git/GADS/share/migrations/_source/deploy/35/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE view DROP FOREIGN KEY view_fk_group_id,
                 DROP INDEX view_idx_group_id,
                 DROP COLUMN group_id;

;

COMMIT;

